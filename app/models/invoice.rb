# app/models/invoice.rb
class Invoice
  include ActiveModel::Model
  include ActiveModel::Attributes
  
  attribute :id, :string
  attribute :invoice_number, :string
  attribute :client_name, :string
  attribute :client_email, :string
  attribute :status, :string, default: 'draft'
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
    @status = params['status'] || 'draft'
    @items = params['items'] || []
    @created_at = params['created_at']
    @updated_at = params['updated_at']
  end

  def items
    @items ||= []
    # Asegurar que siempre sea un array
    @items = [] unless @items.is_a?(Array)
    @items
  end

  def items=(value)
    @items = value.is_a?(Array) ? value : []
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
    
    if persisted?
      # Si ya existe, solo actualizar
      data = store.update(id, to_hash)
      data ? update_attributes_from_data(data) : false
    else
      # Si es nuevo, generar número de factura y crear
      self.invoice_number = generate_invoice_number
      data = store.create(to_hash)
      update_attributes_from_data(data)
    end
  end

  def destroy
    store.delete(id) if persisted?
  end

  def add_item(product_id, quantity, tax_rate_id)
    product = Product.find(product_id.to_s)
    tax_rate = TaxRate.find(tax_rate_id.to_s)
    
    return false unless product && tax_rate

    # Asegurar que items es un array
    self.items = [] if self.items.nil?
    
    # Verificar si ya existe este producto con la misma tasa en la factura
    existing_item = self.items.find do |item| 
      item.is_a?(Hash) && 
      item['product_id'] == product_id.to_s && 
      item['tax_rate_id'] == tax_rate_id.to_s 
    end
    
    if existing_item
      # Si existe, aumentar la cantidad
      existing_item['quantity'] = existing_item['quantity'].to_i + quantity.to_i
    else
      # Si no existe, crear nuevo item
      item = {
        'product_id' => product_id.to_s,
        'product_name' => product.name,
        'quantity' => quantity.to_i,
        'unit_price' => product.price,
        'tax_rate_id' => tax_rate_id.to_s,
        'tax_rate_name' => tax_rate.name,
        'tax_percentage' => tax_rate.percentage
      }
      self.items << item
    end
    
    true
  end

  def remove_item(index)
    items.delete_at(index) if index >= 0 && index < items.length
  end

  # Cálculos financieros
  def subtotal
    items.sum do |item| 
      next 0 unless item.is_a?(Hash)
      (item['quantity'].to_i * item['unit_price'].to_f)
    end
  end

  def tax_total
    items.sum do |item|
      next 0 unless item.is_a?(Hash)
      line_subtotal = item['quantity'].to_i * item['unit_price'].to_f
      line_subtotal * item['tax_percentage'].to_f / 100
    end
  end

  def total
    subtotal + tax_total
  end

  def total_items_count
    items.sum do |item| 
      next 0 unless item.is_a?(Hash)
      item['quantity'].to_i
    end
  end

  # Métodos de estado
  def draft?
    status == 'draft'
  end

  def finalized?
    status == 'finalized'
  end

  def can_be_edited?
    draft?
  end

  def can_be_finalized?
    draft? && items.any?
  end

  # Procesar stock al finalizar factura
  def process_stock
    return false unless can_be_finalized?
    
    # Verificar stock disponible antes de procesar
    stock_issues = []
    items.each do |item|
      next unless item.is_a?(Hash)
      
      product = Product.find(item['product_id'])
      if product && product.stock < item['quantity'].to_i
        stock_issues << "#{item['product_name']} (disponible: #{product.stock}, requerido: #{item['quantity']})"
      end
    end
    
    if stock_issues.any?
      return { success: false, errors: stock_issues }
    end
    
    # Si todo está bien, procesar el stock
    items.each do |item|
      next unless item.is_a?(Hash)
      
      product = Product.find(item['product_id'])
      product.update_stock(item['quantity'].to_i, :subtract) if product
    end
    
    # Cambiar estado a finalizada
    self.status = 'finalized'
    save
    
    { success: true, errors: [] }
  end

  # Agrupación de impuestos para resumen
  def tax_summary
    tax_groups = {}
    
    items.each do |item|
      next unless item.is_a?(Hash)
      
      tax_key = "#{item['tax_rate_name']}_#{item['tax_percentage']}"
      line_subtotal = item['quantity'].to_i * item['unit_price'].to_f
      line_tax = line_subtotal * item['tax_percentage'].to_f / 100
      
      if tax_groups[tax_key]
        tax_groups[tax_key][:base_amount] += line_subtotal
        tax_groups[tax_key][:tax_amount] += line_tax
      else
        tax_groups[tax_key] = {
          name: item['tax_rate_name'],
          percentage: item['tax_percentage'].to_f,
          base_amount: line_subtotal,
          tax_amount: line_tax
        }
      end
    end
    
    tax_groups.values
  end

  private

  def store
    self.class.store
  end

  def generate_invoice_number
    # Obtener todas las facturas existentes
    all_invoices = self.class.all
    
    # Encontrar el número más alto
    if all_invoices.empty?
      last_number = 0
    else
      existing_numbers = all_invoices.map { |inv| inv.invoice_number.to_i }.compact
      last_number = existing_numbers.max || 0
    end
    
    # Generar el siguiente número único
    next_number = last_number + 1
    candidate_number = next_number.to_s.rjust(6, '0')
    
    # Verificar que no exista (por si acaso)
    while all_invoices.any? { |inv| inv.invoice_number == candidate_number }
      next_number += 1
      candidate_number = next_number.to_s.rjust(6, '0')
    end
    
    candidate_number
  end

  def to_hash
    {
      'invoice_number' => invoice_number,
      'client_name' => client_name,
      'client_email' => client_email,
      'status' => status,
      'items' => items
    }
  end

  def update_attributes_from_data(data)
    @id = data['id']
    @invoice_number = data['invoice_number']
    @client_name = data['client_name']
    @client_email = data['client_email']
    @status = data['status'] || 'draft'
    @items = data['items'] || []
    @created_at = data['created_at']
    @updated_at = data['updated_at']
    true
  end
end