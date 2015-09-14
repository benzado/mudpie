require 'term/ansicolor'

module MudPie
  class Logger
    include Term::ANSIColor

    WARN  =  1
    INFO  =  0
    DEBUG = -1

    def initialize
      @output = $stderr
      @output_level = INFO
    end

    def quiet=(quiet)
      if quiet
        @output_level = WARN
      else
        @output_level = [INFO, @output_level].min
      end
    end

    def debug=(debug)
      if debug
        @output_level = DEBUG
      else
        @output_level = [INFO, @output_level].max
      end
    end

    def log(level, message)
      if level >= @output_level
        if @output.isatty
          case level
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
