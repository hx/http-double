require 'rack/utils'

class HttpDouble::RequestLogger

  def initialize(app, log)
    @app = app
    @log = log
  end

  def call(env)
    @app.call(env).tap do |response|
      next if response[1].has_key? 'suppress-logging'
      @log << RoundTrip.new(
          Request.new(env),
          Response.new(
              response[0],
              HashWithIndifferentAccess.new(response[1]),
              response[2].join
          )
      )
    end
  end

  class RoundTrip
    attr_reader :request, :response

    def initialize(request, response)
      @request  = request
      @response = response
    end
  end

  class Response
    attr_reader :code, :headers, :body

    def initialize(code, headers, body)
      @code    = code
      @headers = headers
      @body    = body
    end
  end

  class Request

    attr_reader :env

    def initialize(env)
      @env = env
    end

    def body
      @body ||= rack_input.rewind && rack_input.read
    end

    def verb
      env['REQUEST_METHOD'].downcase.to_sym
    end

    def path
      env['REQUEST_PATH']
    end

    def [](field, index = nil)
      result = parsed_input[field]
      result = result[index] if result and index
      result
    end

    def method_missing(sym, *args, &block)
      parsed_input.__send__ sym, *args, &block
    end

    def respond_to_missing?(sym)
      parsed_input.respond_to? sym
    end

    private

    def parsed_input
      @parsed_input ||= case env['CONTENT_TYPE']
        when 'application/x-www-form-urlencoded' then form_fields
        when 'application/json', 'application/x-json' then json_input
        else raise "The content type '#{env['CONTENT_TYPE']}' doesn't support indexed access"
      end
    end

    def rack_input
      @rack_input ||= env['rack.input']
    end

    def form_fields
      @form_fields ||= HashWithIndifferentAccess.new(
          Rack::Utils.parse_query(body).map do |key, value|
            [key.to_sym, value.is_a?(Array) ? value : [value]]
          end.to_h
      )
    end

    def json_input
      @json_input ||= JSON.parse body, quirks_mode: true
    end

  end

  class HashWithIndifferentAccess < Hash

    def initialize(other_hash = {})
      merge! other_hash
    end

    def merge!(other_hash)
      other_hash.each { |k, v| self[k] = v }
    end

    %i([] []= key? fetch delete).each do |method|
      define_method(method) { |key, *args, &block| super key.to_s, *args, &block }
    end

  end

end
