maintainer       "RocketLabs Development"
maintainer_email "info@rocketlabsdev.com"
license          "All rights reserved"
description      "Installs/Configures gitolite"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
depends          "git"
version          "0.0.3"

attribute 'gitolite_global/prefix',
  :display_name => 'Gitolite prefix',
  :description => 'Installation prefix for Gitolite code files',
  :default => '/usr/local'

attribute 'gitolite_global/ref',
  :display_name => 'Gitolite version reference',
  :description => <<-EODESC.gsub(/^  */, ''),
      Version tag to checkout when installing gitolite, which may be any valid git reference.
      If Gitolite g3 is desired, the ref should be a g3 tag matching /^v3/, else the
      installation will use g2-style executables and arguments.
  EODESC
  :default => 'v2.3.1'
