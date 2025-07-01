# db/seeds.rb
puts "🌱 Creando datos iniciales..."

# Limpiar datos existentes
puts "Limpiando datos existentes..."
Product.store.instance_variable_set(:@file_path, Rails.root.join('db', 'products.json'))
TaxRate.store.instance_variable_set(:@file_path, Rails.root.join('db', 'tax_rates.json'))
Invoice.store.instance_variable_set(:@file_path, Rails.root.join('db', 'invoices.json'))

File.write(Rails.root.join('db', 'products.json'), '[]')
File.write(Rails.root.join('db', 'tax_rates.json'), '[]')
File.write(Rails.root.join('db', 'invoices.json'), '[]')

puts "📊 Creando tasas de impuesto..."

iva = TaxRate.new(name: "IVA", percentage: 13.0)
if iva.save
  puts "✅ Creada tasa: #{iva.name} (#{iva.percentage}%)"
else
  puts "❌ Error creando IVA: #{iva.errors.full_messages}"
end

exento = TaxRate.new(name: "Exento", percentage: 0.0)
if exento.save
  puts "✅ Creada tasa: #{exento.name} (#{exento.percentage}%)"
else
  puts "❌ Error creando Exento: #{exento.errors.full_messages}"
end

servicios = TaxRate.new(name: "Servicios", percentage: 4.0)
if servicios.save
  puts "✅ Creada tasa: #{servicios.name} (#{servicios.percentage}%)"
else
  puts "❌ Error creando Servicios: #{servicios.errors.full_messages}"
end

puts "🛍️ Creando productos de ejemplo..."

productos = [
  { name: "Laptop Dell Inspiron", price: 450000.0, stock: 10 },
  { name: "Mouse Inalámbrico Logitech", price: 15000.0, stock: 3 },
  { name: "Teclado Mecánico RGB", price: 75000.0, stock: 8 },
  { name: "Monitor 24 pulgadas", price: 180000.0, stock: 15 },
  { name: "Auriculares Bluetooth", price: 25000.0, stock: 2 }
]

productos.each do |producto_data|
  producto = Product.new(producto_data)
  if producto.save
    status = producto.low_stock? ? "⚠️ Stock bajo" : "✅"
    puts "#{status} Creado producto: #{producto.name} - Stock: #{producto.stock}"
  else
    puts "❌ Error creando producto #{producto_data[:name]}: #{producto.errors.full_messages}"
  end
end

puts "\n🎉 Datos iniciales creados exitosamente!"
puts "📈 Resumen:"
puts "   - #{TaxRate.all.count} tasas de impuesto"
puts "   - #{Product.all.count} productos"
puts "   - #{Product.all.select(&:low_stock?).count} productos con stock bajo"
puts "\n🚀 ¡La aplicación está lista para usar!"