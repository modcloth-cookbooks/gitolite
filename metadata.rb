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
  :description => 'Version tag to checkout when installing gitolite, which may be any valid git reference',
  :default => 'v3.03'
