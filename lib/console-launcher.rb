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

# Author::    Juergen Hoffmann  (mailto:buddy@redhat.com)
# Author::    Vinny Valdez  (mailto:vvaldez@redhat.com)
# Author::    Thomas Crowe  (mailto:tcrowe@redhat.com)
# Copyright:: Copyright (c) 2013 Red Hat Inc.
# License::   http://www.apache.org/licenses/LICENSE-2.0

require 'rubygems'
require 'rest_client'
require 'xmlsimple'
require 'tmpdir' # required to download the certificate files on they fly
require 'net/http'
require 'highline/import' # Secure Password Prompting if a user does not provide it when the script is called
require 'rhev-manager/virtual-machine'
require 'rbconfig'

# This class provides utility methods to encapsulates RESTful access to the RHEV Manager.
# Since the returned response is in XML this class transforms the XML Response into Ruby Objects.

class RhevManager

  TMP_DIR = Dir.tmpdir

  def initialize(host, user, password)
    @host = host
    @user = user
    @pass = password

    # Create a little helper object that we will use to
    # make connections to the REST API
    @rhevm = RestClient::Resource.new(
        "https://" + @host,
        :user => @user,
        :password => @pass,
        :ssl_ca_cert => @cert,
        :ssl_version => "SSLv3",
        :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
    get_cert
  end

  # Download the Server SSL Certificate file on the fly
  def get_cert()
    begin
      cert = File.new(TMP_DIR + "/" + @host + ".crt", "w+")
      Net::HTTP.start(@host) do |http|
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
      raise "There has been an error downloading the certificate file from #{@host}: #{e.message}"
    end
  end

  # Returns an array of VirtualMachine ruby objects that are running on the RHEV Manager

  def get_vms()
    @vms = Array.new # Clear out array

    # get the vms api and get the list of vms
    vms_data = XmlSimple.xml_in(@rhevm["/api/vms"].get.body, {'ForceArray' => false})

    # Iterate through the VM's and get all the
    # required information
    vms_data['vm'].each do |vm|
      # Making sure we only consider VM's that are in state up (so they do have a console to connect to)
      # and that have the spice protocol enabled as the connection mode
      if vm['status']['state'] == "up" && vm['display']['type'] == "spice"
        @vms.push(VirtualMachine.new(vm))
      end
    end
    return @vms
  end

  # This method takes an index that is used to query the VirtualMachine Array for the VM that is supposed to
  # be started. It then queries the RHEV Manager for the correct subject and then requests a ticket for the
  # console session.
  # It then creates a .vv file that is used to be passed to the RemoteViewer Application. It returns the command
  # to be launched because we fork the process and detach from the RemoteViewer process so we are able to launch
  # more than one Console Session at once.
  def launch_viewer(index)
    vm = @vms[index-1]

    # let us no gather the host subject
    hosts_data = XmlSimple.xml_in(@rhevm["/api/hosts/"+vm.host_uuid].get.body, {'ForceArray' => false})
    host_subject = hosts_data['certificate']['subject']

    ticket_data = XmlSimple.xml_in(@rhevm["/api/vms/" + vm.id + "/ticket"].post("<action><ticket><expiry>30</expiry></ticket></action>", :content_type => 'application/xml').body, {'ForceArray' => false})
    password = ticket_data['ticket']['value']

    # Creating the .vv File for the connection
    # download the certificate file on the fly
    @vv = File.new(TMP_DIR + "/" + vm.name + ".vv", "w+")
    begin
      @vv.puts("[virt-viewer]")
      @vv.puts("type=spice")
      @vv.puts("host=#{vm.address}")
      @vv.puts("port=#{vm.port}")
      @vv.puts("password=#{password}")
      @vv.puts("tls-port=#{vm.secure_port}")
      @vv.puts("fullscreen=0")
      @vv.puts("title=vm:#{vm.name} - %d - Press SHIFT+F12 to Release Cursor")
      @vv.puts("enable-smartcard=0")
      @vv.puts("enable-usb-autoshare=1")
      @vv.puts("usb-filter=-1,-1,-1,-1,0")
      @vv.puts("host-subject=#{host_subject}")
      @vv.puts("toggle-fullscreen=shift+f11")
      @vv.puts("release-cursor=shift+f12")
    ensure
      @vv.close()
    end

    # Now that we have all the information we can print the cmd line
    puts "Console to VM: #{vm.name} state: #{vm.state} is started"

    command = [
        Helper::OPTIONS[:viewer],
        "--spice-ca-file",
        @cert,
        @vv.path,
        {
            :out => Tempfile.new(["RemoteViewer",".out"]).path,
            :err => Tempfile.new(["RemoteViewer",".err"]).path
        }
    ]
  end


end

module Helper

  CONFIG_FILE = File.join(ENV['HOME'], '.console-launcher.rc.yaml')

  OPTIONS = {
      :print => false,
      :dryrun => false,
      :host => nil,
      :user => "admin@internal",
      :pass => nil
  }

  OPTIONS[:viewer] = case RbConfig::CONFIG['host_os']
                       when /mac|darwin/ then
                         "/Applications/RemoteViewer.app/Contents/MacOS/RemoteViewer"
                       when /linux|bsd|cygwin/ then
                         "/usr/bin/remote-viewer"
                       when /mswin|mingw/ then
                         "C:/Program Files/VirtViewer/bin/remote-viewer.exe"
                       # when /solaris|sunos/     then :Linux # needs testing..
                       else
                         raise "Your OS(#{ RbConfig::CONFIG['host_os'] }) is not yet supported"
                     end

  def load_options
    if File.exists? CONFIG_FILE
      config_options = YAML.load_file(CONFIG_FILE)
      OPTIONS.merge!(config_options)

      unless config_options.has_key?(:viewer)
        File.open(CONFIG_FILE, 'w') { |file| YAML::dump(OPTIONS, file) }
      end
    else
      File.open(CONFIG_FILE, 'w') { |file| YAML::dump(OPTIONS, file) }
      STDERR.puts "Initialized configuration file in #{CONFIG_FILE}"
    end
  end

  # queries the User for a password
  def get_password(prompt="RHEV-M Password: ")
    ask(prompt) { |q| q.echo = "*" }
  end

  # Remove any leading http or https from the host
  def strip_url(url)
    url = url.split("://")[1] if url.include? "://"
    return url
  end


end