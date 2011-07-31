require 'logger'

module SkypeLogger
  class SimpleFormatter < Logger::Formatter
    # This method is invoked when a log event occurs
    def call(severity, timestamp, progname, msg)
      "#{timestamp.strftime("%Y/%m/%d %H:%M:%S")} #{String === msg ? msg : msg.inspect}\n"
    end
  end
end
