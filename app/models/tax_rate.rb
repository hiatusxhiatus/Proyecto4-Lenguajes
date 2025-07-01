# app/models/tax_rate.rb
class TaxRate
  include ActiveModel::Model
  include ActiveModel::Attributes
  
  attribute :id, :string
  attribute :name, :string
  attribute :percentage, :float
  attribute :created_at, :string
  attribute :updated_at, :string

  validates :name, presence: true, length: { minimum: 2 }
  validates :percentage, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  def initialize(params = {})
    super
    @id = params['id']
    @name = params['name']
    @percentage = params['percentage'].to_f if params['percentage']
    @created_at = params['created_at']
    @updated_at = params['updated_at']
  end

  # Métodos necesarios para Rails forms
  def to_model
    self
  end

  def to_key
    id ? [id] : nil
  end

  def to_param
    id
  end

  def persisted?
    id.present?
  end

  def model_name
    ActiveModel::Name.new(self.class)
  end

  # Métodos de clase
  def self.store
    @store ||= JsonStore.new('tax_rates')
  end

  def self.all
    store.all.map { |data| new(data) }
  end

  def self.find(id)
    data = store.find(id)
    data ? new(data) : nil
  end

  def self.create(params)
    tax_rate = new(params)
    tax_rate.save ? tax_rate : nil
  end

  # Métodos de instancia
  def save
    return false unless valid?
    
    if persisted?
      data = store.update(id, to_hash)
      data ? update_attributes_from_data(data) : false
    else
      data = store.create(to_hash)
      update_attributes_from_data(data)
    end
  end

  def destroy
    store.delete(id) if persisted?
  end

  def calculate_tax(amount)
    (amount * percentage / 100).round(2)
  end

  private

  def store
    self.class.store
  end

  def to_hash
    {
      'name' => name,
      'percentage' => percentage
    }
  end

  def update_attributes_from_data(data)
    @id = data['id']
    @name = data['name']
    @percentage = data['percentage'].to_f
    @created_at = data['created_at']
    @updated_at = data['updated_at']
    true
  end
end