# app/services/json_store.rb
require 'json'
require 'fileutils'

class JsonStore
  def initialize(filename)
    @file_path = Rails.root.join('db', "#{filename}.json")
    ensure_file_exists
  end

  def all
    JSON.parse(File.read(@file_path))
  rescue JSON::ParserError
    []
  end

  def find(id)
    all.find { |item| item['id'] == id.to_s }
  end

  def create(data)
    items = all
    data['id'] = next_id(items).to_s
    data['created_at'] = Time.current.to_s
    data['updated_at'] = Time.current.to_s
    items << data
    save(items)
    data
  end

  def update(id, data)
    items = all
    item = items.find { |i| i['id'] == id.to_s }
    return nil unless item
    
    item.merge!(data)
    item['updated_at'] = Time.current.to_s
    save(items)
    item
  end

  def delete(id)
    items = all
    items.reject! { |item| item['id'] == id.to_s }
    save(items)
    true
  end

  private

  def ensure_file_exists
    FileUtils.mkdir_p(File.dirname(@file_path))
    File.write(@file_path, '[]') unless File.exist?(@file_path)
  end

  def next_id(items)
    return 1 if items.empty?
    items.map { |item| item['id'].to_i }.max + 1
  end

  def save(data)
    File.write(@file_path, JSON.pretty_generate(data))
  end
end