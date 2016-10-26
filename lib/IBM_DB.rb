# frozen_string_literal: true
if RUBY_PLATFORM =~ /darwin/i
  cli_package_path = File.dirname(__FILE__) + '/clidriver'
  if Dir.exist?(cli_package_path)
    current_path = File.expand_path(File.dirname(File.dirname(__FILE__))).to_s

    cmd = "chmod 755 #{current_path}/lib/ibm_db.bundle "
    `#{cmd}`

    cmd = "chmod 755 #{current_path}/lib/clidriver/lib/libdb2.dylib"
    `#{cmd}`

    cmd = "install_name_tool -change libdb2.dylib #{current_path}/lib/clidriver/lib/libdb2.dylib #{current_path}/lib/ibm_db.bundle"
    `#{cmd}`

    $LOAD_PATH.unshift("#{current_path}/lib")
  end

  require 'ibm_db.bundle'

elsif RUBY_PLATFORM =~ /mswin32/ || RUBY_PLATFORM =~ /mingw32/
  require 'mswin32/ibm_db'
else
  require 'ibm_db.so'
end
