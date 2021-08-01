# frozen_string_literal: true

require 'redis'
require 'redis/adequate_rate_limiter'

r = Redis.new
x = Redis::AdequateRateLimiter.new(r)

x.configure(r, 'ruby-test', 100, 300, 60)

140.times do
  z = x.allow?(r, 'ruby-test', 12_343, check_only: false)
  print("#{z}\n")
end
