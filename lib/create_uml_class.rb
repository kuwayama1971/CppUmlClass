#!/usr/bin/env ruby
$LOAD_PATH << File.dirname(File.expand_path(__FILE__))
require "tempfile"
require "facter"
require "check_word"

CStruct = Struct.new(:type,
                     :name,
                     :block_count,
                     :var_list,
                     :method_list,
                     :inherit_list,
                     :composition_list)

def get_gcc_path
  kernel = Facter.value(:kernel)
  if kernel == "windows"
    ENV["PATH"].split(";").each do |path|
      gcc_path = "#{path}\\gcc"
      if File.exists? gcc_path
        return "rubyw " + gcc_path + " -fpreprocessed -dD -E "
      end
    end
    return ""
  else
    return "gcc -fpreprocessed -dD -E "
  end
end

def get_unifdef_path
  kernel = Facter.value(:kernel)
  if kernel == "windows"
    ENV["PATH"].split(";").each do |path|
      gcc_path = "#{path}\\unifdef"
      if File.exists? gcc_path
        return "rubyw " + gcc_path + " -k  "
      end
    end
    return ""
  else
    return "unifdef -k  "
  end
end

def get_clang_format_path
  kernel = Facter.value(:kernel)
  if kernel == "windows"
    ENV["PATH"].split(";").each do |path|
      clang_format_path = "#{path}\\clang-format"
      if File.exists? clang_format_path
        return "rubyw " + clang_format_path + " --style=file:'.clang-format' "
      end
    end
    return ""
  else
  end
  return "clang-format --style=file:'.clang-format' "
end

# ソースコードの整形
# フォーマット変更(clang-format)
# コメント削除(gcc)
# ifdefの処理(unifdef)
def update_source(file)
  # コメント削除
  gcc_out_file = Tempfile.open(["gcc", File.extname(file)])
  #puts gcc_out_file.path
  #puts "|#{get_gcc_path} #{file} > #{gcc_out_file.path}"
  open("|#{get_gcc_path} #{file} > #{gcc_out_file.path}") do |f|
    if f.read =~ /error/
      puts "gcc error #{f}"
      return ""
    end
  end
  #puts File.binread gcc_out_file.path
  # clang-format
  format_out_file = Tempfile.open(["clang_format", File.extname(file)])
  #puts format_out_file.path
  #puts "|#{get_clang_format_path} #{gcc_out_file.path} > #{format_out_file.path}"
  open("|#{get_clang_format_path} #{gcc_out_file.path} > #{format_out_file.path}") do |f|
    if f.read =~ /No such/
      puts "gcc error #{f}"
      return ""
    end
  end
  buf = File.binread format_out_file.path
  return buf
  # ifdef処理
  unifdef_out_file = Tempfile.open(["gcc", File.extname(file)])
  #puts unifdef_out_file.path
  #puts "|#{get_unifdef_path} #{format_out_file.path} > #{unifdef_out_file.path}"
  open("|#{get_unifdef_path} #{gcc_out_file.path} > #{unifdef_out_file.path}") do |f|
    if f.read =~ /No such/
      puts "gcc error #{f}"
      return ""
    end
  end
  buf = File.binread unifdef_out_file.path
  puts buf
  return buf
end

def print_uml(out, out_list)
  out_list.each do |o_list|
    if o_list.type == :class_start
      # nop
    elsif o_list.type == :module_start
      out.push "namespace #{o_list.name} {"
    elsif o_list.type == :class_end
      pp o_list if o_list.name == ""
      out.push "class #{o_list.name} {"
      # インスタンス変数の出力
      o_list.var_list.uniq.each do |iv|
        out.push iv
      end
      # メソッドの出力
      o_list.method_list.each do |ml|
        out.push ml
      end
      out.push "}"
      # 継承リストの出力
      o_list.inherit_list.each do |ih|
        out.push "#{o_list.name} -[#blue]-|> #{ih}"
      end
      # compo
      o_list.composition_list.uniq.each do |co|
        out.push "#{o_list.name} *-[#green]- #{co}"
      end
    elsif o_list.type == :module_end
      # インスタンス変数がある場合はモジュール名と同じクラスを定義
      if o_list.var_list.size != 0 or
         o_list.method_list.size != 0 or
         o_list.inherit_list.size != 0 or
         o_list.composition_list.size != 0
        pp o_list if o_list.name == ""
        out.push "class #{o_list.name} {"
        # インスタンス変数の出力
        o_list.var_list.uniq.each do |iv|
          out.push iv
        end
        # メソッドの出力
        o_list.method_list.each do |ml|
          out.push ml
        end
        out.push "}"
        # 継承リストの出力
        o_list.inherit_list.each do |ih|
          out.push "#{o_list.name} -[#blue]-|> #{ih}"
        end
        # compo
        o_list.composition_list.uniq.each do |co|
          out.push "#{o_list.name} *-[#green]- #{co}"
        end
      end
      out.push "}"
    else
      # error
      puts "error!"
    end
  end
  return out
end

def composition_list_create(in_dir, out_list)
  # composition_list
  Dir.glob("#{in_dir}/**/*.{cpp,hpp}") do |file|
    if file =~ Regexp.new(@config["exclude_path"])
      puts "skip #{file}"
      next
    end
    puts file
    # ソースコードの整形
    buf = update_source(file)
    # ソースを解析
    cstruct_list = []
    block_count = 0
    buf.each_line do |line|
      next if line =~ /^[\r\n]*$/  # 空行は対象外
      next if line =~ /^#/ # #から始まる行は対象外
      puts line

      # ブロックの開始/終了
      if line.match(/\{/)
        block_count += 1
      end
      if line.match(/\}/)
        block_count -= 1
      end
      puts "block_count=#{block_count}"

      # classの開始
      #if line =~ /^\s*(class)\s/ and File.extname(file) == ".h"
      if line =~ /^\s*(class|struct)\s/ and File.extname(file) == ".h"
        next if line =~ /;$/
        work = line.gsub(/(class|struct)/, "")
        class_name = work.split(" : ")[0].to_s.chomp.match(/ [A-Za-z0-9_:]+/).to_s.split(" ")[0]
        base_name = work.split(" : ")[1].to_s.split(" ")[1].to_s.gsub(/<.*>/, "")
        puts "start class #{class_name}"
        cstruct_list.push CStruct.new(:class_end, class_name, block_count, [], [], [], [])
      end

      # 関数の開始
      #if line =~ /^\S+::\S+/
      if line.gsub(/<.*>/, "") =~ /^\S.*(\S+)::(\S+).*\(.*{$/ and
         (File.extname(file) == ".cpp" or File.extname(file) == ".hpp")
        puts "method start"
        #class_name = line.match(/(\w+)(?=<\w*,?\s*\w*>?::\w+\(\))/).to_s
        #class_name = line.match(/(\w+)(?=::\S+\(\))/).to_s if class_name == ""
        #class_name = line.match(/(\w+(?:::\w+)*)(?=::\w+\(.*\))/).to_s if class_name == ""
        #class_name = class_name.split("::")[1] if class_name =~ /::/
        line.gsub(/<.*>/, "").match(/(\w+)(?=\S+\()/) do |m|
          puts "class_name=#{m}"
          cstruct_list.push CStruct.new(:method_start, m.to_s, block_count, [], [], [], [])
          break
        end

        #puts "class_name=[#{class_name}]"
        #if class_name != ""
        #  cstruct_list.push CStruct.new(:method_start, class_name, block_count, [], [], [], [])
        #  next
        #end
      end

      if cstruct_list.size != 0
        class_block_count = cstruct_list[-1].block_count
        if block_count == (class_block_count - 1) # block_countが一致
          # 関数の終了
          puts "method end #{cstruct_list[-1].name}"
          cstruct_list.slice!(-1) # 最後の要素を削除
        else
          puts "#{File.basename(file)}:#{block_count}:line3=#{line}"
          my_class_name = cstruct_list[-1].name
          my_cstruct = out_list.select { |m| m.name == my_class_name }[1]
          #pp my_cstruct
          if my_cstruct
            # 使用しているクラスの検索
            out_list.each do |clist|
              next if clist.name == my_cstruct.name
              use_class_name = clist.name
              puts "my_class_name=#{my_class_name} : use_class_name=#{use_class_name}"
              if check_word(line, use_class_name)
                #if line.include?(use_class_name)
                my_cstruct.composition_list.push use_class_name
              end
            end
          end
        end
      end
    end
  end
  #pp out_list
  return out_list
end

def create_uml_class(in_dir, out_file)
  out = []
  out.push "@startuml"

  puts "in_dir = #{in_dir}"
  main_composition_list = []
  main_method_list = []
  global_var = []

  out_list = []
  #Dir.glob("#{in_dir}/**/*.{cpp,hpp,h}") do |file|
  Dir.glob("#{in_dir}/**/*.{h}") do |file|
    if file =~ Regexp.new(@config["exclude_path"])
      puts "skip #{file}"
      next
    end
    puts file
    # ソースコードの整形
    buf = update_source(file)

    cstruct_list = []
    block_count = 0
    method_type = :public
    class_name = ""
    # ソースを解析
    buf.each_line do |line|
      next if line =~ /^[\r\n]*$/  # 空行は対象外
      next if line =~ /^#/ # #から始まる行は対象外
      puts line

      # ブロックの開始/終了
      if line.match(/\{/)
        block_count += line.each_char.select { |c| c == "{" }.size
        start_block = true
      else
        start_block = false
      end
      # ブロックの終了
      if line.match(/\}/)
        block_count -= line.each_char.select { |c| c == "}" }.size
      end
      puts "block_count=#{block_count}"

      # classの開始
      #if line =~ /^\s*(class)\s/
      if line =~ /^\s*(class|struct)\s/
        next if line =~ /;$/
        work = line.gsub(/(class|struct)/, "")
        class_name = work.split(" : ")[0].to_s.chomp.match(/ [A-Za-z0-9_:]+/).to_s.split(" ")[0]
        base_name = work.split(" : ")[1].to_s.gsub(/(public |private |protected )/, "").to_s.gsub(/<.*>/, "").split(" ")[0]
        puts "start class [#{class_name}]"
        if class_name == ""
          puts file
          exit
        end
        #if out_list.size != 0 and out_list[-1].type == :class_start # classが連続している
        #  class_name = out_list[-1].name + "." + class_name
        #  out_list[-1].name = class_name
        #  cstruct_list[-1].name = class_name
        #else
        out_list.push CStruct.new(:class_start, class_name, block_count, [], [], [], [])
        cstruct_list.push CStruct.new(:class_end, class_name, block_count, [], [], [], [])
        #end
        #pp line if class_name == ""
        if base_name.to_s != ""
          #base_name.gsub!(/::/, ".")
          puts "base_name=#{base_name}"
          cstruct_list[-1].inherit_list.push base_name
        end
      end

      if line =~ /^\s*private:$/
        method_type = :private
      elsif line =~ /^\s*protected:$/
        method_type = :protected
      elsif line =~ /^\s*public:$/
        method_type = :public
      end

      if cstruct_list.size != 0 and
         (block_count == cstruct_list[-1].block_count or
          (start_block == true and block_count - 1 == cstruct_list[-1].block_count))
        if line =~ /\(.*\)/
          #puts "#{block_count}:line2=#{line}"
          # 関数名を取り出す
          method = line.split(" : ")[0].gsub(/^\s+/, "")
          method = method.split(";")[0].split("{")[0]
          puts "method=#{method}"
          method_list = cstruct_list[-1].method_list
          case method_type
          when :public
            method_list.push "+ #{method}"
          when :private
            method_list.push "- #{method}"
          when :protected
            method_list.push "# #{method}"
          end
        end
      end

      # class変数
      # 括弧を含まない、かつtemplateを含まない文字列
      if cstruct_list.size != 0 and block_count == cstruct_list[-1].block_count
        if line =~ /^[^(){}]*$/ and
           line =~ /^((?!\/tmp\/).)*$/ and
           line =~ /^((?!namespace).)*$/ and
           line =~ /^((?!template).)*$/ and
           line =~ /^((?!public:).)*$/ and
           line =~ /^((?!private:).)*$/ and
           line =~ /^((?!protected:).)*$/
          puts "class member=#{line}"
          #val = line.split("=")[0].split(" ")[-1]
          val = line.split("=")[0]
          val = val.split(";")[0]
          instance_var = cstruct_list[-1].var_list
          case method_type
          when :public
            instance_var.push "+ #{val}"
          when :private
            instance_var.push "- #{val}"
          when :protected
            instance_var.push "# #{val}"
          end
        end
      end

      # クラスの終了
      if cstruct_list.size != 0
        class_block_count = cstruct_list[-1].block_count
        if block_count == (class_block_count - 1) # block_countが一致
          puts "class end #{cstruct_list[-1].name}"
          out_list.push cstruct_list[-1]
          cstruct_list.slice!(-1) # 最後の要素を削除
        end
      end
      #puts "#{block_count} #{line.chomp}"
    end
    if block_count != 0
      # エラー
      puts file
      return ""
    end
  end
  # compositon_listの作成
  out_list = composition_list_create(in_dir, out_list)
  # UMLの出力
  out = print_uml(out, out_list)

  if main_method_list.size != 0 or
     main_composition_list.size != 0 or
     main_method_list.size != 0
    out.push "class main {"
    main_method_list.each do |mml|
      out.push mml
    end
    # グローバル変数の出力
    global_var.uniq.each do |gv|
      out.push gv
    end
    out.push "}"
    main_composition_list.uniq.each do |mcl|
      out.push mcl
    end
  end

  out.push "@enduml"
  return out.join("\n")
end

def search_func(file)
  puts file
  # ソースコードの整形
  buf = update_source(file)
  # ソースを解析
  buf.each_line do |line|
    next if line =~ /^[\r\n]*$/  # 空行は対象外
    next if line =~ /^#/ # #から始まる行は対象外
    #puts line
    if line.gsub(/<.*>/, "") =~ /^\S.*(\S+)::(\S+).*\(.*{$/
      puts line.gsub!(/<.*>/, "")
      line.match(/(\w+)(?=\S+\()/) do |m|
        puts "class_name=#{m}"
      end
    end
  end
end

if $0 == __FILE__
  #search_func(ARGV[0])
  #exit
  #buf = update_source(ARGV[0])
  #puts buf
  @config = { "exclude_path" => "test" }

  if true
    puts create_uml_class(ARGV[0], ARGV[1])
  else
    out_list = []
    out_list.push CStruct.new(:method_start, "DefaultVehicleHal", 1, [], [], [], [])
    out_list.push CStruct.new(:method_start, "SubscriptionManager", 1, [], [], [], [])
    out_list.push CStruct.new(:method_start, "ContSubConfigs", 1, [], [], [], [])
    out_list.push CStruct.new(:method_start, "GetSetValuesClient", 1, [], [], [], [])
    puts composition_list_create(ARGV[0], out_list)
  end
end
