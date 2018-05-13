module AutoTypeDoc
  class MethodInfo
    include TypeStats

    attr_reader :id, :arguments, :return_types, :source_location

    def initialize(id:, source_location:)
      @id = id.to_s
      @source_location = source_location.to_s
      @arguments = Set.new
      @return_types = Hash.new(0)
    end

    def source_path
      source_location[0]
    end

    def source_line
      source_location[1]
    end

    def argument(name)
      arguments.find { |a| a.name == name.to_s }
    end

    def doc_string
      arguments_doc = arguments.map(&:doc_string).join("\n")
      return_doc = "# @return [#{most_frequent_return_type}]"
      "#{arguments_doc}\n#{return_doc}"
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
    def most_frequent_argument_type(arg_name)
      argument(arg_name).most_frequent_type
    end

    # @return [String]
    def most_frequent_return_type
      most_frequent_type(return_types)
    end

    def to_h
      h = {}
      h[:arguments] = arguments.map(&:to_h) if arguments.any?
      h.merge(
        return_types: return_types,
        source_location: {
          path: source_path,
          line: source_line
        }
      )
    end

    def to_json(*args)
      to_h.to_json(*args)
    end
  end
end
