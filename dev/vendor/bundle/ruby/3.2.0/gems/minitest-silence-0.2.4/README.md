# Minitest::Silence

Minitest plugin to capture output to stdout and stderr from tests.

It's best practice for tests to not write anything to `STDOUT` or `STDERR` while running. Besides it being an implicit dependency, it interferes with the output from the test runner. Even though this is a best practice, when your test suite grows large enough, it becomes almost impossible to make sure every test conforms to this best practice.

This plugins aims to solve this problem by rebinding `STDOUT` and `STDERR` while a test is running. Any output written will be redirected to a pipe, so it won't interfere with the output of the test runner. The plugin will also bind `STDIN` to `/dev/null`. This codifies the best practice that automated tests should not depend on user input.

This plugin is inspired by [how the Python test runner handles output](https://docs.pytest.org/en/stable/capture.html).

## Installation

Add this line to your application's Gemfile, and run `bundle install`:

```ruby
gem 'minitest-silence', require: false
```

## Usage

The plugin will be automatically loaded by Minitest if it is in your application's bundle.

- By default, output will be written to `STDOUT` and `STDERR` normally for local test runs, and captured for CI runs. In CI (environments with `ENV["CI"]` set), out put will be captured and discarded, so the output of the test runner will look like how it was intended.
-  If you run tests with the `--verbose` option , it will be nicely included in the test runner's output, inside a box that will tell you what test it originated from.
- You can also run this plugin in "strict mode": by running tests with the `--fail-on-output` option, tests will fail if they produce any output to `STDOUT` or `STDERR`.

You can enable the plugin in any environment by providing the `--enable-silence` command line option to your test invocation. The primary use case for this is when you want to silence output locally.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bin/rake install`. To release a new version, update the version number in `version.rb`, and then run `bin/rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/minitest-silence. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/Shopify/minitest-silence/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Minitest::Silence project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Shopify/minitest-silence/blob/master/CODE_OF_CONDUCT.md).
