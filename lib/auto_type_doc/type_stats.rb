module AutoTypeDoc
  module TypeStats
    def most_frequent_type(type_hash = types)
      type_hash.max_by { |_, count| count }[0]
    end
  end
end
