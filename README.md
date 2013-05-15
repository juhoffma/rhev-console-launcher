# rhev-console-launcher

## Installation
Next to the console-launcher.rb script, some gems are required. Please install them with the following commands.

```
  gem install rest-client
  gem install xml-simple
  gem install clipboard
```

On MacOSX This script requires [RemoteViewer](http://people.freedesktop.org/~teuf/spice-gtk-osx/dmg/0.3.1/) to be installed.

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
                                       