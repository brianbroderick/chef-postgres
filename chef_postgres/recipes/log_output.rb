# frozen_string_literal: true
### Logging ###

ruby_block "log_data_directory" do
  block { ::Chef::Log.info("** Creating Data Directory **") }
  action :nothing
end

ruby_block "log_backup_directory" do
  block { ::Chef::Log.info("** Creating Backup Directory **") }
  action :nothing
end

ruby_block "log_copy_files" do
  block { ::Chef::Log.info("** Copying Files **") }
  action :nothing
end

ruby_block "log_stop_pg" do
  block { ::Chef::Log.info("** Stop Postgres **") }
  action :nothing
end

ruby_block "log_move_data_directory" do
  block { ::Chef::Log.info("** Moving Data Directory **") }
  action :nothing
end

ruby_block "log_start_pg" do
  block { ::Chef::Log.info("** Starting Postgres **") }
  action :nothing
end

ruby_block "log_create_admin" do
  block { ::Chef::Log.info("** Create Admin User **") }
  action :nothing
end

ruby_block "log_create_repl" do
  block { ::Chef::Log.info("** Create Repl User **") }
  action :nothing
end

ruby_block "log_create_base_backup" do
  block { ::Chef::Log.info("** Create Base Backup **") }
  action :nothing
end

ruby_block "log_unzip_base_backup" do
  block { ::Chef::Log.info("** Unzip Base Backup and Extract to Data Dir **") }
  action :nothing
end

ruby_block "log_move_backup_directory" do
  block { ::Chef::Log.info("** Moving Backup Directory to Data Directory **") }
  action :nothing
end

ruby_block "log_compile_decoderbufs" do
  block { ::Chef::Log.info("** Compile Decoderbufs **") }
  action :nothing
end

ruby_block "log_compile_hypopg" do
  block { ::Chef::Log.info("** Compile HypoPG **") }
  action :nothing
end

ruby_block "log_set_iptables" do
  block { ::Chef::Log.info("** Set IPTables **") }
  action :nothing
end
