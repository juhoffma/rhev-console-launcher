Gem::Specification.new do |s|
  s.name        = 'console-launcher'
  s.version     = '0.0.6'
  s.date        = '2013-05-23'
  s.summary     = "RHEV-M Console Launcher"
  s.description = "This gem provides the ability to launch console sessions on Mac"
  s.authors     = ["Juergen Hoffmann", "Vinny Valdez", "Thomas Crowe"]
  s.email       = ['buddy@redhat.com', 'vvaldez@redhat.com', 'tcrowe@redhat.com']
  s.homepage    = 'https://github.com/juhoffma/rhev-console-launcher'
  s.executables = 'console-launcher'
  s.add_runtime_dependency 'rest-client', '~>1.6.7'
  s.add_runtime_dependency 'xml-simple', '~>1.1.2'
  s.add_runtime_dependency 'highline', '~>1.6.19'
  s.requirements << 'RemoteViewer - get it from http://people.freedesktop.org/~teuf/spice-gtk-osx/dmg/0.3.1/'
end
