case platform
when "solaris2", "smartos"
  default.gitolite_global.prefix = '/opt/local'
  default.gitolite_global.git_path = '/opt/local/bin'
else
  default.gitolite_global.prefix = '/usr/local'
  default.gitolite_global.git_path = ''
end

default.gitolite = []
default.gitolite_global.ref = 'v2.3.1'
