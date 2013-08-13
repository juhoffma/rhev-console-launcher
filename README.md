# rhev-console-launcher
https://github.com/juhoffma/rhev-console-launcher

To run rhev console launcher you can simply install it as a gem
```
gem install console-launcher
```
and all gems we depend upon will be installed immediately

Alternatively you can go ahead and install it manually...

## Manual Installation

In addition to the console-launcher script, a few gems are required. 

In case you do not have [bundler](http://gembundler.com) installed you have to install it first

```
  gem install bundler
```

Then you can simply run the following command...

```
  bundle install
```

## Introduction
This script requires [virt-viewer](http://spice-space.org/download.html) to be installed. On Mac OSX you can get the most recent version of the Application from http://people.freedesktop.org/~teuf/spice-gtk-osx/dmg/0.3.1/

## Running the script
The script provides a self explanatory help message.
```
  $ ./console-launcher --help

  This script connects to a RHEV-M Instance and lists all running VMs. You can choose which VM you want to
  connect to via SPICE Protocol.

  This script requires a working SPICE Client for your platform. You can get it from
     - MacOSX:    http://people.freedesktop.org/~teuf/spice-gtk-osx/dmg/0.3.1/
     - Linux:     http://virt-manager.et.redhat.com/download/sources/virt-viewer/virt-viewer-0.5.6.tar.gz
     - Windows:   http://virt-manager.org/download/sources/virt-viewer/virt-viewer-x64-0.5.6.msi

  Usage: ./console-launcher [options]
          --print                      Print the command to launch the Remote Viewer instead of executing it
      -d, --dry-run                    Do not execute the Remote Viewer Application
      -h, --host HOSTNAME              The Hostname of your RHEV-M Installation
      -c, --cert PATH                  The Path to the Certificate File (defaults to "~/ca.crt")
      -u, --username USERNAME          The Username used to establish the connection to --host (defaults to admin@internal)
      -p, --password PASSWORD          The Password used to establish the connection to --host
          --help                       Display this Help Message
```

## Configuration
This script automatically creates a configuration file `~/.console-launcher.rc.yaml`. This allows you to setup your environment. The configuration file follows the [YAML](http://www.yaml.org) standards and is read in as a YAML file.
```
---
:print: false
:dryrun: false
:host: rhevm.example.com
:user: admin@internal
:pass: secret:password!
:viewer: /Applications/RemoteViewer.app/Contents/MacOS/RemoteViewer
```            

## Installation Instructions on Fedora 18

thanks to Benjamin Kruell for trying that out.

1.) download `virt-viewer-0.5.6` or newer package from:
ftp://rpmfind.net/linux/fedora/linux/development/rawhide/x86_64/os/Packages/v/virt-viewer-0.5.6-1.fc20.i686.rpm

2.) download `libgovirt-0.0.3-2.fc20.i686.rpm` or newer
ftp://rpmfind.net/linux/fedora/linux/development/rawhide/x86_64/os/Packages/l/libgovirt-0.0.3-2.fc20.i686.rpm

3.) `yum -y install intltool`

4.) go to the location containing the downloaded rpm and install them:
`yum localinstall libgovirt-0.0.3-2.fc20.i686.rpm`
`yum localinstall virt-viewer-0.5.6-1.fc20.i686.rpm`

5.) `yum -y install spice-xpi`

* console-launcher will not work without virt-viewer 0.5.6 or newer
* because libgovirt 64bit package does not ship the libgovirt(x64) flag which is required by the virt-viewer 64-bit package, we currently have to use the 32-bit packages until a newer version of the package.

## Problem Solving
If you still run into issues with SSL Certificates like:
```
console-launcher --host student1-aio.juhoffma.gsso.redhat.com
/Users/buddy/.rvm/gems/ruby-1.9.3-p362@rails3tutorial2ndEd/gems/rest-client-1.6.7/lib/restclient/abstract_response.rb:48:in `return!'
/Users/buddy/.rvm/gems/ruby-1.9.3-p362@rails3tutorial2ndEd/gems/rest-client-1.6.7/lib/restclient/request.rb:230:in `process_result'
/Users/buddy/.rvm/gems/ruby-1.9.3-p362@rails3tutorial2ndEd/gems/rest-client-1.6.7/lib/restclient/request.rb:178:in `block in transmit'
/Users/buddy/.rvm/rubies/ruby-1.9.3-p362/lib/ruby/1.9.1/net/http.rb:745:in `start'
/Users/buddy/.rvm/gems/ruby-1.9.3-p362@rails3tutorial2ndEd/gems/rest-client-1.6.7/lib/restclient/request.rb:172:in `transmit'
/Users/buddy/.rvm/gems/ruby-1.9.3-p362@rails3tutorial2ndEd/gems/rest-client-1.6.7/lib/restclient/request.rb:64:in `execute'
/Users/buddy/.rvm/gems/ruby-1.9.3-p362@rails3tutorial2ndEd/gems/rest-client-1.6.7/lib/restclient/request.rb:33:in `execute'
/Users/buddy/.rvm/gems/ruby-1.9.3-p362@rails3tutorial2ndEd/gems/rest-client-1.6.7/lib/restclient/resource.rb:51:in `get'
/Users/buddy/.rvm/gems/ruby-1.9.3-p362@rails3tutorial2ndEd/gems/console-launcher-0.0.11/lib/console-launcher.rb:81:in `get_vms'
/Users/buddy/.rvm/gems/ruby-1.9.3-p362@rails3tutorial2ndEd/gems/console-launcher-0.0.11/bin/console-launcher:104:in `<top (required)>'
/Users/buddy/.rvm/gems/ruby-1.9.3-p362@rails3tutorial2ndEd/bin/console-launcher:23:in `load'
/Users/buddy/.rvm/gems/ruby-1.9.3-p362@rails3tutorial2ndEd/bin/console-launcher:23:in `<main>'
/Users/buddy/.rvm/gems/ruby-1.9.3-p362@rails3tutorial2ndEd/bin/ruby_noexec_wrapper:14:in `eval'
/Users/buddy/.rvm/gems/ruby-1.9.3-p362@rails3tutorial2ndEd/bin/ruby_noexec_wrapper:14:in `<main>'
```
This link provides some very useful information: http://railsapps.github.io/openssl-certificate-verify-failed.html