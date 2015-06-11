require 'net/http'
require 'json'

class TestMiddleware
  @calls = 0
  class << self
    attr_accessor :calls, :arg
  end
  def initialize(app, arg)
    @app = app
    self.class.arg = arg
  end
  def call(env)
    self.class.calls += 1
    @app.call env
  end
end

class TestDouble < HttpDouble::Base
  get '/test' do
    [200, {foo: 'bar'}, 'testing 123']
  end
  post '/echo' do
    [200, {}, [request.body.read]]
  end
  get '/silent' do
    [200, {'Suppress-Logging' => '1'}, ['do not log this']]
  end
end

TestDouble.use TestMiddleware, 'dont argue'
TestDouble.background '127.0.0.1', 27409, log_path: File.expand_path('../../log/test.log', __FILE__)

describe HttpDouble do

  let(:http) { Net::HTTP.new '127.0.0.1', 27409 }
  let(:log) { TestDouble.log }

  before { log.clear }

  describe 'log suppression' do

    before { http.get '/silent' }

    it 'should respond to the DO_NOT_LOG header' do
      expect(log).to be_empty
    end

  end

  describe 'basic requests' do

    before :each do
      @response = http.get('/test')
    end

    it 'should run in the background' do
      expect(@response).to be_a Net::HTTPOK
      expect(@response.body).to eq 'testing 123'
    end

    it 'should log one action per request' do
      expect(log.size).to be 1
    end

    it 'should log a request and a response' do
      expect(log.first).to respond_to :request
      expect(log.first).to respond_to :response
    end

    it 'should log the request verb and path' do
      expect(log.first.request.verb).to be :get
      expect(log.first.request.path).to eq '/test'
    end

    describe 'logged response' do

      subject { log.first.response }

      it 'should include the status code' do
        expect(subject.code).to be 200
      end

      it 'should include response headers' do
        expect(subject.headers['foo']).to eq 'bar'
      end

      it 'should include the response body' do
        expect(subject.body).to eq 'testing 123'
      end

    end

  end

  describe 'middleware' do

    it 'should be used' do
      expect { http.get '/test' }.to change { TestMiddleware.calls }.by 1
    end

    it 'should take arguments' do
      expect(TestMiddleware.arg).to eq 'dont argue'
    end

  end

  describe 'form data' do

    before :each do
      http.post '/echo', 'a=1&a=2&b=3', 'Content-Type' => 'application/x-www-form-urlencoded'
    end

    it 'should allow array access to request data' do
      expect(log.first.request['a']).to eq %w[1 2]
      expect(log.first.request[:b]).to eq %w[3]
    end

  end

  describe 'JSON' do

    subject { log.first.request }

    describe 'hashes' do

      before :each do
        http.post '/echo', JSON.generate(a:1, b: [2, 3], c: :c, d: {e: :f}), 'Content-Type' => 'application/json'
      end

      it 'should allow array access to request data' do
        expect(subject['a']).to be 1
        expect(subject['b']).to eq [2, 3]
        expect(subject['c']).to eq 'c'
        expect(subject['d']).to eq('e' => 'f')
      end

    end

    describe 'arrays' do

      before :each do
        http.post '/echo', JSON.generate([1, 'a', [4, 5, 6]]), 'Content-Type' => 'application/json'
      end

      it 'should allow array access to request data' do
        expect(subject[0]).to be 1
        expect(subject[1]).to eq 'a'
        expect(subject[2]).to eq [4, 5, 6]
      end

      it 'should provide array methods' do
        expect(subject.first).to be 1
        expect(subject.last).to eq [4, 5, 6]
        expect(subject.size).to be 3
      end

    end

  end

end
