# frozen_string_literal: true
chef_gem "aws-sdk" do
  compile_time true
end
require "aws-sdk"

include_recipe "chef_postgres::log_output"

repl_user = node["chef_postgres"]["vars"]["repl_user"]
repl_pass = node["chef_postgres"]["vars"]["repl_pass"]
backup_dir = node["chef_postgres"]["pg_config"]["backup_directory"]

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
end

bash "create_base_backup" do
  code <<-EOF_CBB
  rm -rf #{backup_dir}/base_backup/*
  pg_basebackup -d 'host=localhost user=#{repl_user} password=#{repl_pass}' -D #{backup_dir}/base_backup --xlog-method=stream
  tar -C #{backup_dir} -czf #{backup_dir}/base_backup.tgz #{backup_dir}/base_backup/  
  EOF_CBB
  action :run
  notifies :run, "ruby_block[log_create_base_backup]", :before
end

ruby_block "s3_upload_backup" do
  block do
    ::Chef::Provider::UploadFile.call(node,
      { bucket: node["chef_postgres"]["s3"]["bucket"],
        source: "#{backup_dir}/base_backup.tgz" })
  end
end