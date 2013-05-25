$LOAD_PATH.push File.expand_path("../lib", __FILE__)

require "console-launcher_version"
require 'date'

Gem::Specification.new do |s|
  s.name        = 'console-launcher'
  s.version     = ConsoleLauncher::VERSION
  s.date        = Time.new.to_date
  s.summary     = "RHEV-M Console Launcher"
  s.description = "This gem provides the ability to launch console sessions on Mac"
  s.authors     = ["Juergen Hoffmann", "Vinny Valdez", "Thomas Crowe"]
  s.email       = ['buddy@redhat.com', 'vvaldez@redhat.com', 'tcrowe@redhat.com']
  s.homepage    = 'https://github.com/juhoffma/rhev-console-launcher'
  s.executables = 'console-launcher'
  s.files       = ['lib/console-launcher.rb',
                   'lib/console-launcher_version.rb',
                   'lib/rhev-manager/virtual-machine.rb',
                   'bin/console-launcher',
                   'man/console-launcher.1.html',
                   'man/console-launcher.1']
  s.add_dependency 'rest-client', '~>1.6.7'
  s.add_dependency 'xml-simple', '~>1.1.2'
  s.add_dependency 'highline', '~>1.6.19'
  s.add_development_dependency("rake")
  s.add_development_dependency("rdoc")
  s.requirements << 'RemoteViewer - get it from http://people.freedesktop.org/~teuf/spice-gtk-osx/dmg/0.3.1/'
end
