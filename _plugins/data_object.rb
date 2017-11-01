require 'date'

class DataObject
  attr_reader :data, :definition, :storage

  def initialize(data, definition, storage)
    @data = data
    @definition = definition
    @storage = storage
  end
  
  def rich_data
    rd = {}
    definition.each do |key, details|
      rd[key] = self.send(key)
    end
    rd
  end
  

  def match?(key, values)
    key = key.to_s
    values = values.map(&:to_s)

    if definition.has_key?(key) && definition[key].has_key?('type') && definition[key]['type'] == 'model'
      storage.send "find_#{definition[key]['model_name']}_by_#{definition[key]['foreign_key'] || 'id'}", values
    else
      values.include? data[key].to_s
    end
  end

  def method_missing(name, *arguments, &block)
    if data[name.to_s].nil?
      return nil
    else
      name = name.to_s
      value = if definition.has_key?(name) && definition[name].has_key?('type') && definition[name]['type'] == 'model'
        storage.send "find_#{definition[name]['model_name']}_by_#{definition[name]['foreign_key'] || 'id'}", data[name]
      elsif definition.has_key?(name) && definition[name].has_key?('type') && definition[name]['type'] == 'date'
        Date.parse data[name]
      elsif definition.has_key?(name) && definition[name].has_key?('type') && definition[name]['type'] == 'datetime'
        DateTime.parse data[name]
      else
        data[name]
      end

      definition.has_key?(name) && definition[name].has_key?('localizable') && definition[name]['localizable'] ?
        value[storage.locale] || value[storage.default_locale] : value
    end
  end

  def respond_to_missing?(name, include_private = false)
    !data[name.to_s].nil? || super
  end

  def to_liquid
    self
  end

  def [](property)
    send(property)
  end

  def has_key?(property)
    data.has_key?(property)
  end

end
