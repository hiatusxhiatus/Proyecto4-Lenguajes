# app/models/invoice.rb
class Invoice
  include ActiveModel::Model
  include ActiveModel::Attributes
  
  attribute :id, :string
  attribute :invoice_number, :string
  attribute :client_name, :string
  attribute :client_email, :string
  attribute :created_at, :string
  attribute :updated_at, :string

  validates :client_name, presence: true, length: { minimum: 2 }
  validates :client_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  def initialize(params = {})
    super
    @id = params['id']
    @invoice_number = params['invoice_number']
    @client_name = params['client_name']
    @client_email = params['client_email']
    @items = params['items'] || []
    @created_at = params['created_at']
    @updated_at = params['updated_at']
  end

  def items
    @items ||= []
  end

  def items=(value)
    @items = value || []
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
    @store ||= JsonStore.new('invoices')
  end

  def self.all
    store.all.map { |data| new(data) }
  end

  def self.find(id)
    data = store.find(id)
    data ? new(data) : nil
  end

  def self.create(params)
    invoice = new(params)
    invoice.save ? invoice : nil
  end

  # Métodos de instancia
  def save
    return false unless valid?
    
    self.invoice_number ||= generate_invoice_number
    
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

  def add_item(product_id, quantity, tax_rate_id)
    product = Product.find(product_id)
    tax_rate = TaxRate.find(tax_rate_id)
    
    return false unless product && tax_rate

    item = {
      'product_id' => product_id,
      'product_name' => product.name,
      'quantity' => quantity.to_i,
      'unit_price' => product.price,
      'tax_rate_id' => tax_rate_id,
      'tax_rate_name' => tax_rate.name,
      'tax_percentage' => tax_rate.percentage
    }

    self.items << item
    true
  end

  def remove_item(index)
    items.delete_at(index) if index >= 0 && index < items.length
  end

  def subtotal
    items.sum { |item| item['quantity'] * item['unit_price'] }
  end

  def tax_total
    items.sum do |item|
      line_subtotal = item['quantity'] * item['unit_price']
      line_subtotal * item['tax_percentage'] / 100
    end
  end

  def total
    subtotal + tax_total
  end

  def process_stock
    items.each do |item|
      product = Product.find(item['product_id'])
      product.update_stock(item['quantity'], :subtract) if product
    end
  end

  private

  def store
    self.class.store
  end

  def generate_invoice_number
    last_invoice = self.class.all.max_by { |inv| inv.invoice_number.to_i }
    last_number = last_invoice ? last_invoice.invoice_number.to_i : 0
    (last_number + 1).to_s.rjust(6, '0')
  end

  def to_hash
    {
      'invoice_number' => invoice_number,
      'client_name' => client_name,
      'client_email' => client_email,
      'items' => items
    }
  end

  def update_attributes_from_data(data)
    @id = data['id']
    @invoice_number = data['invoice_number']
    @client_name = data['client_name']
    @client_email = data['client_email']
    @items = data['items'] || []
    @created_at = data['created_at']
    @updated_at = data['updated_at']
    true
  end
end