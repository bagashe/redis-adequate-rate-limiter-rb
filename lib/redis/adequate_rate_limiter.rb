# frozen_string_literal: true

# @see https://github.com/redis/redis-rb
class Redis
  # Wrapper for a Lua script that provides smooth, configurable, space-efficient & blazing fast
  # rate limiting.
  #
  # Usage:
  #
  # require 'redis'
  # require 'redis/adequate_rate_limiter'
  #
  # r = Redis.new
  # rate_limiter = Redis::AdequateRateLimiter.new(r)
  # rate_limiter.configure(r, event_type, max_allowed, over_interval, lockout_interval)
  #
  # ...
  # if rate_limiter.allow?(r, event_type, actor)
  #    # Count this action and check if it is allowed.
  #    ...
  # end
  # ...
  #
  #
  # If `allow?` is invoked on an event type that has not been configured, a
  # ConfigNotDefinedError exception will be raised.
  #
  class AdequateRateLimiter
    # Lua script SHA1 digest
    # @return [String]
    attr_reader :sha1_digest

    # Create a new AdequateRateLimter instance
    # @param redis [Redis]
    def initialize(redis)
      load_script(redis)
    end

    # Configure rate limiting for an event type
    # @param redis [Redis]
    # @param event_type [String]
    # @param max_allowed [Integer]  Maximum allowed events for an actor
    # @param over_interval [Integer] Over a rolling window of seconds
    # @param lockout_interval [Integer] Seconds to lock out an actor from an event.
    # @return [void]
    # See README for more details.
    def configure(redis, event_type, max_allowed, over_interval, lockout_interval)
      key = namespaced_key(event_type)
      redis.del(key)
      redis.rpush(key, max_allowed)
      redis.rpush(key, over_interval)
      redis.rpush(key, lockout_interval)
    end

    # Check if an actor is allowed to perform an action of event_type.
    # @param redis [Redis]
    # @param event_type [String]
    # @param actor [String]
    # @return [Boolean]
    def allow?(redis, event_type, actor)
      q = available_quota(redis, event_type, actor)
      q.positive?
    end

    def peek(redis, event_type, actor)
      redis.lrange(namespaced_key("#{event_type}:#{actor}"), 0, -1)
    end

    def peek_config(redis, event_type)
      redis.lrange(namespaced_key(event_type), 0, -1)
    end

    def namespaced_key(key)
      "arl:#{key}"
    end

    class ConfigNotDefinedError < StandardError
    end

    private
    
    # Fetch remaining quota, as a fraction of max_allowed for an event_type, actor pair.
    # @param redis [Redis]
    # @param event_type [String]
    # @param actor [String]
    # @return [Float]
    def available_quota(redis, event_type, actor)
      keys = [namespaced_key(event_type), actor]
      argv = [Time.now.to_i, 1]

      available_quota = 1.0

      available_quota = redis.evalsha(sha1_digest, keys, argv).to_f
    rescue Redis::CommandError => e
      if e.to_s.include?('NOSCRIPT')
        load_script(redis)
        available_quota = redis.evalsha(sha1_digest, keys, argv).to_f
      elsif e.to_s.include?('No config found')
        raise ConfigNotDefinedError, e.to_s
      end
    ensure
      available_quota
    end

    def load_script(redis)
      lua_code = <<-LUA
        local config_identifier = KEYS[1]
        local actor_identifier = KEYS[2]

        local config = redis.call('lrange', config_identifier, 0, -1)
        if not next(config) then
          return redis.error_reply("No config found for event type - "..config_identifier)
        end

        local max_allowed = tonumber(config[1])
        local over_interval = tonumber(config[2])
        local lockout_interval = tonumber(config[3])
        local expire_in = over_interval + lockout_interval

        local t1 = tonumber(ARGV[1])
        local bump_counter = 0
        if nil ~= ARGV[2] then
          bump_counter = tonumber(ARGV[2])
        end

        local y = nil

        local key = config_identifier..":"..actor_identifier
        local tuple = redis.call('lrange', key, 0, -1)
        -- Tuple format = {last_updated_score, last_updated_timestamp, last_blocked_timestamp}

        if not next(tuple) then
          y = bump_counter
          if bump_counter > 0 then
            -- Update tuple only if an event has occurred.
            redis.call('rpush', key, y)
            redis.call('rpush', key, t1)
            redis.call('rpush', key, 0)
            redis.call('expire', key, expire_in)
          end
        else
          y = tonumber(tuple[1])
          local t0 = tonumber(tuple[2])
          local b = tonumber(tuple[3])

          if t1 - b > lockout_interval then
            -- If not in the lockout interval since the last block
            -- Decay the old score (at t0) using the configured slope to compute the current value.
            y = y - (max_allowed / over_interval) * (t1 - t0)
            y = math.max(y, 0) -- Score cannot drop below 0.

            if bump_counter > 0 then
              -- Update tuple only if an event has occurred.
              y = y + bump_counter

              if y >= max_allowed then
                y = max_allowed -- Score cannot go above max_allowed.
                -- Set t1 as the last_blocked_timestamp
                redis.call('lset', key, 2, t1)
              end

              redis.call('lset', key, 0, string.format("%.4f", y))
              redis.call('lset', key, 1, t1)
              redis.call('expire', key, expire_in)
            end
          end
        end

        return tostring(1.0 - y / max_allowed)
      LUA

      @sha1_digest = redis.script(:load, lua_code.freeze).freeze
    end

  end
end
