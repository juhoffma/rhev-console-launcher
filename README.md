# rhev-console-launcher
https://github.com/juhoffma/rhev-console-launcher

## Preparation
In addition to the console-launcher.rb script, a few gems are required. 

In case you do not have [bundler](http://gembundler.com) installed you have to install it first

```
  gem install bundler
```

Then you can simply run the following command...

```
  bundle install
```

alternatively you can go ahead and run

```
gem install console-launcher
```

and all gems we depend upon will be installed immediately

On MacOSX This script requires [RemoteViewer](http://people.freedesktop.org/~teuf/spice-gtk-osx/dmg/0.3.1/) to be installed. This script looks for it in /Applications/RemoteViewer.app so make sure to install it to that same location.

## Running the script
The script provides a self explanatory help message.
```
  $ ./console-launcher.rb --help

  This script connects to a RHEV-M Instance and lists all running VMs. You can choose which VM you want to
  connect to via SPICE Protocol.

  This script requires a working SPICE Client for your platform. You can get it from
     - MacOSX:    http://people.freedesktop.org/~teuf/spice-gtk-osx/dmg/0.3.1/
     - Linux:     TBD
     - Windows:   TBD

  Usage: ./console-launcher.rb [options]
          --print                      Print the command to launch the Remote Viewer instead of executing it
      -d, --dry-run                    Do not execute the Remote Viewer Application
      -h, --host HOSTNAME              The Hostname of your RHEV-M Installation
      -c, --cert PATH                  The Path to the Certificate File (defaults to "~/ca.crt")
      -u, --username USERNAME          The Username used to establish the connection to --host (defaults to admin@internal)
      -p, --password PASSWORD          The Password used to establish the connection to --host
          --help                       Display this Help Message
```
                                       
