#!/usr/bin/env ruby

def condition_judge(cond_string, define_hash)
  ret = false
  #puts "cond_string=#{cond_string}"
  cond_string.gsub!(/defined/, "")
  if cond_string.gsub(/ /, "").to_s == "0"
    cond_string = "false"
  end
  #puts "cond_string=#{cond_string}"
  eval_buf = []
  arg_hash = {}
  eval_buf.push "def judge_ifdef"
  cond_string.scan(/[A-Z][A-Z_0-9]+/) do |m|
    #puts "scan word=#{m}"
    if define_hash.key? m
      arg_hash[m] = define_hash[m]
    else
      arg_hash[m] = false
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
  #puts eval_string
  ret = eval eval_string
  puts "call ifdef_judge #{ret}"
  return ret
end

def process_ifdef(file_buf, define_hash)
  out_buf = []
  proc_list = [true]
  line_count = 1
  ifdef_flag = false
  file_buf.each_line do |line|
    line = line.strip
    case line
    when /^#ifdef\s+(.*)/
      proc_list.push condition_judge($1, define_hash)
      ifdef_flag = proc_list[-1]
      puts "#ifdef #{ifdef_flag}:#{line_count}:line=[#{line}]:#{$1}"
    when /^#ifndef\s+(.+)/
      proc_list.push !condition_judge($1, define_hash)
      ifdef_flag = proc_list[-1]
      puts "#ifndef #{ifdef_flag}:#{line_count}:line=[#{line}]:#{$1}"
    when /^#if\s+(.+)/
      proc_list.push condition_judge($1, define_hash)
      ifdef_flag = proc_list[-1]
      puts "#if #{ifdef_flag}:#{line_count}:line=[#{line}]:#{$1}"
    when /^#elif\s+(.+)/
      if !ifdef_flag
        proc_list[-1] = condition_judge($1, define_hash)
        ifdef_flag = proc_list[-1]
      else
        proc_list[-1] = false
        ifdef_flag = true
      end
      puts "#elif #{ifdef_flag}:#{line_count}:line=[#{line}]:#{$1}"
    when /^#else/
      if !ifdef_flag
        proc_list[-1] = !proc_list[-1]
      else
        proc_list[-1] = false
        ifdef_flag = true
      end
      puts "#else #{ifdef_flag}:#{line_count}:line=[#{line}]"
    when /^#endif/
      proc_list.pop
      ifdef_flag = false
      puts "#endif #{ifdef_flag}:#{line_count}:line=[#{line}]"
    else
      print "proc_list="
      pp proc_list
      if 0 == proc_list.select { |p| p == false }.size
        puts "#{ifdef_flag}:#{line_count}: #{line}"
        out_buf.push line
      else
        puts "#{ifdef_flag}:#{line_count}: #{line}"
      end
    end
    line_count += 1
  end
  return out_buf
end

if $0 == __FILE__
  file = "/home/kuwayama/tool/cpp_test/test1/test3.cpp"
  buf = File.read(file)
  define_hash = {
    "TEST" => true,
    "TEST2" => true,
    "TEST3" => true,
    "DEBUG" => true,
  }
  out = process_ifdef(buf, define_hash)
  puts "-----------------------------------------------------------------------------------------"
  puts out
  puts "-----------------------------------------------------------------------------------------"
end
