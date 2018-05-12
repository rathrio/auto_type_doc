module AutoTypeDoc
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
end