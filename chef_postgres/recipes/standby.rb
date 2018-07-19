# frozen_string_literal: true
chef_gem "aws-sdk" do
  compile_time true
end
require "aws-sdk"

node.default["chef_postgres"]["pg_config"]["cluster_type"] = "hot_standby" # opts: standalone, warm_standby, hot_standby
node.default["chef_postgres"]["pg_config"]["pg_node"] = "standby" # opts: master, standby

backup_dir = node["chef_postgres"]["pg_config"]["backup_directory"]

include_recipe "chef_postgres::log_output"
include_recipe "chef_postgres::ubuntu_packages"
include_recipe "chef_postgres::install_s3cmd"
include_recipe "chef_postgres::config_postgres"
include_recipe "chef_postgres::security"

ruby_block "s3_download_backup" do
  block do
    ::Chef::Provider::DownloadFile.call(node,
      { bucket: node["chef_postgres"]["s3"]["bucket"],
        file: "base_backup.tgz",
        destination: "#{backup_dir}/base_backup.tgz" })
  end
end

bash "unzip_base_backup" do
  code <<-EOF_CBB
  tar -xvzf #{backup_dir}/base_backup.tgz
  chown -R postgres:postgres #{backup_dir}/base_backup/
  EOF_CBB
  notifies :run, "ruby_block[log_unzip_base_backup]", :before
end

bash "move_backup_directory" do
  action :run
  code <<-EOF_MDD
  mv #{backup_dir}/base_backup/recovery_conf.source #{node["chef_postgres"]["pg_config"]["data_directory"]}/recovery.conf
  mv #{backup_dir}/base_backup/* #{node["chef_postgres"]["pg_config"]["data_directory"]}
  EOF_MDD
  user "postgres"
  notifies :run, "ruby_block[log_move_backup_directory]", :before
end

service "start_postgres" do
  action :start
  service_name "postgresql"
  notifies :run, "ruby_block[log_start_pg]", :before
end
