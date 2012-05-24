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

bash 'checkout_gitolite' do
  cwd TMP
  code 'git clone git://github.com/sitaramc/gitolite gitolite-source'
  not_if { File.exists?(File.join(REPO_DEST, '.git')) }
end

bash 'install_gitolite' do
  cwd REPO_DEST
  code <<-EOH
    git reset --hard #{node.gitolite_global.ref}
    mkdir -p #{PREFIX}/share/gitolite/conf #{PREFIX}/share/gitolite/hooks
    src/gl-system-install #{PREFIX}/bin #{PREFIX}/share/gitolite/conf #{PREFIX}/share/gitolite/hooks
  EOH
  creates "#{PREFIX}/bin/gl-setup"
end

node.gitolite.each do |instance|
  username = instance['name']

  user username do
    comment "#{username} Gitolite User"
    home "/home/#{username}"
    shell "/bin/bash"
  end

  directory "/home/#{username}" do
    owner username
    action :create
  end

  admin_name = instance['admin']
  admin = data_bag_item('users', admin_name)
  admin_ssh_key = admin['ssh_key'] || admin['ssh_keys']

  file "#{TMP}/gitolite-#{admin_name}.pub" do
    owner username
    content admin_ssh_key
  end

  template "/home/#{username}/.gitolite.rc" do
    owner username
    source "gitolite.rc.erb"
    action :create
  end

  execute "installing_gitolite_for" do
    user username
    command "#{PREFIX}/bin/gl-setup #{TMP}/gitolite-#{admin_name}.pub"
    environment ({'HOME' => "/home/#{username}"})
  end

  if instance.has_key?('campfire')
    gem_package "tinder"
    username = instance['name']

    template "/home/#{username}/.gitolite/hooks/common/campfire-hook.rb" do
      source "campfire-hook.rb.erb"
      mode 0755
      owner username
      variables( :campfire => instance['campfire'] )
    end

    cookbook_file "/home/#{username}/.gitolite/hooks/common/campfire-notification.rb" do
      source "campfire-notification.rb"
      mode 0755
      owner username
    end

    cookbook_file "/home/#{username}/.gitolite/hooks/common/post-receive" do
      source "campfire-post-receive"
      mode 0755
      owner username
    end
  end
end
