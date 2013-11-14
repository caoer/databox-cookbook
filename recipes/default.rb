#
# Cookbook Name:: databox
# Recipe:: default
#
#

if node["databox"]["databases"]["postgresql"].any?
  include_recipe "databox::postgresql"
end
