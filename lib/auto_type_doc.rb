require "auto_type_doc/version"
require "auto_type_doc/type_stats"
require "auto_type_doc/argument"
require "auto_type_doc/method_info"

require 'irb'
require 'pry'
require 'json'
require 'set'
require 'fileutils'

module AutoTypeDoc
  module_function

  METHOD_BLACK_LIST = %r{
    AutoTypeDoc
  }x

  LOCATION_BLACK_LIST = %r{
    rubies/
    |/gems/
    |/spec/
    |/test/
  }x

  Tracker = TracePoint.new(:call, :return) do |t|
    begin
      method = t.self.method(t.method_id)
    rescue
      next
    end

    source_location = method.source_location
    next if source_location.nil?

    source_path = source_location[0]
    next if source_path =~ LOCATION_BLACK_LIST
    next if method.to_s =~ METHOD_BLACK_LIST
    next if method_name_with_owner(method).start_with?("#<")

    case t.event
    when :call
      next if method.parameters.empty?
      on_call(t, method: method)
    when :return
      on_return(t, method: method)
    end
  end

  # @param method [Method]
  # @return [String]
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

  def on_return(t, method:)
    method_info = method_info(method)
    obj = t.return_value
    method_info.add_return_type(type(obj))
  end

  # @param obj [Object]
  # @return [String]
  def type(obj)
    if obj.is_a?(Array) && obj.any?
      return "#{obj.class}<#{type(obj.first)}>"
    end

    if obj.equal?(true) || obj.equal?(false)
      return "Boolean"
    end

    obj.class
  end

  # @param method [Method]
  # @return [MethodInfo]
  def method_info(method)
    key = method_name_with_owner(method)

    AutoTypeDoc.all_method_info[key] ||= MethodInfo.new(
      id: key,
      source_location: method.source_location
    )

    AutoTypeDoc.all_method_info[key]
  end

  def all_method_info
    @all_method_info ||= {}
  end

  def enable
    Tracker.enable
  end

  def disable
    Tracker.disable
  end

  def doc_dir
    './type_doc'
  end

  def dump_json
    FileUtils.mkdir_p(doc_dir)

    File.open("#{doc_dir}/types.json", 'w') do |f|
      f.write(JSON.pretty_generate(all_method_info))
    end
  end
end
