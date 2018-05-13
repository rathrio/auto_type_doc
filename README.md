# AutoTypeDoc

![Build status](https://travis-ci.org/rathrio/auto_type_doc.svg?branch=master)

Generates type documentation (e.g. YARD tags) by collecting runtime information.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'auto_type_doc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install auto_type_doc

## Usage

Call `AutoTypeDoc.enable` to start collecting type information and
`AutoTypeDoc.dump_json` to store it in `type_doc/types.json` in the current
folder, e.g.

```ruby
# in test.rb
require 'auto_type_doc'

AutoTypeDoc.enable

class Cat
  def bite(dog)
    "Bite #{dog}"
  end
end

class Dog; end

Cat.new.bite(Dog.new)

AutoTypeDoc.dump_json
```

After running this script, e.g. with `ruby test.rb`, `type_doc/types.json` will
contain:

```json
{
  "Cat#bite": {
    "arguments": [
      {
        "name": "dog",
        "types": {
          "Dog": 1
        },
        "kind": "req",
        "position": 0
      }
    ],
    "return_types": {
      "String": 1
    },
    "source_location": {
      "path": "test.rb",
      "line": 6
    }
  }
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rathrio/auto_type_doc.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
