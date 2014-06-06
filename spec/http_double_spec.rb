require 'net/http'
require 'json'

class TestDouble < HttpDouble::Base
  get '/test' do
    [200, {foo: 'bar'}, 'testing 123']
  end
  post '/echo' do
    [200, {}, JSON.generate(params)]
  end
end

TestDouble.background '127.0.0.1', 27409, log_path: File.expand_path('../../log/test.log', __FILE__)

describe HttpDouble do

  let(:http) { Net::HTTP.new '127.0.0.1', 27409 }
  let(:log) { TestDouble.log }

  before { log.clear }

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

  describe 'form data' do

    before :each do
      @response = http.post '/echo', 'a=1&a=2&b=3', 'Content-Type' => 'application/x-www-form-urlencoded'
    end

    it 'should allow array access to request data' do
      expect(log.first.request['a']).to eq %w[1 2]
      expect(log.first.request[:b]).to eq %w[3]
    end

  end

end
