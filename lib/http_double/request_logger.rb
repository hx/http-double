require 'rack/utils'
require 'ostruct'
require 'active_support/hash_with_indifferent_access'

class HttpDouble::RequestLogger

  # noinspection RubyConstantNamingConvention
  IHash = ActiveSupport::HashWithIndifferentAccess

  def initialize(app, log)
    @app = app
    @log = log
  end

  def call(env)
    response = @app.call(env)
    res = OpenStruct.new(
        code:    response[0],
        headers: IHash.new(response[1]),
        body:    response[2].join
    )
    @log << OpenStruct.new(request: Request.new(env), response: res)
    response
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
      @form_fields ||= IHash.new(Rack::Utils.parse_query(body).map { |key, value| [key.to_sym, value.is_a?(Array) ? value : [value]] }.to_h)
    end

    def json_input
      @json_input ||= JSON.parse body, quirks_mode: true
    end

  end

end
