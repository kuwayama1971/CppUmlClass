#!/usr/bin/env ruby

class IfdefProcess
  attr_reader :define_list

  def initialize()
    @define_list = []
  end

  def remove_suffixes(text)
    suffixes = %w[ULL LL UL D F U L]
    suffix_pattern = suffixes.uniq.sort_by(&:length).reverse.join("|")
    #puts suffix_pattern
    regex = /(\d+\.?\d*)(?:#{suffix_pattern})\b/i
    text.gsub(regex, '\1')
  end

  def check_ifdefined(cond_string, define_hash)
    pattern = /(!)?defined\(([^)]*)\)/
    define_hash_new = define_hash.dup
    matches = cond_string.scan(pattern)

    matches.each do |match|
      # !definedでKeyが未登録の場合は登録
      has_exclamation = !match[0].nil?
      key = match[1]
      if has_exclamation
        unless define_hash.key? key
          define_hash_new[key] = false
        end
      end
    end

    return define_hash_new
  end

  def condition_judge(cond_string, define_hash)
    ret = false
    #puts "cond_string=#{cond_string}"
    cond_string = remove_suffixes(cond_string)
    #puts "cond_string=#{cond_string}"
    define_hash_new = check_ifdefined(cond_string, define_hash)
    #pp define_hash_new
    cond_string.gsub!(/defined/, "")
    if cond_string.gsub(/ /, "").to_s == "0"
      # not define
      #puts "return ifdef_judge #{ret}"
      return false
    end
    eval_buf = []
    arg_hash = {}
    eval_buf.push "def judge_ifdef"
    cond_string.scan(/[_A-Za-z][_A-Za-z_0-9]+/) do |m|
      #puts "scan word=#{m}"
      @define_list.push m
      next if m == "false" or m == "true"
      if define_hash_new.key? m
        arg_hash[m] = define_hash_new[m]
      else
        # not define
        #puts "return ifdef_judge #{ret}"
        return false
      end
    end
    #puts "arg_hash=#{arg_hash}"
    arg_hash.each do |key, val|
      eval_buf.push "  #{key.downcase} = #{val}"
    end
    eval_buf.push "  if #{cond_string.downcase}"
    eval_buf.push "    return true"
    eval_buf.push "  else"
    eval_buf.push "    return false"
    eval_buf.push "  end"
    eval_buf.push "end"
    eval_buf.push "judge_ifdef()"
    eval_string = eval_buf.join("\n")
    #puts "eval_string=#{eval_string}"
    ret = eval eval_string
    #puts "return ifdef_judge #{ret}"
    return ret
  end

  def process_ifdef(file_buf, define_hash)
    out_buf = []
    proc_list = [true]
    line_count = 1
    ifdef_flag = [false]
    file_buf.each_line do |line|
      line = line.strip
      case line
      when /^#ifdef\s+(.*)/
        proc_list.push condition_judge($1, define_hash)
        ifdef_flag.push proc_list[-1]
        #puts "#ifdef #{ifdef_flag[-1]}:#{line_count}:line=[#{line}]:#{$1}"
      when /^#ifndef\s+(.+)/
        proc_list.push !(condition_judge($1, define_hash))
        ifdef_flag.push proc_list[-1]
        #puts "#ifndef #{ifdef_flag[-1]}:#{line_count}:line=[#{line}]:#{$1}"
      when /^#if\s+(.+)/
        proc_list.push condition_judge($1, define_hash)
        ifdef_flag.push proc_list[-1]
        #puts "#if #{ifdef_flag[-1]}:#{line_count}:line=[#{line}]:#{$1}"
      when /^#elif\s+(.+)/
        if !ifdef_flag[-1]
          proc_list[-1] = condition_judge($1, define_hash)
          ifdef_flag[-1] = proc_list[-1]
        else
          proc_list[-1] = false
          ifdef_flag[-1] = true
        end
        #puts "#elif #{ifdef_flag[-1]}:#{line_count}:line=[#{line}]:#{$1}"
      when /^#else/
        if !ifdef_flag[-1]
          proc_list[-1] = !proc_list[-1]
        else
          proc_list[-1] = false
          ifdef_flag[-1] = true
        end
        #puts "#else #{ifdef_flag[-1]}:#{line_count}:line=[#{line}]"
      when /^#endif/
        proc_list.pop
        ifdef_flag.pop
        #puts "#endif #{ifdef_flag[-1]}:#{line_count}:line=[#{line}]"
      else
        #print "proc_list="
        #pp proc_list
        if 0 == proc_list.select { |p| p == false }.size
          #puts "#{ifdef_flag[-1]}:#{line_count}: #{line}"
          out_buf.push line
        else
          #puts "#{ifdef_flag[-1]}:#{line_count}: #{line}"
        end
      end
      line_count += 1
    end
    @define_list.uniq!
    return out_buf
  end
end

if $0 == __FILE__
  #file = "/home/kuwayama/tool/cpp_test/test1/test3.cpp"
  file = ARGV[0]
  buf = File.read(file)
  # define_hash = {
  #   "TEST" => false,
  #   "TEST2" => false,
  #   "TEST3" => false,
  #   "DEBUG" => false,
  #   "AAA" => false,
  #   "BBB" => true,
  # }
  define_hash = {}
  pifdef = IfdefProcess.new
  out = pifdef.process_ifdef(buf, define_hash)
  puts "-----------------------------------------------------------------------------------------"
  puts out
  puts "-----------------------------------------------------------------------------------------"
  puts pifdef.define_list
end
