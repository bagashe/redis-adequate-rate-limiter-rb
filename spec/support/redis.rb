# frozen_string_literal: true

require 'redis'

REDIS_URL = ENV.fetch('REDIS_URL', 'redis://localhost').freeze
REDIS = Redis.new(url: REDIS_URL)

RSpec.configure do |config|
  cleanup = proc { REDIS.tap(&:flushdb).script('flush') }

  config.before :suite do
    puts "REDIS_URL=#{REDIS_URL.inspect}"
    puts "REDIS=#{REDIS.inspect}"
  end

  config.before(&cleanup)
  config.after(:suite, &cleanup)
end
