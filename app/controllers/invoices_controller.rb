# app/controllers/invoices_controller.rb
class InvoicesController < ApplicationController
  before_action :find_invoice, only: [:show, :edit, :update, :destroy, :add_item, :remove_item, :finalize, :download_pdf]
  before_action :load_form_data, only: [:new, :edit, :create, :update]

  def index
    @invoices = Invoice.all
  end

  def show
    # @invoice ya está cargado por before_action
  end

  def new
    @invoice = Invoice.new
  end

  def create
    @invoice = Invoice.new(invoice_params)
    
    if @invoice.save
      # Agregar los items si existen
      if params[:invoice][:items]
        params[:invoice][:items].each do |item_params|
          @invoice.add_item(
            item_params[:product_id], 
            item_params[:quantity], 
            item_params[:tax_rate_id]
          )
        end
        @invoice.save
      end
      
      redirect_to @invoice, notice: 'Factura creada exitosamente'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @invoice ya está cargado por before_action
  end

  def update
    @invoice.client_name = invoice_params[:client_name]
    @invoice.client_email = invoice_params[:client_email]
    
    if @invoice.save
      redirect_to @invoice, notice: 'Factura actualizada exitosamente'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @invoice.destroy
    redirect_to invoices_path, notice: 'Factura eliminada exitosamente'
  end

  def add_item
    product_id = params[:product_id]
    quantity = params[:quantity].to_i
    tax_rate_id = params[:tax_rate_id]
    
    if product_id.present? && quantity > 0 && tax_rate_id.present?
      if @invoice.add_item(product_id, quantity, tax_rate_id)
        @invoice.save
        redirect_to edit_invoice_path(@invoice), notice: 'Producto agregado exitosamente'
      else
        redirect_to edit_invoice_path(@invoice), alert: 'Error al agregar producto. Verifica que el producto y tasa de impuesto existan.'
      end
    else
      redirect_to edit_invoice_path(@invoice), alert: 'Todos los campos son obligatorios'
    end
  end

  def remove_item
    index = params[:item_index].to_i
    @invoice.remove_item(index)
    @invoice.save
    redirect_to edit_invoice_path(@invoice), notice: 'Producto eliminado de la factura'
  end

  def finalize
    if @invoice.items.any?
      @invoice.process_stock
      redirect_to @invoice, notice: 'Factura finalizada exitosamente. Stock actualizado.'
    else
      redirect_to edit_invoice_path(@invoice), alert: 'No se puede finalizar una factura sin productos'
    end
  end

  def download_pdf
    if @invoice.items.any?
      pdf_content = PdfGenerator.new(@invoice).generate
      send_data pdf_content, 
                filename: "factura_#{@invoice.invoice_number}.pdf", 
                type: 'application/pdf',
                disposition: 'attachment'
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
    @products = Product.all
    @tax_rates = TaxRate.all
  end

  def invoice_params
    params.require(:invoice).permit(:client_name, :client_email)
  end
end