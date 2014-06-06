require 'thin'
require 'sinatra/base'
require 'forwardable'

module HttpDouble
  class << self
    extend Forwardable
    delegate %i[background foreground log] => :Base
  end
end

require 'http_double/base'
require 'http_double/version'
require 'http_double/thin_logging'
require 'http_double/request_logger'
