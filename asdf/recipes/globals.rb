include_recipe "asdf::log_output"

bash "global_erlang" do  
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  user "ubuntu"  
  code "#{node["asdf"]["asdf_location"]} global erlang 20.0"
  notifies :run, "ruby_block[global_erlang]", :before      
end

bash "root_global_erlang" do  
  code "#{node["asdf"]["root_asdf_location"]} global erlang 20.0"
  notifies :run, "ruby_block[global_erlang]", :before      
end

bash "global_elixir" do  
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  user "ubuntu"  
  code "#{node["asdf"]["asdf_location"]} global elixir 1.5.1"
  notifies :run, "ruby_block[global_elixir]", :before      
end

bash "root_global_elixir" do  
  code "#{node["asdf"]["root_asdf_location"]} global elixir 1.5.1"
  notifies :run, "ruby_block[global_elixir]", :before      
end

bash "global_ruby" do  
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  user "ubuntu"  
  code "#{node["asdf"]["asdf_location"]} global ruby 2.4.2"
  notifies :run, "ruby_block[global_ruby]", :before       
end

bash "root_global_ruby" do  
  code "#{node["asdf"]["root_asdf_location"]} global ruby 2.4.2"
  notifies :run, "ruby_block[global_ruby]", :before       
end