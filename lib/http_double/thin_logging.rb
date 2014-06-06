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
