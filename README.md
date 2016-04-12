# TypeTracer

TypeTracer collects a set of experimental approaches to statically checking Ruby
"types" (particularly method signatures) while still allowing a decent level of
metaprogramming and without needing to specify annotations in the production
code.

At this point it includes simple proof-of-concept code for several key
approaches to catch some `NoMethodError` cases automatically:

### 1. Enhancing RSpec `instance_double` to check stubbed argument values

Even if you have 100% unit test coverage, there still can be invalid method
calls in the "seams" between your classes or groups of classes.

RSpec's [Verifying Doubles](https://relishapp.com/rspec/rspec-mocks/docs/verifying-doubles),
such as `instance_double` will check that stubbed method calls are actually
defined on a instance of the class you specify and that the method arity (number
of arguments) matches what you are stubbing.

This gem includes an early stage implementation of an
[ArgCheckedInstanceDouble](https://github.com/draffensperger/type_tracer/blob/master/spec/spec_helper.rb#L7)
that parses the abstract syntax tree of the stubbed method to check whether the
arguments to the stubbed call would result in an `NoMethodError` were they actually to be
passed into the stubbed method.

It can only reliably assume that a method will be called on the actual value of
an argument if that argument variable isn't reassigned and if the method doesn't
contain any branches (because it could branch on the type of the argument). A
lot of methods contain branches, so I may try to tighten that requirement (e.g.
that the expression that it branches on must involve the argument).

### 2A. Sampling implied types from production to use in further analysis

This is not a direct way to catch bad method calls, but it's an idea to use the
running production application to gather the real implicit type signature for
methods and then feed that back into the specs or analysis tools as more
realistic type information (without needing to annotate production code or be
super-specific about what the types actually are).

This approach is what gives the gem its name, and the core class for this is
[TypeTracer::Tracer](https://github.com/draffensperger/type_tracer/blob/master/lib/type_tracer/tracer.rb).
It uses the Tracepoint API and I've tested in for some simple cases and it
works.

It's common, for instance, for a method to take either `nil` or a specific value.
It's also decently comment for a method to take a "duck type" i.e. it could take
instances of a range of classes but call a fixed set of methods on all of them.
Sometimes too a method may have an explicit `is_a?` check and do different
things for different types (e.g. a method that operates recursively on a nested
structure that could be either an Array or Hash).

To try to represent as many of those cases as possible, the traced types are in
effect union types of all the different classes that are passed in and what
methods are called on instances of those different classes.

### 2B. Using sampled production types to auto-convert `double` to `instance_double`

This currently has an initial implementation of
[AutoTypeDouble](https://github.com/draffensperger/type_tracer/blob/master/spec/lib/type_tracer/personal_greeter_spec.rb#L5)
that will examine a type hash (of the same form as what the production type
tracer above produces) and automatically use a verifying double based on the
production argument type for the first method the double is passed into.

I don't yet have the appropriate monkey patching to make the actual call to
`double` behave as an `AutoTypeDouble`, but I plan to have that to make this
easy to try out with an existing test suite.

### 2C. Check method calls on arguments based on production traced types

I also wrote a
[MethodChecker](https://github.com/draffensperger/type_tracer/blob/master/lib/type_tracer/method_checker.rb)
class that takes a method signature of the same form as (a subset) of what the
production type tracer above outputs and it will check that the method does not
make undefined method calls on its arguments given those production traced
types.

A similar caveat to the expanded `instance_double` above holds, that the
checking will assume the method is correct if it either contains branches or a
re-assignment of the argument variable (because those cases are harder to
analyze and a common idiom is e.g. `return if x.nil?` or `x ||= default_value`
both of which could change the type of the `x` argument).

### 3. Check instance method calls in app environment (for runtime defined methods)

It's very difficult / impossible to simply statically analyze Ruby code for
undefined methods (though see the
[ruby-lint](https://github.com/YorickPeterse/ruby-lint) gem for something that
does a decent job at it).

My idea instead is to combine static and dynamic analysis of a Ruby program.
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

Here's the initial working code for this
[UndefinedMethodCheck](https://github.com/draffensperger/type_tracer/blob/master/lib/type_tracer/undefined_method_check.rb#L24)
idea. It does not check methods on things like arguments, instance variables,
results of other methods, etc. since simulating all that is pretty tricky
(though again, hats off to the `ruby-lint` for simulating that)

What it does instead is just parses the code and examines top level instance
method calls only. The main missing piece in it is to keep track of the
class/module it's in so that it can link that to the runtime loaded class/module
to check for whether the method is defined or not (right now I just hard-coded
the class it checks to test the rest of the concept).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'type_tracer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install type_tracer

## Usage

At this point the gem is in active development and it isn't ready yet for
general usage. The planned interface for the gem would be as follows:

- A file you can require that makes `instance_double` do the extra checking of
  argument values as explained above.
- A sample initializer script to start the production type tracing and a sample
  route to expose the production type trace for you to get from your app. Also a
  sample Rack middleware that turns on and off tracing randomly so that most
  requests are not type-traced. The production type tracing would provide a way
  to set the Git commit of the production code (e.g. from the Heroku
  `SOURCE_VERSION` env var). The git commit of the production tracing will allow
  a simple form of invalidation based on the diff between the prod code that
  generated the trace and your locally modified code.
- A file you can require that makes `double` behave as `instance_double`
  based on the production type trace as well as an `auto_type_double` if you
  want to specify per-double which use the production type trace.
- A rake task that checks a modified method to see if it makes any undefined
  calls on its arguments based on the traced production types for its arguments.
- A rake task that loads the app's environment and checks for undefined instance
  methods. (Also to include a sample that instantiates all ActiveRecord objects
  to define their DB methods and prevent those as false positives).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/type_tracer.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

