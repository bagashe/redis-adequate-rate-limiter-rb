Gem::Specification.new do |s|
  s.name        = 'redis-adequate-rate-limiter'
  s.version     = '0.0.0'
  s.summary     = "Provides rate limiting using Redis & a Lua script."
  s.description = "Uses a Lua extension for Redis to provide smooth, configurable, space-efficient &
blazing fast rate limiting."
  s.authors     = ["Bhal Agashe"]
  s.email       = 'bhalchandra@gmail.com'
  s.files       = ["lib/redis/adequate-rate-limiter.rb"]
  s.homepage    =
    'https://rubygems.org/gems/redis-adequate-rate-limiter'
  s.license       = 'MIT'
end
