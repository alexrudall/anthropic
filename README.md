# Anthropic (WIP)

[![Gem Version](https://badge.fury.io/rb/anthropic.svg)](https://badge.fury.io/rb/anthropic)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/alexrudall/anthropic/blob/main/LICENSE.txt)
[![CircleCI Build Status](https://circleci.com/gh/alexrudall/anthropic.svg?style=shield)](https://circleci.com/gh/alexrudall/anthropic)

Use the [Anthropic API](https://docs.anthropic.com/claude/reference/getting-started-with-the-api) with Ruby! 🌌❤️

You can apply for access to the API [here](https://docs.anthropic.com/claude/docs/getting-access-to-claude).

[Ruby AI Builders Discord](https://discord.gg/k4Uc224xVD)

[Rails AI Guides](https://railsai.com)

Follow me on [Twitter](https://twitter.com/alexrudall) for more Ruby / AI content!

### Bundler

Add this line to your application's Gemfile:

```ruby
gem "anthropic"
```

And then execute:

$ bundle install

### Gem install

Or install with:

$ gem install anthropic

and require with:

```ruby
require "anthropic"
```

## Usage

- Get your API key from [https://console.anthropic.com/account/keys](https://console.anthropic.com/account/keys)

### Quickstart

For a quick test you can pass your token directly to a new client:

```ruby
client = Anthropic::Client.new(access_token: "access_token_goes_here")
```

### With Config

For a more robust setup, you can configure the gem with your API keys, for example in an `anthropic.rb` initializer file. Never hardcode secrets into your codebase - instead use something like [dotenv](https://github.com/motdotla/dotenv) to pass the keys safely into your environments.

```ruby
Anthropic.configure do |config|
    config.access_token = ENV.fetch("ANTHROPIC_API_KEY")
end
```

Then you can create a client like this:

```ruby
client = Anthropic::Client.new
```

#### Change version or timeout

You can change to a different dated version (different from the URL version which is just `v1`) of Anthropic's API by passing `anthropic_version` when initializing the client. If you don't the default latest will be used, which is "2023-06-01". [More info](https://docs.anthropic.com/claude/reference/versioning)

The default timeout for any request using this library is 120 seconds. You can change that by passing a number of seconds to the `request_timeout` when initializing the client.

```ruby
client = Anthropic::Client.new(
    access_token: "access_token_goes_here",
    anthropic_version: "2023-01-01", # Optional
    request_timeout: 240 # Optional
)
```

You can also set these keys when configuring the gem:

```ruby
Anthropic.configure do |config|
    config.access_token = ENV.fetch("ANTHROPIC_API_KEY")
    config.anthropic_version = "2023-01-01" # Optional
    config.request_timeout = 240 # Optional
end
```

### Completions

Hit the Anthropic API for a completion:

```ruby
response = client.complete(
    parameters: {
        model: "claude-2",
        prompt: "Once upon a time",
        max_tokens: 5
    })
puts response["choices"].map { |c| c["text"] }
# => [", there lived a great"]
```

Note that all requests are prepended by this library with

`\n\nHuman: `

and appended with

`\n\nAssistant:`

so whatever prompt you pass will be sent to the API as

`\n\nHuman: Once upon a time\n\nAssistant:`

This is a requirement of [the API](https://docs.anthropic.com/claude/reference/complete_post).

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

### Warning

If you have an `ANTHROPIC_API_KEY` in your `ENV`, running the specs will use this to run the specs against the actual API, which will be slow and cost you money - 2 cents or more! Remove it from your environment with `unset` or similar if you just want to run the specs against the stored VCR responses.

## Release

First run the specs without VCR so they actually hit the API. This will cost 2 cents or more. Set ANTHROPIC_API_KEY in your environment or pass it in like this:

```
ANTHROPIC_API_KEY=123abc bundle exec rspec
```

Then update the version number in `version.rb`, update `CHANGELOG.md`, run `bundle install` to update Gemfile.lock, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/alexrudall/anthropic>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/alexrudall/anthropic/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ruby Anthropic project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/alexrudall/anthropic/blob/main/CODE_OF_CONDUCT.md).
