include_recipe "asdf::log_output"

bash "install_hex" do 
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  user "ubuntu"
  code "/home/ubuntu/.asdf/shims/mix local.hex --force"
  notifies :run, "ruby_block[install_hex]", :before
end

bash "root_install_hex" do 
  code "/root/.asdf/shims/mix local.hex --force"
  notifies :run, "ruby_block[install_hex]", :before
end