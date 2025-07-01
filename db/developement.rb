# config/environments/development.rb - Solo agregar estas líneas al archivo existente

# Líneas a agregar al final del archivo:
config.file_watcher = ActiveSupport::EventedFileUpdateChecker
config.hosts.clear if Rails.env.development?