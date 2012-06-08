#
# Cookbook Name:: gitolite
# Recipe:: default
#
# Copyright 2011, RocketLabs Development
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
#

require_recipe "git"

PREFIX = node.gitolite_global.prefix
TMP = Chef::Config[:file_cache_path]
REPO_DEST = File.join(TMP, 'gitolite-source')
G3 = node.gitolite_global.ref =~ /^v3/

bash 'checkout_gitolite' do
  cwd TMP
  code 'git clone git://github.com/sitaramc/gitolite gitolite-source'
  not_if { File.exists?(File.join(REPO_DEST, '.git')) }
end

bash 'reset_to_ref' do
  cwd REPO_DEST
  code "git reset --hard #{node.gitolite_global.ref}"
end

bash 'install_gitolite' do
  cwd REPO_DEST
  if G3
    code "./install -ln #{PREFIX}/bin"
    creates "#{PREFIX}/bin/gitolite"
  else
    code <<-EOH
    set -e
    mkdir -p #{PREFIX}/share/gitolite/conf #{PREFIX}/share/gitolite/hooks
    src/gl-system-install #{PREFIX}/bin #{PREFIX}/share/gitolite/conf #{PREFIX}/share/gitolite/hooks
    EOH
    creates "#{PREFIX}/bin/gl-setup"
  end
end

node.gitolite.each do |instance|
  username = instance.fetch('name')
  groupname = instance.fetch('group', username)
  home_directory = instance.fetch('home_directory', "/home/#{username}")

  user username do
    comment "#{username} Gitolite User"
    home home_directory
    shell "/bin/sh"
  end

  group groupname do
  end

  if node.platform == 'solaris2'
    execute "unlock the newly-created '#{username}' account" do
      command "passwd -u #{username}"
    end
  end

  directory home_directory do
    mode 0770
    owner username
    group groupname
    action :create
  end

  admin_name = instance.fetch('admin')
  if keyname = instance['admin_key_name']
    admin_ssh_key = data_bag_item('keys', keyname).fetch('public_key')
  else
    admin = data_bag_item('users', admin_name)
    admin_ssh_key = admin['ssh_key'] || admin['ssh_keys']
  end

  file "#{TMP}/#{admin_name}.pub" do
    content admin_ssh_key
    mode 0660
    owner username
    group groupname
  end

  template "#{home_directory}/.gitolite.rc" do
    if G3
      source 'g3-gitolite.rc.erb'
    else
      source 'gitolite.rc.erb'
    end
    mode 0664
    owner username
    group groupname
    action :create
    variables(:prefix => PREFIX, :git_path => node.gitolite_global.git_path)
  end

  execute "installing_gitolite_for" do
    user username
    if G3
      command "#{PREFIX}/bin/gitolite setup -pk #{TMP}/#{admin_name}.pub"
    else
      command "#{PREFIX}/bin/gl-setup #{TMP}/#{admin_name}.pub"
    end
    environment({'HOME' => home_directory})
  end

  if instance.has_key?('campfire')
    gem_package "tinder"

    template "#{home_directory}/.gitolite/hooks/common/campfire-hook.rb" do
      source "campfire-hook.rb.erb"
      mode 0775
      owner username
      group groupname
      variables( :campfire => instance['campfire'] )
    end

    cookbook_file "#{home_directory}/.gitolite/hooks/common/campfire-notification.rb" do
      source "campfire-notification.rb"
      mode 0775
      owner username
      group groupname
    end

    cookbook_file "#{home_directory}/.gitolite/hooks/common/post-receive" do
      source "campfire-post-receive"
      mode 0775
      owner username
      group groupname
    end
  end
end
