require 'osx/cocoa'
require 'logger'
OSX.ns_import 'SkypeLoggerLoader'

class NSLogLogger
  [:fatal, :error, :warn, :info, :debug].each do |log_method|
    define_method log_method do |message|
	  OSX.NSLog("%@", message)
	end
  end
end

def application_support_path
  File.join(OSX::NSSearchPathForDirectoriesInDomains(OSX::NSLibraryDirectory, OSX::NSUserDomainMask, 1).first.to_s, 'Application Support')
rescue
  File.expand_path('~/Library/Application Support')
end

def logger
  log_path = File.join(application_support_path, 'Skype', 'SkypeLogger.log')
  logger = Logger.new(log_path)
  logger.formatter = SimpleFormatter.new
  logger.level = Logger::INFO
  logger
  #NSLogLogger.new
end

def bundle
  OSX::NSBundle.bundleForClass(OSX::SkypeLoggerLoader)
end

def resource_path
  bundle.resourcePath.fileSystemRepresentation
end

begin
  $LOAD_PATH << resource_path

  require 'client'
  require 'formatter'

  include SkypeLogger

  client = Client.new
  client.logger = logger

  at_exit do
    OSX::SkypeAPI.disconnect
  end

  sleep(3);

  OSX::SkypeAPI.setSkypeDelegate client
  OSX::SkypeAPI.connect
rescue Object => e
  OSX.NSLog("Exception: %@", e.inspect + (e.backtrace || []).join("\n\t"))
end