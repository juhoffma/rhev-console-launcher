#!/usr/bin/env ruby

# This script calls the RHEV-M Virt API and creates callable cmd-lines
# to the remote viewer.
# 
# written by Juergen Hoffmann <buddy@redhat.com>
# May 14th, 2013 

require 'rubygems'
require 'rest_client'
require 'xmlsimple'
require 'pp'
require 'clipboard'
require 'optparse'

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options]"

  options[:print] = false
  opts.on( '-p', '--print', 'Print the command to launch the Remote Viewer instead of executing it') do |directory|
    options[:print] = true
  end

  options[:dryrun] = false
  opts.on( '-d', '--dry-run', 'Do not execute the Remote Viewer Application') do |dryrun|
    options[:dryrun] = true
  end

  options[:host] = nil
  opts.on( '-h', '--host HOSTNAME', 'The Hostname of your RHEV-M Installation') do |host|
    options[:host] = host
  end

  options[:cert] = File.expand_path('~/ca.crt')
  opts.on( '-c', '--cert PATH', 'The Path to the Certificate File (defaults to "~/ca.crt")') do |f|
    options[:cert] = f
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

@host = options[:host]
@user = options[:user]
@pass = options[:pass]
@cert = options[:cert]

@vms = Array.new

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

# Create a little helper object that we will use to 
# make connections to the REST API
rhevm = RestClient::Resource.new(
    "https://" + @host, 
    :user => @user, 
    :password => @pass,
    :ssl_ca_cert => @cert,
    :ssl_version => "SSLv3",
    :verify_ssl => OpenSSL::SSL::VERIFY_NONE)

# get the vms api and get the list of vms
vms_data = XmlSimple.xml_in(rhevm["/api/vms"].get.body, { 'ForceArray' => false })

# Iterate through the VM's and get all the 
# required information
vms_data['vm'].each do |vm|
  # Making sure we only consider VM's that are in state up (so they do have a console to connect to)
  # and that have the spice protocol enabled as the connection mode
  if vm['status']['state'] == "up" && vm['display']['type'] == "spice"
    @vms.push(VM.new(vm))
  end
end

# Print the selection to the User
@vms.each_with_index do |v, index|
  puts "#{index+1}. Name: #{v.name} Description: #{v.description} State: #{v.state}"
end

puts "Please select the VM you wish to open: "

STDOUT.flush  
index = gets.chomp.to_i
if index > @vms.size
  puts "ERROR: Your selection #{index} is out of range."
  exit 1
end

vm = @vms[index-1]

pp vm

# let us no gather the host subject
hosts_data = XmlSimple.xml_in(rhevm["/api/hosts/"+vm.host_uuid].get.body, { 'ForceArray' => false })
host_subject = hosts_data['certificate']['subject']

ticket_data = XmlSimple.xml_in(rhevm["/api/vms/" + vm.id + "/ticket"].post("<action><ticket><expiry>300</expiry></ticket></action>", :content_type => 'application/xml').body, { 'ForceArray' => false })
password = ticket_data['ticket']['value']
Clipboard.copy password

# Now that we have all the information we can print the cmd line
puts "VM: #{vm.name} state: #{vm.state} Password: #{password}"
command = "/Applications/RemoteViewer.app/Contents/MacOS/RemoteViewer --spice-ca-file #{@cert} --spice-host-subject #{host_subject} spice://#{vm.address}/?port=#{vm.port}\\&tls-port=#{vm.secure_port}"
puts command if options[:print]
%x{#{command}} unless options[:dryrun]

exit 0


