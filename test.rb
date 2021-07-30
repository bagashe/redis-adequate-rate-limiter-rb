require 'redis'
require 'redis/adequate-rate-limiter'

r = Redis.new
x = Redis::AdequateRateLimiter.new(r)

x.configure(r, "ruby-test", 100, 300, 60)

140.times do
  z = x.allow?(r, "ruby-test", 12343, check_only: false)
  println(z)
end

