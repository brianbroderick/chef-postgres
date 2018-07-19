# frozen_string_literal: true
chef_gem "aws-sdk" do
  compile_time true
end
require "aws-sdk"

node.default["chef_postgres"]["pg_config"]["cluster_type"] = "hot_standby" # opts: standalone, warm_standby, hot_standby
node.default["chef_postgres"]["pg_config"]["pg_node"] = "master" # opts: master, standby

include_recipe "chef_postgres::log_output"
include_recipe "chef_postgres::add_data_drive"
include_recipe "chef_postgres::ubuntu_packages"
include_recipe "chef_postgres::install_s3cmd"
include_recipe "chef_postgres::config_postgres"
include_recipe "chef_postgres::security"

version = node["chef_postgres"]["version"]
pg_pass = node["chef_postgres"]["vars"]["pg_pass"]
admin_user = node["chef_postgres"]["vars"]["admin_user"]
admin_pass = node["chef_postgres"]["vars"]["admin_pass"]
admin_is_generated = node["chef_postgres"]["vars"]["admin_is_generated"]
repl_user = node["chef_postgres"]["vars"]["repl_user"]
repl_pass = node["chef_postgres"]["vars"]["repl_pass"]
backup_dir = node["chef_postgres"]["pg_config"]["backup_directory"]
scripts_dir = node["chef_postgres"]["pg_config"]["scripts_directory"]
user_created = node["chef_postgres"]["vars"]["user_created"]

# Build this on the master so the standbys have the right settings
template "recovery_conf.source" do
  group "postgres"
  mode "0640"
  owner "postgres"
  path "#{node["chef_postgres"]["pg_config"]["data_directory"]}/recovery_conf.source"
  source "recovery_conf.erb"
  variables({ config: { username: repl_user,
                        password: repl_pass,
                        hostname: node["ec2"]["local_hostname"],
                        standby: node["chef_postgres"]["pg_config"]["cluster_type"] } })
  not_if { user_created }
end

bash "move_data_directory" do
  action :run
  code <<-EOF_MDD
  echo "Moving data directory" >> /tmp/chef_setup.log
  TIME_DELAY = 0.1
  WAITED = 0
  until [ ! -f /var/lib/postgresql/#{version}/main/postmaster.pid ]; do
    sleep $TIME_DELAY
    $WAITED = $(($WAITED + $TIME_DELAY))
    echo "Waiting for Postgres to Stop. Waited: $WAITED seconds" >> /tmp/chef_setup.log
    if [ $WAITED -gt 15 ]
    then
      echo "Waiting long enough..." >> /tmp/chef_setup.log
      break
    fi
  done
  mv /var/lib/postgresql/#{version}/main/* #{node["chef_postgres"]["pg_config"]["data_directory"]}
  EOF_MDD
  not_if { ::File.exist?("#{node["chef_postgres"]["pg_config"]["data_directory"]}/PG_VERSION") }
  only_if { node["chef_postgres"]["pg_config"]["data_directory_on_separate_drive"] }
  user "postgres"
  not_if { user_created }
  notifies :run, "ruby_block[log_move_data_directory]", :before
end

service "start_postgres" do
  action :start
  service_name "postgresql"
  not_if { user_created }
  notifies :run, "ruby_block[log_start_pg]", :before
end

bash "create_admin_user" do
  action :run
  user "postgres"
  code <<-EOF_CAU
    echo "ALTER USER postgres WITH PASSWORD '#{pg_pass}';" | psql -U postgres -d postgres
    echo "CREATE USER #{admin_user} WITH PASSWORD '#{admin_pass}' SUPERUSER CREATEDB CREATEROLE; CREATE DATABASE #{admin_user} OWNER #{admin_user};" | psql -U postgres -d postgres
  EOF_CAU
  not_if { user_created }
  notifies :run, "ruby_block[log_create_admin]", :before
end

bash "create_repl_user" do
  user "postgres"
  code <<-EOF_CRU
  echo "CREATE USER #{repl_user} WITH PASSWORD '#{repl_pass}' REPLICATION LOGIN CONNECTION LIMIT 4;" | psql -U postgres -d postgres
  EOF_CRU
  not_if { user_created }
  notifies :run, "ruby_block[log_create_repl]", :before
end


bash "create_base_backup" do
    if version == "10"
      code <<-EOF_CBB
      rm -rf #{backup_dir}/base_backup/*
      pg_basebackup -d 'host=localhost user=#{repl_user} password=#{repl_pass}' -D #{backup_dir}/base_backup
      tar -C #{backup_dir} -czf #{backup_dir}/base_backup.tgz #{backup_dir}/base_backup/
      EOF_CBB
      not_if { user_created }
      action :run
      notifies :run, "ruby_block[log_create_base_backup]", :before
    else
      code <<-EOF_CBB
      rm -rf #{backup_dir}/base_backup/*
      pg_basebackup -d 'host=localhost user=#{repl_user} password=#{repl_pass}' -D #{backup_dir}/base_backup --xlog-method=stream
      tar -C #{backup_dir} -czf #{backup_dir}/base_backup.tgz #{backup_dir}/base_backup/
      EOF_CBB
      not_if { user_created }
      action :run
      notifies :run, "ruby_block[log_create_base_backup]", :before
  end
end

ruby_block "s3_upload_backup" do
  block do
    ::Chef::Provider::UploadFile.call(node,
      { bucket: node["chef_postgres"]["s3"]["bucket"],
        source: "#{backup_dir}/base_backup.tgz" })
  end
  not_if { user_created }
end

cookbook_file "Copy backup file" do
  group "ubuntu"
  mode "0775"
  owner "ubuntu"
  path "#{backup_dir}/pg_backup.sh"
  source "pg_backup.sh"
  not_if { user_created }
end

cookbook_file "Copy remove_postgres_logs file" do
  group "ubuntu"
  mode "0775"
  owner "ubuntu"
  path "#{scripts_dir}/remove_postgres_logs.sh"
  source "remove_postgres_logs.sh"
  not_if { user_created }
end

cron "pg_backup.sh" do
  minute "2"
  hour "7"
  user "ubuntu"
  command "#{backup_dir}/pg_backup.sh"
  not_if { user_created }
end

service "restart_postgres" do
  action :restart
  service_name "postgresql"
  notifies :run, "ruby_block[log_restart_pg]", :before
  not_if { user_created }
end

# Do last. If everything works, this keeps things idempotent.
file "record_admin" do
  content "admin user: #{admin_user} password: #{admin_pass} \n repl user: #{repl_user} password: #{repl_pass}"
  group "root"
  mode "0400"
  owner "root"
  path node["chef_postgres"]["vars"]["admin_login_path"]
  not_if { user_created }
  action :create
end
