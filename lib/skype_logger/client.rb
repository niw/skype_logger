require 'osx/cocoa'

module SkypeLogger
  class Client < OSX::NSObject
    attr_accessor :logger

    def clientApplicationName
      'SkypeLogger'
    end

    # FIXME make a standarized parser
    def skypeNotificationReceived(a)
      return unless logger
      logger.debug a.to_s
      case a.to_s
      when /CHATMESSAGE ([0-9]+) STATUS (SENT|RECEIVED)/
        on_message_sent_or_recieve($1)
      when /CHATMESSAGE ([0-9]+) ([A-Z_]+) (.*)$/
        on_message($1, $2, $3)
      end
    end

    def skypeBecameAvailable(a)
    end

    addRubyMethod_withType 'skypeAttachResponse:', 'v@:i'
    def skypeAttachResponse(status)
      return if status != 1
      command("PROTOCOL 8")
    end

    private

    def command(cmd)
      OSX::SkypeAPI.sendSkypeCommand(cmd).to_s
    end

    def format_message(message)
      [message[:timestamp] ? message[:timestamp].strftime("%Y/%m/%d %H:%M:%S") : "",
      message[:chattopic] ? message[:chattopic].gsub(/ /, '_') : "",
      message[:chatname],
      message[:id],
      message[:from],
      message[:body]].join(" ")
    end

    module SynchronousSendSkypeCommand
      def on_message_sent_or_recieve(id)
        message = get_message(id)
        logger.info format_message(message)
      end

      def on_message(id, key, value)
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
    end
    #include SynchronousSendSkypeCommand

    # Skype Framework 2.8.x seems have a bug which sendSkypeCommand
    # response asynchronously.
    module AsynchronousSendSkypeCommand
      def on_message_sent_or_recieve(id)
        request_message(id)
      end

      def on_message(id, key, value)
        message = (messages[id] ||= {:id => id})
        case key
        when "CHATNAME"
          message[:chatname] = value
          # FIXME
          message[:chattopic] = "(null)"
        when "BODY"
          message[:body] = value
        when "TIMESTAMP"
          message[:timestamp] = Time.at(value.to_i)
        when "FROM_HANDLE"
          message[:from] = value
        end
        write_log_if_possible
      end

      private

      def messages
        @messages ||= {}
      end

      def write_log_if_possible
        @messages.each do |id, message|
          if message[:chatname] && message[:body] && message[:timestamp] && message[:from]
            logger.info format_message(message)
            @messages.delete(id)
          end
        end
        logger.debug "current queue message: #{@messages.keys}"
      end

      def request_message(id)
        command("GET CHATMESSAGE #{id} CHATNAME")
        command("GET CHATMESSAGE #{id} BODY")
        command("GET CHATMESSAGE #{id} TIMESTAMP")
        command("GET CHATMESSAGE #{id} FROM_HANDLE")
      end
    end
    include AsynchronousSendSkypeCommand
  end
end
