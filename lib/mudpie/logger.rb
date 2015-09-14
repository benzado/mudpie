require 'term/ansicolor'

module MudPie
  class Logger
    include Term::ANSIColor

    WARN  =  1
    INFO  =  0
    DEBUG = -1

    attr_accessor :output
    attr_accessor :level

    def initialize
      @output = $stderr
      @level = INFO
    end

    def log(message_level, message)
      if message_level >= @level
        if @output.isatty
          case message_level
          when WARN then message = red(message)
          when DEBUG then message = faint(message)
          end
        end
        @output.puts(message)
      end
    end

    def warn(message)
      log(WARN, message)
    end

    def info(message)
      log(INFO, message)
    end

    def debug(message)
      log(DEBUG, message)
    end
  end

  def self.logger
    @logger ||= Logger.new
  end
end
