# frozen_string_literal: true

require 'create_bundle/version'
require 'logger'
require 'plist'
require 'pathname'
require 'pry'
require 'optparse'

module CreateBundle
  class Base
    attr_accessor :logger, :app_path, :target_path, :verbose

    def initialize(options)
      @logger = Logger.new(STDOUT)
      @app_path = Pathname(options[:source])
      @custom_icon = options[:icon]
      @custom_script = options[:script]
      options[:target] = options[:source] if options[:bare]
      @target_path = options[:target] ? Pathname(options[:target]) : Pathname(@app_path.basename.to_s)
    end

    def custom_icon_path
      return false unless @custom_icon
      if Pathname(@custom_icon).exist?
        Pathname(@custom_icon)
      else
        puts "Icon file doesn't exist"
        exit_and_cleanup
      end
    end

    def icon_path
      custom_icon_path || app_path + 'Contents' + 'Resources' + icon_file
    rescue ArgumentError
      logger.warn 'Problem reading source plist file, probably binary format, falling back to default icon name'
      icon = app_path + 'Contents' + 'Resources' + 'AppIcon.icns'
      icon || exit_and_cleanup
    end

    def plist_path
      path = app_path + 'Contents' + 'Info.plist'
      path.exist? ? path : (logger.info("Source doesn't look like an app bundle") && exit)
    end

    def plist
      Plist.parse_xml(plist_path)
    end

    def icon_file
      !/icns$/.match?(plist['CFBundleIconFile']) ? plist['CFBundleIconFile'] + '.icns' : plist['CFBundleIconFile']
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
      [target_path, contents_dir, resources_dir, macos_dir].each { |dir| create_dir(dir) }
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

    def write_script
      f = File.new(macos_dir + 'applet', 'w')
      f.puts "#!/bin/sh\nopen -a \"#{ARGV[0]}\""
      f.close
      logger.debug "Created exec: #{(macos_dir + 'applet')}" if verbose
    end

    def copy_script
      return false unless @custom_script
      if Pathname(@custom_script).exist?
        File.link(Pathname(@custom_script), macos_dir + 'applet')
        true
      else
        puts "Script file doesn't exist"
        exit_and_cleanup
      end
    end

    def create_exec
      copy_script || write_script
      FileUtils.chmod 0o755, macos_dir + 'applet'
    end

    def create
      create_dirs
      copy_icon
      create_exec
      create_plist
    rescue Errno::EEXIST => e
      logger.error e.message
    end

    def exit_and_cleanup
      FileUtils.rm_rf(target_path)
      exit
    end
  end
end
