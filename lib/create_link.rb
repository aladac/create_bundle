require 'create_link/version'
require 'logger'
require 'plist'
require 'pathname'
require 'pry'

module CreateLink
  class Base
    attr_accessor :logger, :app_path, :target_path

    def initialize(path, target_path = './')
      @logger = Logger.new(STDOUT)
      @app_path = Pathname(path)
      @target_path = Pathname(target_path) + @app_path.basename.to_s
    end

    def icon_path
      app_path + 'Contents' + 'Resources' + icon_file
    end

    def plist_path
      app_path + 'Contents' + 'Info.plist'
    end

    def plist
      Plist.parse_xml(plist_path)
    end

    def icon_file
      plist['CFBundleIconFile'] !~ /icns$/ ? plist['CFBundleIconFile'] + '.icns' : plist['CFBundleIconFile']
    end

    def contents_dir
      target_path + 'Contents'
    end

    def resources_dir
      contents_dir + 'Resources'
    end

    def macos_dir
      contents_dir + 'MacOS'
    end

    def create_dirs
      Dir.mkdir target_path
      Dir.mkdir contents_dir
      Dir.mkdir resources_dir
      Dir.mkdir macos_dir
    end

    def create_plist
      target_plist_hash = {
        'CFBundleExecutable' => 'applet',
        'CFBundleIconFile' => 'applet'
      }
      f = File.new(contents_dir + 'Info.plist', 'w')
      f.puts target_plist_hash.to_plist
      f.close
    end

    def copy_icon
      File.link(icon_path, resources_dir + 'applet.icns')
    end

    def create_exec
      f = File.new(macos_dir + 'applet', 'w')
      f.puts "#!/bin/sh\nopen -a \"#{ARGV[0]}\""
      f.close
      FileUtils.chmod 0o755, macos_dir + 'applet'
    end

    def create
      create_dirs
      copy_icon
      create_exec
      create_plist
    rescue Errno::EEXIST => e
      puts e.message
    end
  end
end
