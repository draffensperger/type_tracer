module TypeTracer
  class Greeter
    HELLOS = {
      english: 'Hello',
      spanish: 'Hola'
    }.freeze

    def initialize(stream)
      @stream = stream
    end

    def greet(name, language)
      language ||= 'english'
      @stream.puts("#{HELLOS[language.downcase.to_sym]} #{name}!")
    end
  end
end
