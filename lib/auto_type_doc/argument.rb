module AutoTypeDoc
  class Argument
    include TypeStats

    attr_reader :name, :types, :kind, :position

    def initialize(name:, kind:, position:)
      @name = name.to_s
      @kind = kind.to_s
      @types = Hash.new(0)
      @position = position
    end

    def doc_string
      "# @param #{name} [#{most_frequent_type}]"
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
end
