require 'logger'
class LogFactory
  class MultiIO
    def initialize(*targets)
       @targets = targets
    end

    def write(*args)
      @targets.each { |t| t.write(*args) }
    end

    def close
      @targets.each(&:close)
    end
  end

  def self.logger(filename)
    @logger ||= create_logger_with_fallback(filename)
  end

  private
    def self.create_logger_with_fallback(filename)
      log_file = File.open("log/#{filename}.log", 'a')
      logger = Logger.new MultiIO.new(STDOUT, log_file)
      def logger.format_message(severity, timestamp, progname, msg)
        "#{severity.upcase} #{Kernel.caller[2].split('/').last}) #{timestamp.localtime} - #{msg2str(msg)}\n"
      end
      def logger.msg2str(msg)
        case msg
        when String
          msg
        when Exception
          "#{ msg.message } (#{ msg.class }): #{ msg.backtrace.take(3).join("\n") }"
        else
          msg.inspect
        end
      end
      logger
    end
end
