# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'saxinator/version'

Gem::Specification.new do |spec|
  spec.name          = 'saxinator'
  spec.version       = Saxinator::VERSION
  spec.authors       = ['Chris Osborn', 'Ken Mayer']
  spec.email         = %w(chrisosb@gmail.com ken@bitwrangler.com)

  spec.summary       = %q{A SAX parser that uses a 'haml'-like DSL}
  spec.description   = %q{A SAX parser that uses a 'haml'-like DSL}
  spec.homepage      = 'https://github.com/PacerPRO/saxinator'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'nokogiri', '~> 1.6'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
