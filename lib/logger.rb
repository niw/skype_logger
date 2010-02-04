#!/usr/bin/arch -i386 /usr/bin/ruby -Ku
# vim:set ft=ruby

require 'osx/cocoa'
require 'logger'
require 'optparse'

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

include OSX

OSX.require_framework '/Applications/Skype.app/Contents/Frameworks/Skype.framework'

class SkypeLogger < NSObject
  class SimpleFormatter < Logger::Formatter
    # This method is invoked when a log event occurs
    def call(severity, timestamp, progname, msg)
      "#{timestamp.strftime("%Y/%m/%d %H:%M:%S")} #{String === msg ? msg : msg.inspect}\n"
    end
  end

  def clientApplicationName
    'SkypeLogger'
  end

  def skypeNotificationReceived(a)
    logger.debug a.to_s
    case a.to_s
    when /MESSAGE ([0-9]+) STATUS (SENT|RECEIVED)/, /MESSAGE ([0-9]+) BODY (.*)$/
      m = get_message($1)
      logger.info "#{m[:timestamp].strftime("%Y/%m/%d %H:%M:%S")} #{m[:chattopic].gsub(/ /, '_')} #{m[:chatname]} #{m[:id]} #{m[:from]} #{m[:body]}"
    end
  end

  def skypeBecameAvailable(a)
  end

  def skypeAttachResponse
    command("PROTOCOL 7")
  end

  private
  def get_message(id)
    message = {:id => id}
    if /MESSAGE [0-9]+ CHATNAME (.*)$/ === command("GET CHATMESSAGE #{id} CHATNAME")
      message[:chatname] = $1
      if /CHAT .+ TOPIC (.*)$/ === command("GET CHAT #{$1} TOPIC")
        message[:chattopic] = $1 == "(null)" ? "" : $1
      end
    end
    if /MESSAGE [0-9]+ BODY (.*)$/ === command("GET CHATMESSAGE #{id} BODY")
      message[:body] = $1
    end
    if /MESSAGE [0-9]+ TIMESTAMP (.*)$/ === command("GET CHATMESSAGE #{id} TIMESTAMP")
      message[:timestamp] = Time.at($1.to_i)
    end
    if /MESSAGE [0-9]+ FROM_HANDLE (.*)$/ === command("GET CHATMESSAGE #{id} FROM_HANDLE")
      message[:from] = $1
    end
    message
  end

  def command(cmd)
    OSX::SkypeAPI.sendSkypeCommand(cmd).to_s
  end

  def logger
    @logger ||= begin
      logger = Logger.new(OPTIONS[:logfile] ? File.expand_path(OPTIONS[:logfile]) : STDOUT)
      logger.formatter = SimpleFormatter.new
      logger.level = OPTIONS[:verbose] ? Logger::DEBUG : Logger::INFO
      logger
    end
  end
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

OSX::SkypeAPI.setSkypeDelegate SkypeLogger.new
OSX::SkypeAPI.connect

app = NSApplication.sharedApplication
app.run
disconnect_and_exit
