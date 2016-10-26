# frozen_string_literal: true

require 'pathname'

Gem::Specification.new do |spec|
  spec.name     = 'ibm_db'
  spec.version  = '3.0.4'
  spec.summary  = 'Rails Driver and Adapter for IBM Data Servers'

  spec.author = 'IBM'
  spec.email = 'opendev@us.ibm.com'
  spec.homepage = 'https://github.com/ibmdb/ruby-ibmdb'

  spec.required_ruby_version = '>= 2.0.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'pry'
  candidates = Dir.glob('**/*')
  spec.files = candidates.delete_if do |item|
    item.include?('CVS') ||
      item.include?('rdoc') ||
      item.include?('install.rb') ||
      item.include?('uninstall.rb') ||
      item.include?('Rakefile') ||
      item.include?('IBM_DB.gemspec') ||
      item.include?('.gem') ||
      item.include?('ibm_db_mswin32.rb')
  end

  if RUBY_PLATFORM =~ /mswin32/ || RUBY_PLATFORM =~ /mingw/
    spec.platform = Gem::Platform::CURRENT
    spec.add_dependency('archive-zip', '>= 0.7.0')
  else
    spec.files = candidates.delete_if { |item| item.include?('lib/mswin32') }
    # Check for the pre-built IBM_DB driver for this platform: #{RUBY_PLATFORM}
    # find ibm_db driver path
    drv_path = Pathname.new(File.dirname(__FILE__)) + 'lib'
    # Locate ibm_db driver path: #{drv_path.realpath}
    drv_lib = drv_path + 'ibm_db.so'
    if drv_lib.file?
      # ibm_db driver was found:   #{drv_lib.realpath}
    else
      # ibm_db driver binary was not found. The driver native extension to be built during install.
      spec.extensions << 'ext/extconf.rb'
    end
  end

  spec.test_file = 'test/ibm_db_test.rb'
end
