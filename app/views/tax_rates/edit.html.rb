<!-- app/views/tax_rates/edit.html.erb -->
<div class="page-header-widget">
  <div class="page-header-content">
    <h1 class="page-title">Editar Tasa de Impuesto</h1>
    <div class="page-header-actions">
      <%= link_to "Volver", tax_rates_path, class: "btn btn-secondary" %>
    </div>
  </div>
</div>

<div class="form-widget">
  <div class="card-widget">
    <div class="card-header">
      <h3 class="card-title">Modificar Tasa</h3>
    </div>
    <div class="card-body">
      <%= form_with model: @tax_rate, local: true, class: "form-component" do |form| %>
        <div class="form-fields">
          <div class="form-row">
            <div class="form-group">
              <%= form.label :name, "Nombre de la Tasa", class: "form-label" %>
              <%= form.text_field :name, class: "form-control", required: true %>
            </div>
            
            <div class="form-group">
              <%= form.label :percentage, "Porcentaje (%)", class: "form-label" %>
              <%= form.number_field :percentage, step: 0.01, min: 0, max: 100, class: "form-control", required: true %>
            </div>
          </div>
        </div>
        
        <div class="form-actions">
          <%= form.submit "Actualizar Tasa", class: "btn btn-primary" %>
          <%= link_to "Cancelar", tax_rates_path, class: "btn btn-secondary" %>
        </div>
      <% end %>
    </div>
  </div>
</div>