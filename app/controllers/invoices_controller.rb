# app/controllers/invoices_controller.rb
class InvoicesController < ApplicationController
  before_action :find_invoice, only: [:show, :edit, :update, :destroy, :add_item, :remove_item, :finalize, :download_pdf]
  before_action :load_form_data, only: [:new, :edit, :create, :update]

  def index
    @invoices = Invoice.all.sort_by { |inv| inv.invoice_number.to_i }.reverse
  end

  def show
    # @invoice ya está cargado por before_action
  end

  def new
    @invoice = Invoice.new
  end

  def create
    @invoice = Invoice.new(invoice_params)
    
    # Agregar los items antes de guardar si existen
    if params[:invoice][:items].present?
      params[:invoice][:items].each do |index, item_params|
        # Validar que el producto existe y tiene stock suficiente
        product = Product.find(item_params[:product_id].to_s)
        if product && product.stock >= item_params[:quantity].to_i
          success = @invoice.add_item(
            item_params[:product_id].to_s, 
            item_params[:quantity].to_i, 
            item_params[:tax_rate_id].to_s
          )
          unless success
            @invoice.errors.add(:items, "Error al agregar producto #{item_params[:product_name]}")
            load_form_data
            render :new, status: :unprocessable_entity
            return
          end
        else
          @invoice.errors.add(:items, "Producto #{item_params[:product_name]} no tiene stock suficiente")
          load_form_data
          render :new, status: :unprocessable_entity
          return
        end
      end
    end
    
    # Guardar la factura una sola vez con todos los items
    if @invoice.save
      redirect_to @invoice, notice: 'Factura creada exitosamente'
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @invoice ya está cargado por before_action
    if @invoice.finalized?
      redirect_to @invoice, alert: 'No se puede editar una factura finalizada'
      return
    end
  end

  def update
    if @invoice.finalized?
      redirect_to @invoice, alert: 'No se puede modificar una factura finalizada'
      return
    end
    
    @invoice.client_name = invoice_params[:client_name]
    @invoice.client_email = invoice_params[:client_email]
    
    if @invoice.save
      redirect_to @invoice, notice: 'Factura actualizada exitosamente'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @invoice.finalized?
      redirect_to invoices_path, alert: 'No se puede eliminar una factura finalizada'
      return
    end
    
    @invoice.destroy
    redirect_to invoices_path, notice: 'Factura eliminada exitosamente'
  end

  def add_item
    if @invoice.finalized?
      redirect_to @invoice, alert: 'No se pueden agregar productos a una factura finalizada'
      return
    end
    
    product_id = params[:product_id]
    quantity = params[:quantity].to_i
    tax_rate_id = params[:tax_rate_id]
    
    if product_id.present? && quantity > 0 && tax_rate_id.present?
      # Verificar stock disponible
      product = Product.find(product_id)
      if product && product.stock >= quantity
        if @invoice.add_item(product_id, quantity, tax_rate_id)
          @invoice.save
          redirect_to edit_invoice_path(@invoice), notice: 'Producto agregado exitosamente'
        else
          redirect_to edit_invoice_path(@invoice), alert: 'Error al agregar producto. Verifica que el producto y tasa de impuesto existan.'
        end
      else
        redirect_to edit_invoice_path(@invoice), alert: 'Stock insuficiente para este producto'
      end
    else
      redirect_to edit_invoice_path(@invoice), alert: 'Todos los campos son obligatorios'
    end
  end

  def remove_item
    if @invoice.finalized?
      redirect_to @invoice, alert: 'No se pueden remover productos de una factura finalizada'
      return
    end
    
    index = params[:item_index].to_i
    @invoice.remove_item(index)
    @invoice.save
    redirect_to edit_invoice_path(@invoice), notice: 'Producto eliminado de la factura'
  end

  def finalize
    if @invoice.items.any?
      # Verificar stock antes de finalizar
      stock_errors = []
      @invoice.items.each do |item|
        product = Product.find(item['product_id'])
        if product.stock < item['quantity']
          stock_errors << "#{item['product_name']} (disponible: #{product.stock}, requerido: #{item['quantity']})"
        end
      end
      
      if stock_errors.any?
        redirect_to edit_invoice_path(@invoice), alert: "Stock insuficiente para: #{stock_errors.join(', ')}"
      else
        @invoice.process_stock
        redirect_to @invoice, notice: 'Factura finalizada exitosamente. Stock actualizado.'
      end
    else
      redirect_to edit_invoice_path(@invoice), alert: 'No se puede finalizar una factura sin productos'
    end
  end

  def download_pdf
    if @invoice.items.any?
      begin
        pdf_content = PdfGenerator.new(@invoice).generate
        send_data pdf_content, 
                  filename: "factura_#{@invoice.invoice_number}.pdf", 
                  type: 'application/pdf',
                  disposition: 'attachment'
      rescue => e
        Rails.logger.error "Error generando PDF: #{e.message}"
        redirect_to @invoice, alert: 'Error al generar el PDF. Intenta nuevamente.'
      end
    else
      redirect_to @invoice, alert: 'No se puede generar PDF de una factura sin productos'
    end
  end

  private

  def find_invoice
    @invoice = Invoice.find(params[:id])
    unless @invoice
      handle_record_not_found("Factura")
    end
  end

  def load_form_data
    @products = Product.all.select { |p| p.stock > 0 } # Solo productos con stock
    @tax_rates = TaxRate.all
  end

  def invoice_params
    params.require(:invoice).permit(:client_name, :client_email, items: {})
  end
end