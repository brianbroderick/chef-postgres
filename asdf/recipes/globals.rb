include_recipe "asdf::log_output"

bash "global_erlang" do  
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  user "ubuntu"  
  code "#{node["asdf"]["asdf_location"]} global erlang #{node["asdf"]["erlang_version"]}"	
  notifies :run, "ruby_block[global_erlang]", :before      		
end		
		
bash "root_global_erlang" do  		
  code "#{node["asdf"]["root_asdf_location"]} global erlang #{node["asdf"]["erlang_version"]}"
  notifies :run, "ruby_block[global_erlang]", :before      
end

bash "global_elixir" do  
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  user "ubuntu"  
  code "#{node["asdf"]["asdf_location"]} global elixir #{node["asdf"]["elixir_version"]}"		 
  notifies :run, "ruby_block[global_elixir]", :before      		
end		
		
bash "root_global_elixir" do  		
  code "#{node["asdf"]["root_asdf_location"]} global elixir #{node["asdf"]["elixir_version"]}"
  notifies :run, "ruby_block[global_elixir]", :before      
end

bash "global_ruby" do  
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  user "ubuntu"  
  code "#{node["asdf"]["asdf_location"]} global ruby #{node["asdf"]["ruby_version"]}"
  notifies :run, "ruby_block[global_ruby]", :before       		
end		
		
bash "root_global_ruby" do  		
  code "#{node["asdf"]["root_asdf_location"]} global ruby #{node["asdf"]["ruby_version"]}"
  notifies :run, "ruby_block[global_ruby]", :before       
end