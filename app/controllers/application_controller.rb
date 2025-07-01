# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  # Método helper para manejar errores 404
  def handle_record_not_found(entity_name = "Registro")
    redirect_to root_path, alert: "#{entity_name} no encontrado"
  end
  
  # Método helper para formatear moneda
  def format_currency(amount)
    "₡#{sprintf('%.2f', amount || 0)}"
  end
  
  # Método helper para formatear fechas
  def format_date(date_string)
    return 'N/A' unless date_string
    Date.parse(date_string).strftime('%d/%m/%Y')
  rescue
    'N/A'
  end
  
  helper_method :format_currency, :format_date
end