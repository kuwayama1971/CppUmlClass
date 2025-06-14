# -*- coding: utf-8 -*-
require "server_app_base.rb"
require "kconv"
require "create_uml_class.rb"
require "ifdef_process"

class CppUmlClass < AppMainBase
  def start(argv)
    super
    begin
      @abort = false
      puts argv
      in_dir = argv[0]
      out_file = argv[1]

      # 履歴の保存
      add_history("history.json", in_dir)
      add_history("out_history.json", out_file)

      # Browserにメッセージ送信
      app_send("app_start:")

      out_svg = out_file.gsub(File.extname(out_file), "") + ".svg"

      # uml作成
      pifdef = IfdefProcess.new

      uml = create_uml_class(pifdef, in_dir, out_file)

      File.open(out_file, "w") do |f|
        f.puts uml
      end

      # PlantUMLの実行
      FileUtils.rm_f out_svg
      cmd = "#{@config["plantuml"]} #{out_file}"
      puts cmd
      system cmd
      if File.exist? out_svg
        yield File.read out_svg
      else
        yield "exec error"
        yield cmd
      end

      app_send("popup:0:終了しました。<br><hr>#{in_dir}<br>で使用されているifdefのリスト<br><hr> #{pifdef.define_list.sort.join("<br>")}")
    rescue
      puts $!
      puts $@
      yield $!.to_s.toutf8
      yield $@.to_s.toutf8
    end
  end

  def stop()
    super
  end
end
