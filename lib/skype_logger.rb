#!/usr/bin/arch -i386 /usr/bin/ruby -Ku

$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require 'optparse'
require 'osx/cocoa'
require 'skype_logger/app_delegate'

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

#File.open('/dev/null') do |f|
#  STDIN.reopen(f)
#  STDOUT.reopen(f) if OPTIONS[:logfile]
#  STDERR.reopen(f)
#end

app = OSX::NSApplication.sharedApplication
app.setDelegate(SkypeLogger::AppDelegate.alloc.initWithOptions(OPTIONS))
[:SIGINT, :SIGTERM, :SIGHUP].each do |signal|
  trap(signal) do
    app.terminate(nil)
  end
end
app.run
