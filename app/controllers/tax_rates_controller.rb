# app/controllers/tax_rates_controller.rb
class TaxRatesController < ApplicationController
  before_action :find_tax_rate, only: [:show, :edit, :update, :destroy]

  def index
    @tax_rates = TaxRate.all
  end

  def show
    # @tax_rate ya está cargado por before_action
  end

  def new
    @tax_rate = TaxRate.new
  end

  def create
    @tax_rate = TaxRate.new(tax_rate_params)
    
    if @tax_rate.save
      redirect_to tax_rates_path, notice: 'Tasa de impuesto creada exitosamente'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @tax_rate ya está cargado por before_action
  end

  def update
    if update_tax_rate_attributes && @tax_rate.save
      redirect_to tax_rates_path, notice: 'Tasa de impuesto actualizada exitosamente'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @tax_rate.destroy
    redirect_to tax_rates_path, notice: 'Tasa de impuesto eliminada exitosamente'
  end

  private

  def find_tax_rate
    @tax_rate = TaxRate.find(params[:id])
    unless @tax_rate
      handle_record_not_found("Tasa de impuesto")
    end
  end

  def tax_rate_params
    params.require(:tax_rate).permit(:name, :percentage)
  end
  
  def update_tax_rate_attributes
    @tax_rate.name = tax_rate_params[:name]
    @tax_rate.percentage = tax_rate_params[:percentage].to_f
    @tax_rate.valid?
  end
end