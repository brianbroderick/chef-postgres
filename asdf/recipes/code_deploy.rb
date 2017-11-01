include_recipe "asdf::log_output"

bash "download_codedeploy" do  
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  cwd "/home/ubuntu"
  user "ubuntu"  
  code "wget https://aws-codedeploy-#{node['asdf']['aws_region']}.s3.amazonaws.com/latest/install
  chmod +x ./install"
  notifies :run, "ruby_block[install_codedeploy]", :before      
end

bash "install_codedeploy" do
  cwd "/home/ubuntu"
  code "./install auto
        rm ./install
        service codedeploy-agent start"
end

# where the code will live
directory "/code" do  
  action :create
  owner "ubuntu"
  group "ubuntu"  
  recursive true
end
