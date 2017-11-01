template "/etc/environment1" do
  source "environment.erb"
  mode 0644
  owner "root"
  group "root"
  variables({ :environment => node['asdf']['etc_environment'] })
end 