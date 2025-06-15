#!/usr/bin/env ruby

require "json"
require "optparse"

def config_json_hash(json)
  config = {}
  json["setting_list"].each do |j|
    config[j["name"]] = j["value"]
  end
  return config
end

opt = Hash.new
opts = OptionParser.new
opts.banner = "Usage: create_cpp_uml_class.rb [options] cpp_source_directory out_file"

opts.on("-c config_file") { |v| opt[:config_file] = v } # config file path
opts.parse!(ARGV)
in_dir = ARGV[0]
out_file = ARGV[1]
if in_dir == nil or out_file == nil
  puts opts.help
  exit
end

dir = File.dirname(File.expand_path(__FILE__ + "/../"))
puts "dir=#{dir}"
home_dir = ENV["HOME"] + "/" + dir.split("/")[-1].gsub(/-[0-9\.-]+/, "")
puts "home_dir=#{home_dir}"

if opt[:config_file] == nil
  json = JSON.parse(File.read("#{home_dir}/config/setting.json"))
else
  json = JSON.parse(File.read(opt[:config_file]))
end
json_config = config_json_hash(json)

file = "#{dir}/lib/create_uml_class.rb"
load file
file = "#{dir}/lib/ifdef_process.rb"
load file

@config = json_config
pifdef = IfdefProcess.new
uml = create_uml_class(pifdef, in_dir, out_file)

File.open(out_file, "w") do |f|
  f.puts uml
end

# PlantUMLの実行
out_svg = out_file.gsub(File.extname(out_file), "") + ".svg"
FileUtils.rm_f out_svg
cmd = "#{@config["plantuml"]} #{out_file}"
puts cmd
system cmd
if File.exist? out_svg
  puts File.binread out_file
  puts "create #{out_svg}"
else
  puts "plantuml error"
  puts cmd
end
