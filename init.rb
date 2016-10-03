# +----------------------------------------------------------------------+
# |  Licensed Materials - Property of IBM                                |
# |                                                                      |
# | (C) Copyright IBM Corporation 2006, 2007.                            |
# +----------------------------------------------------------------------+

require 'pathname'

begin
  puts ".. Attempt to load IBM_DB Ruby driver for IBM Data Servers for this platform: #{RUBY_PLATFORM}"
  unless defined? IBM_DB
    # find IBM_DB driver path relative init.rb
    drv_path = Pathname.new(File.dirname(__FILE__)) + 'lib'
    drv_path += (RUBY_PLATFORM =~ /mswin32/) ? 'mswin32' : 'linux32'
    puts ".. Locate IBM_DB Ruby driver path: #{drv_path}"
    drv_lib = drv_path + 'ibm_db.so'
    require "#{drv_lib.to_s}"
    puts ".. Successfuly loaded IBM_DB Ruby driver: #{drv_lib}"
  end
rescue
  raise LoadError, "Failed to load IBM_DB Driver !?"
end
