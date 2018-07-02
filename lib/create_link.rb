require 'create_link/version'
require 'logger'
require 'plist'
require 'pathname'
require 'pry'
require 'optparse'

module CreateLink
  class Base
    attr_accessor :logger, :app_path, :target_path, :verbose

    def initialize(path, target_path = '.')
      @logger = Logger.new(STDOUT)
      @app_path = Pathname(path)
      @target_path = Pathname(target_path) + @app_path.basename.to_s if target_path == '.'
      (logger.info("Source doesn't look like an app bundle") && exit) unless plist_path.exist?
    end

    def icon_path
      app_path + 'Contents' + 'Resources' + icon_file
    rescue ArgumentError
      logger.warn 'Problem reading source plist file, probably binary format, falling back to default icon name'
      icon = app_path + 'Contents' + 'Resources' + 'AppIcon.icns'
      icon || exit
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
      create_dir target_path
      create_dir contents_dir
      create_dir resources_dir
      create_dir macos_dir
    end

    def create_dir(path)
      Dir.mkdir path
      logger.debug "Created dir: #{path}" if verbose
    end

    def create_plist
      target_plist_hash = {
        'CFBundleExecutable' => 'applet',
        'CFBundleIconFile' => 'applet'
      }
      f = File.new(contents_dir + 'Info.plist', 'w')
      f.puts target_plist_hash.to_plist
      f.close
      logger.debug "Created plist file: #{(contents_dir + 'Info.plist')}" if verbose
    end

    def copy_icon
      File.link(icon_path, resources_dir + 'applet.icns')
      logger.debug "Copied icon to: #{(resources_dir + 'applet.icns')}" if verbose
    end

    def create_exec
      f = File.new(macos_dir + 'applet', 'w')
      f.puts "#!/bin/sh\nopen -a \"#{ARGV[0]}\""
      f.close
      FileUtils.chmod 0o755, macos_dir + 'applet'
      logger.debug "Created exec: #{(macos_dir + 'applet')}" if verbose
    end

    def create
      create_dirs
      copy_icon
      create_exec
      create_plist
    rescue Errno::EEXIST => e
      logger.error e.message
    end
  end
end
