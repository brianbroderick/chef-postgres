include_recipe "chef_postgres::log_output"

# For redislog
package "libssl-dev"
package "libkrb5-dev"
package "libhiredis-dev"
package "redis-server"

bash "compile_redislog" do
  action :run
  code <<-EOF_CDB
  git clone https://github.com/brianbroderick/redislog.git -b master --single-branch
  cd /redislog
  make && make install
  cd /
  rm -rf redislog
  EOF_CDB
  notifies :run, "ruby_block[log_compile_redislog]", :before
end

service "stop_redis" do
  action :stop
  service_name "redis-server"
  notifies :run, "ruby_block[log_stop_redis]", :before
end
