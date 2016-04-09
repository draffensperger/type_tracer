module TypeTracer
  class GreetingApp
    def run
      stdio_greeter = TypeTracer::Greeter.new(STDOUT)
      personal_greeter = TypeTracer::PersonalGreeter.new('Dave', stdio_greeter)
      personal_greeter.greet
    end
  end
end
