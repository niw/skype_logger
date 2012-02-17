require 'osx/cocoa'
require 'skype_logger/client'
require 'skype_logger/formatter'

module SkypeLogger
  class AppDelegate < OSX::NSObject
    def initWithOptions(options)
      init
      @options = options
      self
    end

    def applicationDidFinishLaunching(notification)
      OSX::SkypeAPI.setSkypeDelegate client
      OSX::SkypeAPI.connect
    end

    def applicationWillTerminate(notification)
      OSX::SkypeAPI.disconnect
    end

    private

    def client
      @client ||= Client.alloc.init.tap do |client|
        client.logger = logger
      end
    end

    def logger
      @logger ||= Logger.new(@options[:logfile] ? File.expand_path(@options[:logfile]) : STDOUT).tap do |logger|
        logger.formatter = SimpleFormatter.new
        logger.level = @options[:verbose] ? Logger::DEBUG : Logger::INFO
      end
    end
  end
end
