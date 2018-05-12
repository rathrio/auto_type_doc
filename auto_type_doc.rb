require 'irb'
require 'pry'
require 'json'
require 'set'

module AutoTypeDoc
  JSON_FILE = './types.json'

  class Argument
    attr_reader :name, :types, :kind, :position

    def initialize(name:, kind:, position:)
      @name = name.to_s
      @kind = kind.to_s
      @types = Hash.new(0)
      @position = position
    end

    def add_type(type)
      type = type.to_s
      types[type] += 1
    end

    def ==(other)
      name == other.name
    end

    def eql?(other)
      self == other
    end

    def hash
      name.hash
    end

    def to_h
      {
        name: name,
        types: types,
        kind: kind,
        position: position
      }
    end
  end

  class MethodInfo
    attr_accessor :arguments
    attr_accessor :return_types
    attr_accessor :source_location

    def initialize(source_location:)
      @source_location = source_location
      @arguments = Set.new
      @return_types = Hash.new(0)
    end

    def source_file
      source_location[0]
    end

    def source_line
      source_location[1]
    end

    def argument(name)
      arguments.find { |a| a.name == name.to_s }
    end

    def add_argument(name:, type:, kind:, position:)
      if (a = argument(name))
        a.add_type(type)
      else
        a = Argument.new(name: name, kind: kind, position: position)
        a.add_type(type)
        arguments << a
      end
    end

    def add_return_type(type)
      return_types[type.to_s] += 1
    end

    # @return [String]
    def most_frequent_arg_type(arg_name)
      most_frequent_type(argument(arg_name).types)
    end

    # @return [String]
    def most_frequent_return_type
      most_frequent_type(return_types)
    end

    def to_h
      {
        arguments: arguments.map(&:to_h),
        return_types: return_types,
        source_location: {
          file: source_file,
          line: source_line
        }
      }
    end

    def to_json(*args)
      to_h.to_json(*args)
    end

    private

    def most_frequent_type(type_hash)
      type_hash.max_by { |_, count| count }[0]
    end
  end

  Tracker = TracePoint.new(:call, :return) do |t|
    begin
      method = t.self.method(t.method_id)
    rescue
      next
    end

    next if method.to_s =~ /Test|AutoTypeDoc|Minitest|RSpec|Gem|main|OptionParser|FileUtils|Mutex_m|Kernel/

    case t.event
    when :call
      next if method.parameters.empty?
      on_call(t, method: method)
    when :return
      on_return(t, method: method)
    end
  end

  module_function

  def method_name_with_owner(method)
    method.to_s[/^#<Method:\s(.+)>$/, 1].sub(/^.+\((.+)\)/, '\1')
  end

  def on_call(t, method:)
    method_info = method_info(method)

    method.parameters.each_with_index do |(kind, name), index|
      begin
        obj = t.binding.local_variable_get(name)
      rescue
        next
      end

      method_info.add_argument(
        name: name,
        type: type(obj),
        kind: kind,
        position: index
      )
    end
  end

  # @return [String]
  def type(obj)
    if obj.is_a?(Array) && obj.any?
      return "#{obj.class}<#{obj.first.class}>"
    end

    obj.class
  end

  def on_return(t, method:)
    method_info = method_info(method)
    obj = t.return_value
    method_info.add_return_type(type(obj))
  end

  def method_info(method)
    key = method_name_with_owner(method)

    AutoTypeDoc.methods[key] ||= MethodInfo.new(
      source_location: method.source_location
    )

    AutoTypeDoc.methods[key]
  end

  def methods
    @methods ||= {}
  end

  def enable
    Tracker.enable
  end

  def disable
    Tracker.disable
  end

  def dump_json
    File.open(JSON_FILE, 'w') do |f|
      f.write(JSON.pretty_generate(methods))
    end
  end
end

AutoTypeDoc.enable
class Dog
end

class Fish
end

module M
  def bite(animal)
  end
end

module CM
  def eat(food)
  end

  def self.info(*args)
    "CHELLO THERE"
  end
end

class Cat
  class << self
    def chabis=(some_value)
      some_value = some_value.to_a
      @chabis = some_value
    end
  end

  def self.foobar(num)
    num + 4
  end

  include M
  extend CM
end

Cat.chabis = Set.new
Cat.new.bite(Dog.new)
Cat.foobar 2
Cat.foobar 8.9
Cat.foobar 123.34

Cat.eat(Fish.new)

CM.info(1, 2)

AutoTypeDoc.disable
AutoTypeDoc.dump_json
