#!/usr/bin/env ruby

EXECUTABLE_FILE = File.realpath(__FILE__)
$LOAD_PATH.unshift File.expand_path('../lib', EXECUTABLE_FILE)
require 'auto_type_doc'

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

binding.pry
puts
