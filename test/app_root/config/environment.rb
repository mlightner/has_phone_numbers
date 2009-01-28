begin
  require 'config/boot'
  require "#{File.dirname(__FILE__)}/../../../../plugins_plus/boot"
rescue Exception => e
  raise "The plugins_plus plugin must be installed in your app to run tests."
end

Rails::Initializer.run do |config|
  config.plugin_paths << '..'
  config.plugins = %w(plugins_plus has_phone_numbers)
  config.cache_classes = false
  config.whiny_nils = true
end
