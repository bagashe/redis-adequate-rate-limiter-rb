# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'redis-adequate-rate-limiter'
  s.version     = '0.0.0'
  s.summary     = 'Provides rate limiting using Redis & a Lua script.'
  s.description = <<~DESCRIPTION
    Uses a Lua extension for Redis to provide smooth, configurable, space-efficient &
    blazing fast rate limiting. As this is extremely light weight, it can be used to rate limit
    access to any resource at scale. Linked homepage has the details.
  DESCRIPTION
  s.authors     = ['Bhal Agashe']
  s.email       = 'bhalchandra@gmail.com'
  s.files       = ['lib/redis/adequate_rate_limiter.rb']
  s.homepage    =
    'https://github.com/bagashe/redis-adequate-rate-limiter-rb'
  s.license = 'MIT'
  s.required_ruby_version = '~> 2.7'
  s.add_runtime_dependency 'redis', '~> 4.0'
  s.require_paths = ['lib']
end
