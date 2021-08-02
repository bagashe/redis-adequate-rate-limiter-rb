# frozen_string_literal: true

require 'redis/adequate_rate_limiter'

RSpec.describe Redis::AdequateRateLimiter do
  subject(:rate_limiter) { described_class.new(REDIS) }

  let(:event_type) { 'api-access' }
  let(:actor) { 'keanu reeves' }

  describe '#configure' do
    it 'configures rate limiting for an event type' do
      expect(REDIS).to receive(:del).once.and_call_original
      expect(REDIS).to receive(:rpush).exactly(3).times.and_call_original

      rate_limiter.configure(REDIS, event_type, 100, 3600, 300)

      config = rate_limiter.peek_config(REDIS, event_type)
      expect(config).to eq(%w[100 3600 300])
    end
  end

  describe '#allow?' do
    before(:each) do
      rate_limiter.configure(REDIS, event_type, 10, 3600, 300)
    end

    it 'should allow the first 9 events by an actor' do
      9.times do
        expect(REDIS).to receive(:evalsha)
          .with(rate_limiter.sha1_digest, any_args)
          .once
          .and_call_original
        allow = rate_limiter.allow?(REDIS, event_type, actor)
        expect(allow).to be true
      end
    end

    it 'should block the actor once the limit is reached' do
      # Set up the block.
      10.times do
        rate_limiter.allow?(REDIS, event_type, actor)
      end

      expect(
        rate_limiter.allow?(REDIS, event_type, actor)
      ).to be false
    end

    it 'should lockout the actor once the limit is reached' do
      # Set up the block.
      10.times do
        rate_limiter.allow?(REDIS, event_type, actor)
      end

      lockout_end_time = Time.now.to_i + 300
      allow(Time).to receive_message_chain(:now, :to_i).and_return(lockout_end_time)
      expect(
        rate_limiter.allow?(REDIS, event_type, actor)
      ).to be false
    end

    it 'should raise error if config is not defined' do
      expect do
        rate_limiter.allow?(REDIS, 'not-defined', actor)
      end.to raise_error(Redis::AdequateRateLimiter::ConfigNotDefinedError)
    end
  end
end
