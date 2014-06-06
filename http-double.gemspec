# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'http_double/version'

Gem::Specification.new do |spec|
  spec.name          = 'http-double'
  spec.version       = HttpDouble::VERSION
  spec.authors       = ['Neil E. Pearson']
  spec.email         = ['neil@helium.net.au']
  spec.summary       = 'Sinatra-based HTTP test doubling'
  spec.description   = 'Provides a simple way to double HTTP services, APIs etc, for testing.'
  spec.homepage      = 'https://github.com/hx/http-double'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\x0")
  spec.require_paths = ['lib']

  spec.add_dependency 'sinatra', '~> 1.4'
  spec.add_dependency 'rack',    '~> 1.5'
  spec.add_dependency 'thin',    '~> 1.6'
  spec.add_dependency 'activesupport', '~> 4.1'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '>= 10.1'
  spec.add_development_dependency 'rspec', '3.0.0.beta2'
end
