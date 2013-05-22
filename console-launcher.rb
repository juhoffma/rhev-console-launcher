#!/usr/bin/env ruby

# Copyright 2013 Red Hat Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script calls the RHEV-M Virt API and creates callable cmd-lines
# to the remote viewer.
# 
# written by:
#   Juergen Hoffmann <buddy@redhat.com>
#   Thomas Crowe <tcrowe@redhat.com>
#   Vinny Valdez <vvaldez@redhat.com>
#
# May 14, 2013 
#   - initial version
# 
# May 22, 2013 
#   - Made sure to strip http and https from the host definition

require 'rubygems'
require 'rest_client'
require 'xmlsimple'
require 'optparse'
require 'tempfile' # required to download the certificate files on they fly
require 'net/http'
require 'highline/import' # Secure Password Prompting if a user does not provide it when the script is called

# queries the User for a password
def get_password(prompt="RHEV-M Password: ")
   ask(prompt) {|q| q.echo = "*"}
end

def strip_url(url)
  # Remove any leading http or https from the host
  url = url.split("://")[1] if url.include? "://"
  return url
end

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options]"

  options[:print] = false
  opts.on( '--print', 'Print the command to launch the Remote Viewer instead of executing it') do |directory|
    options[:print] = true
  end

  options[:dryrun] = false
  opts.on( '-d', '--dry-run', 'Do not execute the Remote Viewer Application') do |dryrun|
    options[:dryrun] = true
  end

  options[:host] = nil
  opts.on( '-h', '--host HOSTNAME', 'The Hostname of your RHEV-M Installation') do |host|
    options[:host] = strip_url(host)
  end

  options[:user] = "admin@internal"
  opts.on( '-u', '--username USERNAME', 'The Username used to establish the connection to --host (defaults to admin@internal)') do |u|
    options[:user] = u
  end

  options[:pass] = nil
  opts.on( '-p', '--password PASSWORD', 'The Password used to establish the connection to --host') do |pass|
    options[:pass] = pass
  end

  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '', '--help', 'Display this Help Message' ) do
    puts ""
    puts "This script connects to a RHEV-M Instance and lists all running VMs. You can choose which VM you want to"
    puts "connect to via SPICE Protocol."
    puts ""
    puts "This script requires a working SPICE Client for your platform. You can get it from"
    puts "   - MacOSX:    http://people.freedesktop.org/~teuf/spice-gtk-osx/dmg/0.3.1/"
    puts "   - Linux:     TBD"
    puts "   - Windows:   TBD"
    puts ""
    puts opts
    exit
  end
end

# Parse the command-line. Remember there are two forms
# of the parse method. The 'parse' method simply parses
# ARGV, while the 'parse!' method parses ARGV and removes
# any options found there, as well as any parameters for
# the options. What's left is the list of files to resize.
optparse.parse!

if options[:host] == nil
  puts "ERROR: You have to configure RHEV-M Hostname to connect to"
  puts optparse.help
  exit 1
end

options[:pass] = get_password if options[:pass] == nil

class VM
  attr_accessor :id, :name, :description, :host_uuid, :state, :port, :secure_port, :address

  def initialize(vm)
    @id = vm['id']
    @name = vm['name']
    @description = vm['description']    
    @address = vm['display']['address'] unless vm['display'].nil?
    @port = vm['display']['port'] unless vm['display'].nil?
    @secure_port = vm['display']['secure_port'] unless vm['display'].nil?
    @state = vm['status']['state'] unless vm['status'].nil?
    @host_uuid = vm['host']['id'] unless vm['host'].nil?
  end
end


# download the certificate file on the fly
begin
  cert = Tempfile.new(options[:host] + ".crt")    
  Net::HTTP.start(options[:host]) do |http|
    begin
      http.request_get('/ca.crt') do |resp|
        resp.read_body do |segment|
          cert.write(segment)
        end
      end
    ensure
      cert.close()
    end
  end
  @cert = cert.path
rescue => e
  puts "There has been an error downloading the certificate file from #{options[:host]}"
  e.message
  exit 1
end

# Create a little helper object that we will use to 
# make connections to the REST API
rhevm = RestClient::Resource.new(
    "https://" + options[:host], 
    :user => options[:user], 
    :password => options[:pass],
    :ssl_ca_cert => @cert,
    :ssl_version => "SSLv3",
    :verify_ssl => OpenSSL::SSL::VERIFY_NONE)

def get_vms(vms_data)
  # Iterate through the VM's and get all the 
  # required information
  @vms = Array.new	# Clear out array
  vms_data['vm'].each do |vm|
    # Making sure we only consider VM's that are in state up (so they do have a console to connect to)
    # and that have the spice protocol enabled as the connection mode
    if vm['status']['state'] == "up" && vm['display']['type'] == "spice"
      @vms.push(VM.new(vm))
    end
  end
  return @vms
end

while true do
  begin
    @vms = Array.new	# Clear out array
    # get the vms api and get the list of vms
    vms_data = XmlSimple.xml_in(rhevm["/api/vms"].get.body, { 'ForceArray' => false })
    @vms = get_vms(vms_data)
    # Print the selection to the User
    puts
    puts "Running Virtual Machines found for #{options[:host]}:"
    @vms.each_with_index do |v, index|
      puts "#{index+1}. Name: #{v.name} Description: #{v.description} State: #{v.state}"
    end
    puts
    puts "r. Refresh"
    puts "q. Quit"
    puts
  
    puts "Please select the VM you wish to open: "
  
    STDOUT.flush  
    index = gets.chomp	# Hackish, just wanting to add quit
    if index.to_s == "q"
      exit 0
    elsif index.to_s == "r"
      next
    end
    index = index.to_i
    if (1..@vms.size).member?(index)
      break
    else
      puts "ERROR: Your selection #{index} is out of range."
    end
  rescue => e
    puts "There was an error retrieving the Virtual Machines from #{options[:host]}: #{e.message}"
    exit 1
  end
end
  
vm = @vms[index-1]

# let us no gather the host subject
hosts_data = XmlSimple.xml_in(rhevm["/api/hosts/"+vm.host_uuid].get.body, { 'ForceArray' => false })
host_subject = hosts_data['certificate']['subject']

ticket_data = XmlSimple.xml_in(rhevm["/api/vms/" + vm.id + "/ticket"].post("<action><ticket><expiry>300</expiry></ticket></action>", :content_type => 'application/xml').body, { 'ForceArray' => false })
password = ticket_data['ticket']['value']

# Creating the .vv File for the connection
# download the certificate file on the fly
vv = Tempfile.new("#{vm.name}.vv")    
begin
  vv.puts("[virt-viewer]")
  vv.puts("type=spice")
  vv.puts("host=#{vm.address}")
  vv.puts("port=#{vm.port}")
  vv.puts("password=#{password}")
  vv.puts("tls-port=#{vm.secure_port}")
  vv.puts("fullscreen=0")
  vv.puts("title=vm:#{vm.name} - %d - Press SHIFT+F12 to Release Cursor")
  vv.puts("enable-smartcard=0")
  vv.puts("enable-usb-autoshare=1")
  vv.puts("usb-filter=-1,-1,-1,-1,0")
  vv.puts("host-subject=#{host_subject}")
  vv.puts("toggle-fullscreen=shift+f11")
  vv.puts("release-cursor=shift+f12")
ensure 
  vv.close()
end

# Now that we have all the information we can print the cmd line
puts "VM: #{vm.name} state: #{vm.state} Password: #{password}"
command = "/Applications/RemoteViewer.app/Contents/MacOS/RemoteViewer --spice-ca-file #{@cert} #{vv.path}"
puts command if options[:print]
%x{#{command}} unless options[:dryrun]

exit 0


