# frozen_string_literal: true
codename = node["chef_postgres"]["release_apt_codename"]
version = node["chef_postgres"]["version"]

::Chef::Log.info("** Install essential build tools **")

package "software-properties-common" do
  options "--no-install-recommends"
end

package "build-essential" do
  options "--no-install-recommends"
end

package "pkg-config" do
  options "--no-install-recommends"
end

package "git" do
  options "--no-install-recommends"
end

package "libproj-dev" do
  options "--no-install-recommends"
end

package "liblwgeom-dev" do
  options "--no-install-recommends"
end

::Chef::Log.info("** Setting up apt_repository to get access to the latest PG versions **")

apt_repository "apt.postgresql.org" do
  uri "http://apt.postgresql.org/pub/repos/apt"
  distribution "#{codename}-pgdg"
  components ["main", version]
  key "https://www.postgresql.org/media/keys/ACCC4CF8.asc"
  action :add
end

::Chef::Log.info("** Installing Postgres **")

package "postgresql-#{version}"
package "postgresql-client-#{version}"
package "postgresql-server-dev-#{version}"
package "postgresql-contrib-#{version}"
package "postgis"
package "postgresql-#{version}-postgis-2.3"
package "postgresql-#{version}-citus"
package "postgresql-#{version}-partman"
package "postgresql-#{version}-repack"
package "postgresql-#{version}-repmgr"

apt_repository "debian" do
  uri "http://ftp.us.debian.org/debian"
  distribution "testing"
  components %w(main contrib)
  key "7638D0442B90D010"
  keyserver "keyserver.ubuntu.com"
  action :add
end

service "stop_postgres" do
  action :stop
  service_name "postgresql"
  notifies :run, "ruby_block[log_stop_pg]", :before
end

package "libprotobuf-c-dev" do
  version "1.2.*"
  options "--no-install-recommends"
end

directory "/var/lib/apt/lists/" do
  recursive true
  action :delete
end

bash "compile_decoderbufs" do
  action :run
  code <<-EOF_CDB
  git clone https://github.com/debezium/postgres-decoderbufs -b v0.5.1 --single-branch
  cd /postgres-decoderbufs
  make && make install
  cd /
  rm -rf postgres-decoderbufs
  EOF_CDB
  notifies :run, "ruby_block[log_compile_decoderbufs]", :before
end

bash "compile_hypopg" do
  action :run
  code <<-EOF_CDB
  git clone https://github.com/dalibo/hypopg.git -b master --single-branch
  cd /hypopg
  make install
  cd /
  rm -rf hypopg
  EOF_CDB
  notifies :run, "ruby_block[log_compile_hypopg]", :before
end


