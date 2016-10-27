#!/usr/bin/env ruby

require 'open-uri'
require 'rubygems/package'
require 'zlib'
require 'fileutils'
require 'pathname'

# +----------------------------------------------------------------------+
# |  Licensed Materials - Property of IBM                                |
# |                                                                      |
# | (C) Copyright IBM Corporation 2006 - 2016                            |
# +----------------------------------------------------------------------+

WIN = RUBY_PLATFORM =~ /mswin/ || RUBY_PLATFORM =~ /mingw/

# use ENV['IBM_DB_HOME'] or latest db2 you can find
ibm_db_home = ENV['IBM_DB_HOME']

machine_bits = ['ibm'].pack('p').size * 8

is64_bit = true

if machine_bits == 64
  is64_bit = true
  puts "Detected 64-bit Ruby\n "
else
  is64_bit = false
  puts "Detected 32-bit Ruby\n "
end

module Kernel
  def suppress_warnings
    orig_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = orig_verbosity
    result
  end
end

downloadlink = ''
downloadlink_root = 'http://public.dhe.ibm.com/ibmdl/export/pub/software/data/db2/drivers/odbc_cli'

if RUBY_PLATFORM =~ /aix/i
  # AIX
  if is64_bit
    puts 'Detected platform - aix 64'
    downloadlink = File.join(downloadlink_root, 'aix64_odbc_cli.tar.gz')
  else
    puts 'Detected platform - aix 32'
    downloadlink = File.join(downloadlink_root, 'aix32_odbc_cli.tar.gz')
  end
elsif RUBY_PLATFORM =~ /powerpc/ || RUBY_PLATFORM =~ /ppc/
  # PPC
  if is64_bit
    puts 'Detected platform - ppc linux 64'
    downloadlink = File.join(downloadlink_root, 'ppc64_odbc_cli.tar.gz')
  else
    puts 'Detected platform - ppc linux 64'
    downloadlink = File.join(downloadlink_root, 'ppc32_odbc_cli.tar.gz')
  end
elsif RUBY_PLATFORM =~ /linux/
  # x86
  if is64_bit
    puts 'Detected platform - linux x86 64'
    downloadlink = File.join(downloadlink_root, 'linuxx64_odbc_cli.tar.gz')
  else
    puts 'Detected platform - linux 32'
    downloadlink = File.join(downloadlink_root, 'linuxia32_odbc_cli.tar.gz')
  end
elsif RUBY_PLATFORM =~ /sparc/i
  # Solaris
  if is64_bit
    puts 'Detected platform - sun sparc64'
    downloadlink = File.join(downloadlink_root, 'sun64_odbc_cli.tar.gz')
  else
    puts 'Detected platform - sun sparc32'
    downloadlink = File.join(downloadlink_root, 'sun32_odbc_cli.tar.gz')
  end
elsif RUBY_PLATFORM =~ /solaris/i
  if is64_bit
    puts 'Detected platform - sun amd64'
    downloadlink = File.join(downloadlink_root, 'sunamd64_odbc_cli.tar.gz')
  else
    puts 'Detected platform - sun amd32'
    downloadlink = File.join(downloadlink_root, 'sunamd32_odbc_cli.tar.gz')
  end
elsif RUBY_PLATFORM =~ /darwin/i
  if is64_bit
    puts 'Detected platform - MacOS darwin64'
    downloadlink = File.join(downloadlink_root, 'macos64_odbc_cli.tar.gz')
  else
    puts 'Mac OS 32 bit not supported. Please use an x64 architecture.'
  end
end

def download_cli_package(destination_path, download_link)
  destination = Pathname.new(File.join(destination_path, 'clidriver.tar.gz')).expand_path

  open(URI.parse(download_link), 'Accept-Encoding' => 'identity') do |response|
    destination.write(response.read)
  end

  destination.to_s
end

def untar_cli_package(archive, destination)
  Zlib::GzipReader.open(archive) do |gz|
    Gem::Package::TarReader.new(gz) do |tar|
      tar.each do |entry|
        file = Pathname.new(File.join(destination, entry.full_name))
        file.delete if file.exist? && file.file?
        FileUtils.mkdir_p(file.dirname)
        if entry.file?
          file.write(entry.read)
          file.chmod(entry.header.mode)
        elsif entry.header.typeflag == '2' # Symlink!
          File.symlink(entry.header.linkname, file)
        end
      end
    end
  end
end

if ibm_db_home.nil? || ibm_db_home == ''
  ibm_db_include = ENV['IBM_DB_INCLUDE']
  ibm_db_lib = ENV['IBM_DB_LIB']

  if (ibm_db_include.nil? || ibm_db_lib.nil?) ||
     (ibm_db_include == '' || ibm_db_lib == '')

    if !downloadlink.nil? && !downloadlink.empty?
      puts "Environment variable IBM_DB_HOME is not set. Downloading and setting up the DB2 client driver\n"
      destination = File.expand_path('../../lib', __FILE__)

      archive = download_cli_package(destination, downloadlink)
      untar_cli_package(archive, destination)
      FileUtils.rm_rf(archive)

      ibm_db_home = "#{destination}/clidriver"
      ibm_db_include = "#{ibm_db_home}/include"
      ibm_db_lib = "#{ibm_db_home}/lib"
    else
      puts "Environment variable IBM_DB_HOME is not set. Set it to your DB2/IBM_Data_Server_Driver installation directory and retry gem install.\n "
      exit 1
    end
  end
else
  ibm_db_include = "#{ibm_db_home}/include"
  ibm_db_lib = is64_bit ? "#{ibm_db_home}/lib64" : "#{ibm_db_home}/lib32"
end

unless File.directory?(ibm_db_lib)
  suppress_warnings do ibm_db_lib = "#{ibm_db_home}/lib" end
  unless File.directory?(ibm_db_lib)
    puts "Cannot find #{ibm_db_lib} directory. Check if you have set the IBM_DB_HOME environment variable's value correctly\n "
    exit 1
  end
  notify_string = 'Detected usage of IBM Data Server Driver package. Ensure you have downloaded '
  notify_string = is64_bit ? notify_string + '64-bit package ' : notify_string + '32-bit package '
  notify_string += "of IBM_Data_Server_Driver and retry the 'gem install ibm_db' command\n "

  puts notify_string
end

unless File.directory?(ibm_db_include)
  puts " #{ibm_db_home}/include folder not found. Check if you have set the IBM_DB_HOME correctly\n "
  exit 1
end

require 'mkmf'

dir_config('IBM_DB', ibm_db_include, ibm_db_lib)

def crash(str)
  printf(" extconf failure: %s\n", str)
  exit 1
end

if RUBY_VERSION =~ /1.9/ || RUBY_VERSION =~ /2./
  create_header('gil_release_version')
  create_header('unicode_support_version')
end

unless have_library(WIN ? 'db2cli' : 'db2',
                    'SQLConnect') || find_library(WIN ? 'db2cli' : 'db2',
                                                  'SQLConnect',
                                                  ibm_db_lib)
  crash(<<EOL)
Unable to locate libdb2.so/a under #{ibm_db_lib}

Follow the steps below and retry

Step 1: - Install IBM DB2 Universal Database Server/Client

step 2: - Set the environment variable IBM_DB_HOME as below

             (assuming bash shell)

             export IBM_DB_HOME=<DB2/IBM_Data_Server_Driver installation directory>
             #(Eg: export IBM_DB_HOME=/opt/ibm/db2/v10)

step 3: - Retry gem install

EOL
end

require 'rbconfig' if RUBY_VERSION =~ /2./

alias libpathflag0 libpathflag
def libpathflag(libpath)
  if RUBY_PLATFORM =~ /darwin/i
    if RUBY_VERSION =~ /2./
      libpathflag0 + case RbConfig::CONFIG['arch']
                     when /solaris2/
                       libpath[0..-2].map { |path| " -R#{path}" }.join
                     when /linux/
                       libpath[0..-2].map { |path| " -R#{path} " }.join
                     else
                       ''
                     end
    else
      libpathflag0 + case Config::CONFIG['arch']
                     when /solaris2/
                       libpath[0..-2].map { |path| " -R#{path}" }.join
                     when /linux/
                       libpath[0..-2].map { |path| " -R#{path} " }.join
                     else
                       ''
                     end
    end
  else
    if RUBY_VERSION =~ /2./
      case RbConfig::CONFIG['arch']
      when /solaris2/
        libpath[0..-2].map { |path| " -R#{path}" }.join
      when /linux/
        libpath[0..-2].map { |path| " -R#{path} " }.join
      else
        ''
      end
    else
      case Config::CONFIG['arch']
      when /solaris2/
        libpath[0..-2].map { |path| " -R#{path}" }.join
      when /linux/
        libpath[0..-2].map { |path| " -R#{path} " }.join
      else
        ''
      end
    end
    libpathflag0 + " '-Wl,-R$$ORIGIN/clidriver/lib' "
  end
end

have_header('gil_release_version')
have_header('unicode_support_version')

create_makefile('ibm_db')
