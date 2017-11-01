include_recipe "asdf::log_output"

directory "#{node['asdf']['ubuntu_home_dir']}/.asdf" do  
  action :create
  owner "ubuntu"
  group "ubuntu"  
  recursive true
end

git "asdf" do
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  repository "https://github.com/asdf-vm/asdf.git"
  checkout_branch "v0.3.0"
  destination "#{node['asdf']['ubuntu_home_dir']}/.asdf"
  user "ubuntu"
  enable_checkout false
  action :sync
  notifies :run, "ruby_block[installing_asdf]", :before
end

bash "add_to_bashrc" do  
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  user "ubuntu"
  code "echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc
        source ~/.bashrc"
  notifies :run, "ruby_block[add_asdf_to_bashrc]", :before
end

bash "add_plugins" do
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  user "ubuntu"
  code "#{node["asdf"]["asdf_location"]} plugin-add erlang
        #{node["asdf"]["asdf_location"]} plugin-add elixir
        #{node["asdf"]["asdf_location"]} plugin-add ruby"
  notifies :run, "ruby_block[add_plugins]", :before      
end
