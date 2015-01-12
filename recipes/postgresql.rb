#
# Cookbook Name:: databox
# Recipe:: postgresql
#
# Install Postgresql and create specified databases and users.
#

file "remove deprecated Pitti PPA apt repository" do
  action :delete
  path "/etc/apt/sources.list.d/pitti-postgresql-ppa"
end

bash "adding postgresql repo" do
  user "root"
  code <<-EOC
  echo "deb http://apt.postgresql.org/pub/repos/apt/ #{node['lsb']['codename']}-pgdg main" > /etc/apt/sources.list.d/pgdg.list
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  EOC
  action :run
end

execute "run apt-get update" do
  command 'apt-get update'
  action :run
end

packages = %w(
  libpq-dev
  git-core 
  curl 
  zlib1g-dev
  libssl-dev 
  libreadline-dev 
  libyaml-dev 
  libsqlite3-dev 
  sqlite3 
  libxml2-dev 
  libxslt1-dev
  postgresql-contrib
)

packages.each { |name| package name }

package "postgresql-#{node['postgresql']['version']}"

root_password = node["databox"]["db_root_password"]
if root_password
  Chef::Log.info %(Set node["postgresql"]["password"]["postgres"] attributes to node["databox"]["db_root_password"])
  node.set["postgresql"]["password"]["postgres"] = root_password
end

include_recipe "postgresql::client"
include_recipe "postgresql::server"
include_recipe "database::postgresql"

#TODO Chef 11 compat?
node.set['postgresql']['pg_hba'] = [
  {:type => 'local', :db => 'all', :user => 'postgres', :addr => nil, :method => 'ident'},
  {:type => 'local', :db => 'all', :user => 'all', :addr => nil, :method => 'md5'},
  {:type => 'host', :db => 'all', :user => 'all', :addr => '127.0.0.1/32', :method => 'md5'},
  {:type => 'host', :db => 'all', :user => 'all', :addr => '::1/128', :method => 'md5'}
]


postgresql_connection_info = {
  :host => "localhost",
  :port => node['postgresql']['config']['port'],
  :username => 'postgres',
  :password => node['postgresql']['password']['postgres']
}

node["databox"]["databases"]["postgresql"].each do |entry|

  postgresql_database entry["database_name"] do
    connection postgresql_connection_info
    template entry["template"] if entry["template"]
    encoding entry["encoding"] if entry["encoding"]
    collation entry["collation"] if entry["collation"]
    connection_limit entry["connection_limit"] if entry["connection_limit"]
    owner entry["owner"] if entry["owner"]
    action :create
  end

  postgresql_database_user entry["username"] do
    connection postgresql_connection_info
    action [:create, :grant]
    password(entry["password"])           if entry["password"]
    database_name(entry["database_name"]) if entry["database_name"]
    privileges(entry["privileges"])       if entry["privileges"]
  end

end
