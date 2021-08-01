# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'redis-adequate-rate-limiter'
  s.version     = '0.0.0'
  s.summary     = 'Provides rate limiting using Redis & a Lua script.'
  s.description = <<~DESCRIPTION
    Uses a Lua script for Redis to provide smooth, configurable, space-efficient &
    blazing fast rate limiting. The script is very light weight and performs the entire operation
    atomically. So it can be used to rate limit access to any resource at scale. Linked homepage
    has more details.
  DESCRIPTION
  s.authors     = ['Bhal Agashe']
  s.email       = ''
  s.files       = ['lib/redis/adequate_rate_limiter.rb']
  s.homepage    =
    'https://github.com/bagashe/redis-adequate-rate-limiter-rb'
  s.license = 'MIT'
  s.required_ruby_version = '~> 2'
  s.add_runtime_dependency 'redis', '~> 4.0'
  s.require_paths = ['lib']
end
