# app/services/pdf_generator.rb
require 'prawn'

class PdfGenerator
  def initialize(invoice)
    @invoice = invoice
  end

  def generate
    Prawn::Document.new do |pdf|
      pdf.font_size 12
      
      # Header
      pdf.text "FACTURA ##{@invoice.invoice_number}", size: 20, style: :bold, align: :center
      pdf.move_down 20
      
      # Client info
      pdf.text "Cliente: #{@invoice.client_name}", style: :bold
      pdf.text "Email: #{@invoice.client_email}" if @invoice.client_email.present?
      pdf.text "Fecha: #{format_date(@invoice.created_at)}"
      pdf.move_down 20
      
      # Items table
      if @invoice.items.any?
        table_data = [['Producto', 'Cantidad', 'Precio Unit.', 'Subtotal', 'Impuesto', 'Total']]
        
        @invoice.items.each do |item|
          line_subtotal = item['quantity'] * item['unit_price']
          line_tax = line_subtotal * item['tax_percentage'] / 100
          line_total = line_subtotal + line_tax
          
          table_data << [
            item['product_name'],
            item['quantity'].to_s,
            format_currency(item['unit_price']),
            format_currency(line_subtotal),
            "#{format_currency(line_tax)} (#{item['tax_percentage']}%)",
            format_currency(line_total)
          ]
        end
        
        pdf.table(table_data, header: true, width: pdf.bounds.width) do
          row(0).font_style = :bold
          columns(2..5).align = :right
        end
        
        pdf.move_down 20
        
        # Totals
        pdf.text "Subtotal: #{format_currency(@invoice.subtotal)}", align: :right
        pdf.text "Total Impuestos: #{format_currency(@invoice.tax_total)}", align: :right
        pdf.text "TOTAL: #{format_currency(@invoice.total)}", align: :right, style: :bold, size: 14
      else
        pdf.text "No hay productos en esta factura", align: :center, style: :italic
      end
      
    end.render
  end

  private

  def format_currency(amount)
    "₡#{sprintf('%.2f', amount || 0)}"
  end

  def format_date(date_string)
    return Date.current.strftime('%d/%m/%Y') unless date_string
    Date.parse(date_string).strftime('%d/%m/%Y')
  rescue
    Date.current.strftime('%d/%m/%Y')
  end
end