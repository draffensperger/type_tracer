# TypeTracer

[![Build Status](https://travis-ci.org/draffensperger/type_tracer.svg?branch=master)](https://travis-ci.org/draffensperger/type_tracer) [![Code Climate](https://codeclimate.com/github/draffensperger/type_tracer.png)](https://codeclimate.com/github/draffensperger/type_tracer)

TypeTracer collects a set of experimental approaches to checking Ruby
"types" (particularly method signatures) while still allowing a decent level of
metaprogramming and without needing to specify annotations in the production
code.

It includes three proof-of-concept approaches to catch some `NoMethodError`
cases automatically.

See [tt_demos](https://github.com/draffensperger/tt_demos) for an example of using
approach 1.,
and [quote-randomizer](https://github.com/draffensperger/quote-randomizer)
for a simple Rails app that incorporates support for approaches 2. and 3.

### 1. Enhancing RSpec `instance_double` to check stubbed argument values

Even if you have 100% unit test coverage, there still can be invalid method
calls in the "seams" between your classes or groups of classes.

RSpec's [Verifying Doubles](https://relishapp.com/rspec/rspec-mocks/docs/verifying-doubles),
such as `instance_double` will check that stubbed method calls are actually
defined on a instance of the class you specify and that the method arity (number
of arguments) matches what you are stubbing.

This gem includes a file you can include which monkey-patches `instance_double`
to parse the abstract syntax tree of the stubbed method to check whether the
arguments to the stubbed call would result in an `NoMethodError` were they actually to be passed into the stubbed method.

To make your `instance_double`'s behave like that, include `type_tracer` in your
`Gemfile` and add `require 'type_tracer/rspec/Instance_double_arg_checker`.

It can only reliably assume that a method will be called on the actual value of
an argument if that argument variable isn't reassigned and if the method doesn't
contain any branches (because it could branch on the type of the argument). A
lot of methods contain branches, so I may try to tighten that requirement (e.g.
that the expression that it branches on must involve the argument).

### 2. Check instance method calls in app environment (for runtime defined methods)

It's very difficult / impossible to simply statically analyze Ruby code for
undefined methods (though see the
[ruby-lint](https://github.com/YorickPeterse/ruby-lint) gem for something that
does a decent job at it).

The approach here is instead to combine static and dynamic analysis of a Ruby program.
That is to run the "undefined method" analysis in the context of a fully loaded
app environment where many/most of the dynamically defined methods have been
defined. In a typical Rails app for instance, the `has_many` association methods
would be defined when a class is loaded.

However, the database attribute methods for `ActiveRecord` objects won't be
defined until a request on that class is made e.g. from a call to `new`. My idea
would be for `TypeTracer` to provide a config option for a block that could be
called to induce most of the dynamically defined methods to get defined, e.g. by
calling `new` on all of the `ActiveRecord::Base` subclasses and perhaps doing
other application-specific method defining. Of course, not all dynamic methods
are defined in easy-to-induce ways, but this would still catch a lot of them.

To use it, include the `type_tracer` gem in your `Gemfile`, then, assuming
you're running a Rails app, you can run a new Rake task
`rake type_tracer:check_method_calls` that will check for undefined top-level
instance method calls (i.e. calls on `self` in methods).

It's possible that you will have methods that are defined not at the time that a
class is first loaded but later in the app runtime. E.g. ActiveRecord attribute
methods aren't defined until the first ActiveRecord operation for that model.

What `type_tracer` provides is a config option called `attribute_methods_definer`
that specifies a proc that is called after the app environment is loaded but
before the analysis starts. Here's an example that will call `new` on all
classes that inherit from `ActiveRecord::Base` which will have the effect of
making those classes define their attribute methods.

```
# config/initializers/type_tracer.rb
require 'type_tracer'

TypeTracer.config do |config|
  config.attribute_methods_definer = proc do
    # initialize all of the active record models so that they will define their
    # attribute methods.
    ActiveRecord::Base.descendants.each(&:new)
  end
end
```

This is similar to how you would define attribute methods for a dynamic class if
you are using RSpec verifying doubles, see their doc for
[dynamic-classes](https://relishapp.com/rspec/rspec-mocks/docs/verifying-doubles/dynamic-classes)

### 3A. Sampling implied types from production to use in further analysis

This is not a direct way to catch bad method calls, but it's an idea to use the
running production application to gather the real implicit type signature for
methods and then feed that back into the specs or analysis tools as more
realistic type information (without needing to annotate production code or be
super-specific about what the types actually are).

It's common, for instance, for a method to take either `nil` or a specific value.
It's also decently comment for a method to take a "duck type" i.e. it could take
instances of a range of classes but call a fixed set of methods on all of them.
Sometimes too a method may have an explicit `is_a?` check and do different
things for different types (e.g. a method that operates recursively on a nested
structure that could be either an Array or Hash).

To try to represent as many of those cases as possible, the traced types are in
effect union types of all the different classes that are passed in and what
methods are called on instances of those different classes.

To use type tracing in your Rails app, include the `type_tracer` gem, and then
add an initializer like this:

```
# config/initializers/type_tracer.rb
require 'type_tracer'

TypeTracer.config do |config|
  # This configures an Rack middleware for what requests to type sample on
  config.sample_types_for_requests do |_rack_env|
    # Only type sample 1% of requests
    rand() > 0.01
  end

  # These configure the files to do type sampling on and the remote URL of the
  # sampled types endpoint in a deployed app.
  config.type_check_root_path = Rails.root
  config.type_check_path_regex = %r{\A(app|lib)/}
  config.sampled_types_url = 'https://quote-randomizer.herokuapp.com/sampled_types'

  # To make the sampled types useful for checking local changes, we need to be
  # able to know the git commit that produced the sampled types in case they are
  # no longer applicable given local changes (if you changed the callers of the
  # method in question).
  # This will give the git commit on Heroku, though requires this buildpack:
  # https://github.com/ianpurvis/heroku-buildpack-version
  config.git_commit = ENV['SOURCE_VERSION']
end
```

You'll also need to set up an endpoint in your app that will serve the sampled
types (as referenced above with the `sampled_types_url`). Here's an example
controller (that would need a corresponding route as well):

```
class SampledTypesController < ApplicationController
  def show
    render json: JSON.pretty_generate(TypeTracer::TypeSampler.sampled_type_info)
  end
end
```

### 3B. Using sampled types to check local changes to a method for undefined method calls on arguments

To use the sampled method type signatures from a deployed app, run
`rake type_tracer:check_arg_sends`. That will fetch the sampled types and Git
commit hash from your specified `sampled_types_url`. It assumes you are using
Git for your project and have the `git` executable installed.

A similar caveat to the expanded `instance_double` above holds, that the
checking will assume the method is correct if it either contains branches or a
re-assignment of the argument variable (because those cases are harder to
analyze and a common idiom is e.g. `return if x.nil?` or `x ||= default_value`
both of which could change the type of the `x` argument).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'type_tracer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install type_tracer

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/type_tracer.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

