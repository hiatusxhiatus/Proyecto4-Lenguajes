# app/controllers/products_controller.rb
class ProductsController < ApplicationController
  before_action :find_product, only: [:show, :edit, :update, :destroy, :update_stock]

  def index
    @products = Product.all
    @low_stock_products = @products.select(&:low_stock?)
  end

  def show
    # @product ya está cargado por before_action
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    
    if @product.save
      redirect_to products_path, notice: 'Producto creado exitosamente'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @product ya está cargado por before_action
  end

  def update    
    @product.name = product_params[:name]
    @product.price = product_params[:price].to_f
    @product.stock = product_params[:stock].to_i
    
    if @product.save
      redirect_to products_path, notice: 'Producto actualizado exitosamente'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: 'Producto eliminado exitosamente'
  end

  def update_stock
    quantity = params[:quantity].to_i
    operation = params[:operation] == 'add' ? :add : :subtract
    
    if quantity > 0
      @product.update_stock(quantity, operation)
      redirect_to @product, notice: 'Stock actualizado exitosamente'
    else
      redirect_to @product, alert: 'La cantidad debe ser mayor a 0'
    end
  end

  private

  def find_product
    @product = Product.find(params[:id])
    unless @product
      handle_record_not_found("Producto")
    end
  end

  def product_params
    params.require(:product).permit(:name, :price, :stock)
  end
end