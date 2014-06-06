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

    attr_reader :env, :body

    def initialize(env)
      @env = env
      @body = env['rack.input'].read
    end

    def verb
      env['REQUEST_METHOD'].downcase.to_sym
    end

    def path
      env['REQUEST_PATH']
    end

    def [](field, index = nil)
      case env['CONTENT_TYPE']
        when 'application/x-www-form-urlencoded'
          result = form_fields[field]
          result = result[index] if result and index
          result
        else
          raise "The content type '#{env['CONTENT_TYPE']}' doesn't support indexed access"
      end
    end

    private

    def form_fields
      @form_fields ||= IHash.new(Rack::Utils.parse_query(body).map { |key, value| [key.to_sym, value.is_a?(Array) ? value : [value]] }.to_h)
    end

  end

end
