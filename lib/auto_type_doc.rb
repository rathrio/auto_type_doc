require "auto_type_doc/version"
require "auto_type_doc/argument"
require "auto_type_doc/method_info"

require 'irb'
require 'pry'
require 'json'
require 'set'

module AutoTypeDoc
  JSON_FILE = './types.json'

  module_function

  Tracker = TracePoint.new(:call, :return) do |t|
    begin
      method = t.self.method(t.method_id)
    rescue
      next
    end

    next if method.to_s =~ /Set|Test|AutoTypeDoc|Minitest|RSpec|Gem|main|OptionParser|FileUtils|Mutex_m|Kernel/

    case t.event
    when :call
      next if method.parameters.empty?
      on_call(t, method: method)
    when :return
      on_return(t, method: method)
    end
  end

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
