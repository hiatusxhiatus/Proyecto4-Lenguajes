# app/models/product.rb
class Product
  include ActiveModel::Model
  include ActiveModel::Attributes
  
  attribute :id, :string
  attribute :name, :string
  attribute :price, :float
  attribute :stock, :integer
  attribute :created_at, :string
  attribute :updated_at, :string

  validates :name, presence: true, length: { minimum: 2 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :stock, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def initialize(params = {})
    super
    @id = params['id']
    @name = params['name']
    @price = params['price'].to_f if params['price']
    @stock = params['stock'].to_i if params['stock']
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

  # Métodos de clase (como "static" en otros lenguajes)
  def self.store
    @store ||= JsonStore.new('products')
  end

  def self.all
    store.all.map { |data| new(data) }
  end

  def self.find(id)
    data = store.find(id)
    data ? new(data) : nil
  end

  def self.create(params)
    product = new(params)
    product.save ? product : nil
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

  def low_stock?
    stock < 5
  end

  def update_stock(quantity, operation = :add)
    if operation == :add
      self.stock += quantity
    else
      self.stock -= quantity
    end
    self.stock = 0 if stock < 0
    save
  end

  private

  def store
    self.class.store
  end

  def to_hash
    {
      'name' => name,
      'price' => price,
      'stock' => stock
    }
  end

  def update_attributes_from_data(data)
    @id = data['id']
    @name = data['name']
    @price = data['price'].to_f
    @stock = data['stock'].to_i
    @created_at = data['created_at']
    @updated_at = data['updated_at']
    true
  end
end