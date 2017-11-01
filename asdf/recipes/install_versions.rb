include_recipe "asdf::log_output"

bash "install_erlang" do  
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  user "ubuntu"
  code "#{node["asdf"]["asdf_location"]} install erlang 20.0"
  notifies :run, "ruby_block[install_erlang]", :before      
end

bash "install_elixir" do 
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  user "ubuntu" 
  code "#{node["asdf"]["asdf_location"]} install elixir 1.5.1"
  notifies :run, "ruby_block[install_elixir]", :before      
end

bash "install_ruby" do  
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  user "ubuntu"
  code "#{node["asdf"]["asdf_location"]} install ruby 2.4.2"
  notifies :run, "ruby_block[install_ruby]", :before       
end

bash "install_hex" do 
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  user "ubuntu"
  code "/home/ubuntu/.asdf/shims/mix local.hex --force"
  notifies :run, "ruby_block[install_ruby]", :before
end
