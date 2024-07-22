REDIS_URL = ENV.fetch('REDIS_URL', 'redis://redis:6379')
REDIS_CLI = Redis.new(url: REDIS_URL)
