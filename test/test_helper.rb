# Load the plugin testing framework
begin
  $:.unshift("#{File.dirname(__FILE__)}/../../plugin_test_helper/lib")
  require 'plugin_test_helper'

rescue Exception => e
  # Try loading from the gem if we cann't find the plugin.
  if !Object.const_defined?("PluginTestHelper")
    require 'rubygems'
    require 'plugin_test_helper'
    raise e unless Object.const_defined?("PluginTestHelper")
  end
  
end

# Run the migrations
ActiveRecord::Migrator.migrate("#{RAILS_ROOT}/db/migrate")

# Mixin the factory helper
require File.expand_path("#{File.dirname(__FILE__)}/factory")
Test::Unit::TestCase.class_eval do
  include Factory
end
