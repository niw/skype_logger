#!/usr/bin/arch -i386 /usr/bin/ruby -Ku

$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require 'osx/cocoa'
require 'optparse'
require 'skype_logger/client'
require 'skype_logger/formatter'

include SkypeLogger

OPTIONS = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [-v] [-l logfile]"

  opts.on "-v", "--verbose", "turn on verbose logging" do |value|
    OPTIONS[:verbose] = value
  end

  opts.on "-l", "--logfile=VAL", "path to log file" do |value|
    OPTIONS[:logfile] = value
  end
end
parser.parse! ARGV

OSX.require_framework '/Applications/Skype.app/Contents/Frameworks/Skype.framework'

def logger
  logger = Logger.new(OPTIONS[:logfile] ? File.expand_path(OPTIONS[:logfile]) : STDOUT)
  logger.formatter = SimpleFormatter.new
  logger.level = OPTIONS[:verbose] ? Logger::DEBUG : Logger::INFO
  logger
end

def disconnect_and_exit
  OSX::SkypeAPI.disconnect
  exit
end

trap('SIGINT')  { disconnect_and_exit }
trap('SIGTERM') { disconnect_and_exit }
trap('SIGHUP')  { disconnect_and_exit }

#File.open('/dev/null') do |f|
#  STDIN.reopen(f)
#  STDOUT.reopen(f) if OPTIONS[:logfile]
#  STDERR.reopen(f)
#end

client = Client.new
client.logger = logger

OSX::SkypeAPI.setSkypeDelegate client
OSX::SkypeAPI.connect

app = OSX::NSApplication.sharedApplication
app.run
disconnect_and_exit
