# Anthropic

[![Gem Version](https://badge.fury.io/rb/anthropic.svg)](https://badge.fury.io/rb/anthropic)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/alexrudall/anthropic/blob/main/LICENSE.txt)
[![CircleCI Build Status](https://circleci.com/gh/alexrudall/anthropic.svg?style=shield)](https://circleci.com/gh/alexrudall/anthropic)

Use the [Anthropic API](https://docs.anthropic.com/claude/reference/getting-started-with-the-api) with Ruby! 🤖🌌

You can get access to the API [here](https://docs.anthropic.com/claude/docs/getting-access-to-claude).

[🎮 Ruby AI Builders Discord](https://discord.gg/k4Uc224xVD) | [🐦 Twitter](https://twitter.com/alexrudall) | [🤖 OpenAI Gem](https://github.com/alexrudall/ruby-openai) | [🚂 Midjourney Gem](https://github.com/alexrudall/midjourney)

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

For a more robust setup, you can configure the gem with your API keys, for example in an `anthropic.rb` initializer file. Never hardcode secrets into your codebase - instead use something like [dotenv](https://github.com/motdotla/dotenv) to pass the keys safely into your environments or rails credentials if you are using this in a rails project.

```ruby
Anthropic.configure do |config|
  # With dotenv
  config.access_token = ENV.fetch("ANTHROPIC_API_KEY")
  # OR
  # With Rails credentials
  config.access_token = Rails.application.credentials.dig(:anthropic, :api_key)
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

### Models

Available Models:

| Name            | API Name                 |
| --------------- | ------------------------ |
| Claude 3 Opus   | claude-3-opus-20240229   |
| Claude 3 Sonnet | claude-3-sonnet-20240229 |
| Claude 3 Haiku  | claude-3-haiku-20240307  |

You can find the latest model names in the [Anthropic API documentation](https://docs.anthropic.com/claude/docs/models-overview#model-recommendations).

### Messages

```
POST https://api.anthropic.com/v1/messages
```

Send a sequence of messages (user or assistant) to the API and receive a message in response.

```ruby
response = client.messages(
  parameters: {
    model: "claude-3-haiku-20240307", # claude-3-opus-20240229, claude-3-sonnet-20240229
    system: "Respond only in Spanish.",
    messages: [
      {"role": "user", "content": "Hello, Claude!"}
    ],
    max_tokens: 1000
  }
)
# => {
# =>   "id" => "msg_0123MiRVCgSG2PaQZwCGbgmV",
# =>   "type" => "message",
# =>   "role" => "assistant",
# =>   "content" => [{"type"=>"text", "text"=>"¡Hola! Es un gusto saludarte. ¿En qué puedo ayudarte hoy?"}],
# =>   "model" => "claude-3-haiku-20240307",
# =>   "stop_reason" => "end_turn",
# =>   "stop_sequence" => nil,
# =>   "usage" => {"input_tokens"=>17, "output_tokens"=>32}
# => }
```

#### Vision

Claude 3 family of models comes with vision capabilities that allow Claude to understand and analyze images.

Transform an image to base64 and send to the API.

```ruby
require 'base64'

image = File.open(FILE_PATH, 'rb') { |file| file.read }

imgbase64 = Base64.strict_encode64(image)

response = client.messages(
  parameters: {
    model: "claude-3-haiku-20240307", # claude-3-opus-20240229, claude-3-sonnet-20240229
    system: "Respond only in Spanish.",
    messages: [
      {"role": "user", "content": [
        {
          "type":"image","source":
          {"type":"base64","media_type":"image/png", imgbase64 }
        },
        {"type":"text","text":"What is this"}
        ]
      }
    ],
    max_tokens: 1000
  }
)

# => {
# =>   "id" => "msg_0123MiRVCgSG2PaQZwCGbgmV",
# =>   "type" => "message",
# =>   "role" => "assistant",
# =>   "content" => [{"type"=>"text", "text"=>"This
# =>    image depicts a person, presumably a student or young adult, holding a tablet
# =>    device. "}],
# =>   "model" => "claude-3-haiku-20240307",
# =>   "stop_reason" => "end_turn",
# =>   "stop_sequence" => nil,
# =>   "usage" => {"input_tokens"=>17, "output_tokens"=>32}
# => }
```


#### Additional parameters

You can add other parameters to the parameters hash, like `temperature` and even `top_k` or `top_p`. They will just be passed to the Anthropic server. You
can read more about the supported parameters [here](https://docs.anthropic.com/claude/reference/messages_post).

There are two special parameters, though, to do with... streaming. Keep reading to find out more.

#### JSON

If you want your output to be json, it is recommended to provide an additional message like this:

```ruby
[{ role: "user", content: "Give me the heights of the 3 tallest mountains. Answer in the provided JSON format. Only include JSON." },
{ role: "assistant", content: '[{"name": "Mountain Name", "height": "height in km"}]' }]
```

Then Claude v3, even Haiku, might respond with:

```ruby
[{"name"=>"Mount Everest", "height"=>"8.85 km"}, {"name"=>"K2", "height"=>"8.61 km"}, {"name"=>"Kangchenjunga", "height"=>"8.58 km"}]
```

### Streaming

There are two modes of streaming: raw and preprocessed. The default is raw. You can call it like this:

```ruby
client.messages(
  parameters: {
    model: "claude-3-haiku-20240307",
    messages: [{ role: "user", content: "How high is the sky?" }],
    max_tokens: 50,
    stream: Proc.new { |chunk| print chunk }
  }
)
```

This still returns a regular response at the end, but also gives you direct access to every single chunk returned by Anthropic as they come in. Even if you don't want to
use the streaming, you may find this useful to avoid timeouts, which can happen if you send Opus a large input context, and expect a long response... It has been known to take
several minutes to compile the full response - which is longer than our 120 second default timeout. But when streaming, the connection does not time out.

Here is an example of a stream you might get back:

```ruby
{"type"=>"message_start", "message"=>{"id"=>"msg_01WMWvcZq5JEMLf6Jja4Bven", "type"=>"message", "role"=>"assistant", "model"=>"claude-3-haiku-20240307", "stop_sequence"=>nil, "usage"=>{"input_tokens"=>13, "output_tokens"=>1}, "content"=>[], "stop_reason"=>nil}}
{"type"=>"content_block_delta", "index"=>0, "delta"=>{"type"=>"text_delta", "text"=>"There"}}
{"type"=>"content_block_delta", "index"=>0, "delta"=>{"type"=>"text_delta", "text"=>" is"}}
{"type"=>"content_block_delta", "index"=>0, "delta"=>{"type"=>"text_delta", "text"=>" no"}}
{"type"=>"content_block_delta", "index"=>0, "delta"=>{"type"=>"text_delta", "text"=>" single"}}
{"type"=>"content_block_delta", "index"=>0, "delta"=>{"type"=>"text_delta", "text"=>" defin"}}
{"type"=>"content_block_delta", "index"=>0, "delta"=>{"type"=>"text_delta", "text"=>"itive"}}
{"type"=>"content_block_delta", "index"=>0, "delta"=>{"type"=>"text_delta", "text"=>" \""}}
...
{"type"=>"content_block_delta", "index"=>0, "delta"=>{"type"=>"text_delta", "text"=>"'s"}}
{"type"=>"content_block_delta", "index"=>0, "delta"=>{"type"=>"text_delta", "text"=>" atmosphere"}}
{"type"=>"content_block_delta", "index"=>0, "delta"=>{"type"=>"text_delta", "text"=>" extends"}}
{"type"=>"content_block_delta", "index"=>0, "delta"=>{"type"=>"text_delta", "text"=>" up"}}
{"type"=>"content_block_delta", "index"=>0, "delta"=>{"type"=>"text_delta", "text"=>" to"}}
{"type"=>"content_block_delta", "index"=>0, "delta"=>{"type"=>"text_delta", "text"=>" about"}}
{"type"=>"content_block_stop", "index"=>0}
{"type"=>"message_delta", "delta"=>{"stop_reason"=>"max_tokens", "stop_sequence"=>nil}, "usage"=>{"output_tokens"=>50}}
{"type"=>"message_stop"}
```

Now, you may find this... somewhat less than practical. Surely, the vast majority of developers will not want to deal with so much
boilerplate json.

Luckily, you can ask the anthropic gem to preprocess things for you!

First, if you expect simple text output, you can receive it delta by delta:

```ruby
client.messages(
  parameters: {
    model: "claude-3-haiku-20240307",
    messages: [{ role: "user", content: "How high is the sky?" }],
    max_tokens: 50,
    stream: Proc.new { |incremental_response, delta| process_your(incremental_response, delta) },
    preprocess_stream: :text
  }
)
```

The first block argument, `incremental_response`, accrues everything that's been returned so far, so you don't have to. If you just want the last bit,
then use the second, `delta` argument.

But what if you want to stream JSON?

Partial JSON is not very useful. But it is common enough to request a collection of JSON objects as a response, as in our earlier example of asking for the heights of the 3 tallest mountains.

If you ask it to, this gem will also do its best to sort this out for you:

```ruby
client.messages(
  parameters: {
    model: "claude-3-haiku-20240307",
    messages: [{ role: "user", content: "How high is the sky?" }],
    max_tokens: 50,
    stream: Proc.new { |json_object| process_your(json_object) },
    preprocess_stream: :json
  }
)
```

Each time a `}` is reached in the stream, the preprocessor will take what it has in the preprocessing stack, pick out whatever's between the widest `{` and `}`, and try to parse it into a JSON object.
If it succeeds, it will pass you the json object, reset its preprocessing stack, and carry on.

If the parsing fails despite reaching a `}`, currently, it will catch the Error, log it to `$stdout`, ignore the malformed object, reset the preprocessing stack and carry on. This does mean that it is possible,
if the AI is sending some malformed JSON (which can happen, albeit rarely), that some objects will be lost.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To run all tests, execute the command `bundle exec rake`, which will also run the linter (Rubocop). This repository uses [VCR](https://github.com/vcr/vcr) to log API requests.

> [!WARNING]
> If you have an `ANTHROPIC_API_KEY` in your `ENV`, running the specs will use this to run the specs against the actual API, which will be slow and cost you money - 2 cents or more! Remove it from your environment with `unset` or similar if you just want to run the specs against the stored VCR responses.

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
