# Redis::Test

This is a super simple gems to help start/stop an instance of test redis
server during test.

There is different option out there like fakeredis but I dislike this
approach as it require the gem to re-implement all the functionality of
redis.

My approach is super simple, and may be already widely used:
Start a redis server on port 9736 (can be
customized by setting ENV['TEST_REDIS_PORT']) and simply change your
config so your redis client will connect there during test instead.

I just try to package it in a convenient way :)

## Installation

Add this line to your application's Gemfile:

    gem 'redis-test', require: 'redis/test'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis-test

## Usage

You can use it with RSpec: (put this in spec/support/)


```
RSpec.configure do |config|
  config.before(:suite) do
    Redis::Test.start
    Redis.current = Redis.new("redis://localhost:9736")
    # If you use sidekiq, you need to config redis for sidekiq as well
    # Sidekiq.configure_server do |config|
    #   config.redis = { url: 'redis://localhost:9736', namespace: 'mynamespace' }
    # end

    # Sidekiq.configure_client do |config|
    #   config.redis = { url: 'redis://localhost:9736', namespace: 'mynamespace' }
    # end
  end

  config.before(:each) do
    Redis::Test.clear
  end

  config.after(:suite) do
    Redis::Test.stop
  end
end
```

Or Cucumber: (put this in features/support/)
```
Redis::Test.start # start this when cucumber load

Before do
  Redis::Test.clear
end

at_exit do
  Redis::Test.stop
end

```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
