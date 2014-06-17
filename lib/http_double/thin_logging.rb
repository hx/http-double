# This patch prevents Thin's logger from wigging out when you feed it binary data.

module Thin::Logging
  class << self
    alias_method :trace_msg_raw, :trace_msg

    def trace_msg(msg)
      source = msg.split "\r\n"
      result = []
      result << source.shift while source.first =~ /\A[[:print:]]+\z/
      result << source.shift if source.first == ''
      if source.index { |line| line =~ /[^[:print:]]/ }
        result << '[Binary body, %s byte(s)]' % source.join("\r\n").length
      else
        result.push *source
      end
      trace_msg_raw result.join "\n"
    end
  end
end

# This patch tries to ensure Thin is using the correct logger in cases where multiple
# doubles are running. This method is not foolproof.

class Thin::Connection
  alias_method :receive_data_original, :receive_data

  def receive_data(data)
    logger = HttpDouble::Base.loggers[backend.port]
    Thin::Logging.trace_logger = logger if logger.respond_to? :level
    receive_data_original data
  end
end
