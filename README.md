This gem allows you to double external HTTP services using [Sinatra](http://www.sinatrarb.com/). Your server(s) will be run in the background using [Thin](http://code.macournoyer.com/thin/) each time you run your tests/specs.

## Installation

```bash
$ gem install http-double
```

## Usage

First, define a server double:

```ruby
require 'http-double'

class HelloDouble < HttpDouble::Base
  get '/hello' do
    [
      200, 
      {'Content-Type' => 'application/json'}, 
      ['{"greeting":"Hello!"}']
    ]
  end
end
```

Then background it in your spec helper or test setup routine, specifying a local address and port:

```ruby
HelloDouble.background '127.0.0.1', 1357
```

You can now write functional tests against your double, using no-nonsense HTTP over honest-to-goodness TCP.

```ruby
describe 'The "Hello" server' do
  it 'should greet me politely' do
    response = Net::HTTP.get_response(URI 'http://127.0.0.1:1357/hello').body
    expect(response).to include 'Hello!'
  end
end
```

### Expectations on Traffic

Every request/response to/from an HTTP double is recorded in its `log`. To use the log effectively, clear it before each test.

```ruby
before :each do
  HelloDouble.log.clear
end
```

Each member of the `log` array contains a `request` and a `response`. Here's a contrived example:

```ruby
describe 'The "Hello" server' do
  it 'should record traffic' do
    log = HelloDouble.log
    Net::HTTP.get_response URI 'http://127.0.0.1:1357/hello'
    
    expect(log.count).to be 1
    
    expect(log.last.request.verb).to be :get
    expect(log.last.request.path).to eq '/hello'
    expect(log.last.request.body).to be_nil
    
    expect(log.last.response.code).to be 200
    expect(log.last.response.headers['Content-Type']).to eq 'application/json'
    expect(JSON.parse(log.last.response.body)['greeting']).to eq 'Hello!'
  end
end
```

In functional tests, you will tend to mostly want to test what your application sends. The log's request object lets you set expectations using indexed access:

```ruby
def be_a_cowboy!
  uri = URI 'http://127.0.0.1:1357/hello'
  Net::HTTP.post_form uri, 'new_greeting' => 'Howdy!'
end

describe 'Something that changes my greeting' do
  it 'should act like a cowboy' do
    be_a_cowboy!
    request = HelloDouble.log.last.request
    
    expect(request.verb).to be :post
    expect(request.path).to eq '/hello'
    expect(request['new_greeting']).to eq 'Howdy!'
  end
end
```

You can use indexed access on any request sent as valid `application/x-www-form-urlencoded` or `application/json`.