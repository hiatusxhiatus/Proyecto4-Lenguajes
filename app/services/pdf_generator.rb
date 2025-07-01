# app/services/pdf_generator.rb
require 'prawn'
require 'prawn/table'

class PdfGenerator
  def initialize(invoice)
    @invoice = invoice
  end

  def generate
    Prawn::Document.new(page_size: 'LETTER', margin: 40) do |pdf|
      pdf.font_size 10
      
      # Header con información de la empresa
      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width) do
        pdf.font_size 18
        pdf.text "FACTURA", style: :bold, align: :center
        pdf.move_down 5
        pdf.font_size 14
        pdf.text "Numero: #{@invoice.invoice_number}", style: :bold, align: :center
        pdf.move_down 20
      end
      
      # Información del cliente y fecha
      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width/2) do
        pdf.font_size 11
        pdf.text "INFORMACION DEL CLIENTE", style: :bold
        pdf.move_down 5
        pdf.text "Cliente: #{@invoice.client_name}"
        pdf.text "Email: #{@invoice.client_email}" if @invoice.client_email.present?
      end
      
      pdf.bounding_box([pdf.bounds.width/2, pdf.cursor + 40], width: pdf.bounds.width/2) do
        pdf.font_size 11
        pdf.text "INFORMACION DE FACTURA", style: :bold, align: :right
        pdf.move_down 5
        pdf.text "Fecha: #{format_date(@invoice.created_at)}", align: :right
        pdf.text "Numero: #{@invoice.invoice_number}", align: :right
      end
      
      pdf.move_down 30
      
      # Tabla de productos
      if @invoice.items.any?
        # Preparar datos de la tabla
        table_data = [
          ['Producto', 'Cant.', 'Precio Unit.', 'Subtotal', 'Impuesto (%)', 'Impuesto (C)', 'Total']
        ]
        
        @invoice.items.each do |item|
          next unless item.is_a?(Hash)
          
          line_subtotal = item['quantity'].to_i * item['unit_price'].to_f
          line_tax = line_subtotal * item['tax_percentage'].to_f / 100
          line_total = line_subtotal + line_tax
          
          table_data << [
            item['product_name'].to_s,
            item['quantity'].to_s,
            format_currency_simple(item['unit_price'].to_f),
            format_currency_simple(line_subtotal),
            "#{item['tax_percentage']}%",
            format_currency_simple(line_tax),
            format_currency_simple(line_total)
          ]
        end
        
        # Crear la tabla con estilos
        pdf.table(table_data, 
          header: true, 
          width: pdf.bounds.width,
          cell_style: { 
            size: 9, 
            padding: [4, 8],
            border_width: 0.5,
            border_color: "CCCCCC"
          }
        ) do
          # Estilo del header
          row(0).font_style = :bold
          row(0).background_color = "F0F0F0"
          
          # Alineación de columnas numéricas
          columns(1..6).align = :right
          
          # Hacer la tabla más legible
          self.row_colors = ["FFFFFF", "F8F9FA"]
        end
        
        pdf.move_down 20
        
        # Resumen de totales en una caja
        pdf.bounding_box([pdf.bounds.width - 200, pdf.cursor], width: 200) do
          pdf.stroke_bounds
          pdf.fill_color "F8F9FA"
          pdf.fill_rectangle [0, pdf.bounds.height], pdf.bounds.width, pdf.bounds.height
          pdf.fill_color "000000"
          
          pdf.pad(10) do
            pdf.font_size 10
            
            # Subtotal
            pdf.text_box "Subtotal:", 
              at: [5, pdf.cursor], 
              width: 100
            pdf.text_box format_currency_simple(@invoice.subtotal), 
              at: [105, pdf.cursor], 
              width: 80, 
              align: :right
            pdf.move_down 15
            
            # Total de impuestos
            pdf.text_box "Total Impuestos:", 
              at: [5, pdf.cursor], 
              width: 100
            pdf.text_box format_currency_simple(@invoice.tax_total), 
              at: [105, pdf.cursor], 
              width: 80, 
              align: :right
            pdf.move_down 15
            
            # Línea separadora
            pdf.stroke_horizontal_line 5, pdf.bounds.width - 5, at: pdf.cursor + 5
            pdf.move_down 10
            
            # Total final
            pdf.font_size 12
            pdf.text_box "TOTAL:", 
              at: [5, pdf.cursor], 
              width: 100, 
              style: :bold
            pdf.text_box format_currency_simple(@invoice.total), 
              at: [105, pdf.cursor], 
              width: 80, 
              align: :right, 
              style: :bold
          end
        end
        
      else
        pdf.text "No hay productos en esta factura", align: :center, style: :italic
      end
      
      # Footer
      pdf.move_down 40
      pdf.font_size 8
      pdf.text "Generado el #{Time.current.strftime('%d/%m/%Y a las %H:%M')}", align: :center, color: "666666"
      
      # Información adicional de la empresa (opcional)
      pdf.move_down 20
      pdf.text "Sistema de Facturacion", align: :center, style: :bold
      
    end.render
  end

  private

  def format_currency_simple(amount)
    "CRC#{sprintf('%.2f', amount || 0)}"
  end

  def format_date(date_string)
    return Date.current.strftime('%d/%m/%Y') unless date_string
    Date.parse(date_string).strftime('%d/%m/%Y')
  rescue
    Date.current.strftime('%d/%m/%Y')
  end
end