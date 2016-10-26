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
  spec.test_file = 'test/ibm_db_test.rb'

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
    spec.extensions << 'ext/extconf.rb'
  end
end
