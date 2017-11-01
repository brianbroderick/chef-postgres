include_recipe "asdf::log_output"

bash "install_erlang" do  
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  user "ubuntu"
  code "#{node["asdf"]["asdf_location"]} install erlang #{node["asdf"]["erlang_version"]}"
  notifies :run, "ruby_block[install_erlang]", :before      
end

bash "root_install_erlang" do  
  code "#{node["asdf"]["root_asdf_location"]} install erlang #{node["asdf"]["erlang_version"]}"
  notifies :run, "ruby_block[install_erlang]", :before      
end

bash "install_elixir" do 
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  user "ubuntu" 
  code "#{node["asdf"]["asdf_location"]} install elixir #{node["asdf"]["elixir_version"]}"
  notifies :run, "ruby_block[install_elixir]", :before      
end

bash "root_install_elixir" do 
  code "#{node["asdf"]["root_asdf_location"]} install elixir #{node["asdf"]["elixir_version"]}"
  notifies :run, "ruby_block[install_elixir]", :before      
end

bash "install_ruby" do  
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  user "ubuntu"
  code "#{node["asdf"]["asdf_location"]} install ruby #{node["asdf"]["ruby_version"]}"
  notifies :run, "ruby_block[install_ruby]", :before       
end

bash "root_install_ruby" do  
  code "#{node["asdf"]["root_asdf_location"]} install ruby #{node["asdf"]["ruby_version"]}"
  notifies :run, "ruby_block[install_ruby]", :before       
end