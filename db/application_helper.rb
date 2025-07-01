# app/helpers/application_helper.rb
module ApplicationHelper
  def format_currency(amount)
    "₡#{sprintf('%.2f', amount || 0)}"
  end
  
  def format_date(date_string)
    return 'N/A' unless date_string
    Date.parse(date_string).strftime('%d/%m/%Y')
  rescue
    'N/A'
  end
  
  def stock_status_badge(product)
    if product.low_stock?
      content_tag :span, 'Stock Bajo', class: 'badge bg-warning'
    else
      content_tag :span, 'OK', class: 'badge bg-success'
    end
  end
end