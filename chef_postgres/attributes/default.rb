# frozen_string_literal: true

default["chef_postgres"]["server_name"] = "default"
default["chef_postgres"]["release_apt_codename"] = node["lsb"]["codename"]
default["chef_postgres"]["version"] = "9.6"
default["chef_postgres"]["rh_version"] = node["chef_postgres"]["version"].gsub(/[^0-9]/, "")
default["chef_postgres"]["workload"] = "oltp"
default["chef_postgres"]["data_device"] = "/dev/xvdl"

version = node["chef_postgres"]["version"]

default["chef_postgres"]["pg_config"]["config_directory"] = "/etc/postgresql/#{version}/main"
default["chef_postgres"]["pg_config"]["original_data_directory"] = "/var/lib/postgresql/#{version}/main"
default["chef_postgres"]["pg_config"]["data_directory_on_separate_drive"] = true
default["chef_postgres"]["pg_config"]["data_directory"] = if node["chef_postgres"]["pg_config"]["data_directory_on_separate_drive"]
                                                                 "/mnt/data/postgresql/#{version}/main"
                                                               else
                                                                 node["chef_postgres"]["pg_config"]["original_data_directory"]
                                                               end
default["chef_postgres"]["pg_config"]["backup_directory"] = if node["chef_postgres"]["pg_config"]["data_directory_on_separate_drive"]
                                                                 "/mnt/data/backups"
                                                               else
                                                                 "/backups"
                                                               end
default["chef_postgres"]["pg_config"]["scripts_directory"] = if node["chef_postgres"]["pg_config"]["data_directory_on_separate_drive"]
                                                                "/mnt/data/scripts"
                                                              else
                                                                "/scripts"
                                                              end


_, pg_pass, = ::Chef::Provider::DbUser.call(node, "pg_login")
admin_user, admin_pass, admin_is_generated = ::Chef::Provider::DbUser.call(node, "admin_login")
repl_user, repl_pass, = ::Chef::Provider::DbUser.call(node, "repl_login")

default["chef_postgres"]["vars"]["pg_pass"] = pg_pass
default["chef_postgres"]["vars"]["admin_user"] = admin_user
default["chef_postgres"]["vars"]["admin_pass"] = admin_pass
default["chef_postgres"]["vars"]["admin_is_generated"] = admin_is_generated
default["chef_postgres"]["vars"]["repl_user"] = repl_user
default["chef_postgres"]["vars"]["repl_pass"] = repl_pass
default["chef_postgres"]["vars"]["admin_login_path"] = "/etc/postgresql/#{version}/main/admin_login"
default["chef_postgres"]["vars"]["user_created"] = ::UserCreated.call(node)

default["sysctl"]["params"]["vm"]["swappiness"] = 1

# Redislog
default["chef_postgres"]["libs"]["shared"] = "decoderbufs"
default["chef_postgres"]["libs"]["redislog_hosts"] = ""
