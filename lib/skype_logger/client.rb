require 'osx/cocoa'

module SkypeLogger
  class Client < OSX::NSObject
    attr_accessor :logger

    def clientApplicationName
      'SkypeLogger'
    end

    def skypeNotificationReceived(a)
      return unless logger
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
  end
end
