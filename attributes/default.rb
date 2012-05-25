case platform
when "solaris2", "smartos"
  default.gitolite_global.prefix = '/opt/local'
else
  default.gitolite_global.prefix = '/usr/local'
end

default.gitolite = []
default.gitolite_global.ref = 'v2.31'
