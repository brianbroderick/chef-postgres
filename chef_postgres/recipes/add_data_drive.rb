
# aws_access_key_id = node["chef_postgres"]["s3"]["AWS_ACCESS_KEY_ID"]
# aws_secret_access_key = node["chef_postgres"]["s3"]["AWS_ACCESS_KEY_ID"]


#include_recipe "aws::ebs_volume"

# aws_ebs_volume "data_volume" do
#   aws_access_key node["chef_postgres"]["s3"]["access_key_id"]
#   aws_secret_access_key node["chef_postgres"]["s3"]["secret_access_key"]
#   size 3400
#   device "/dev/sdi"
#   action [ :attach ]
# end

device = node["chef_postgres"]["data_device"]

execute "format_vol" do
  command "sudo mkfs.ext3 #{device}"
  action :run
  not_if {File.exists?("/mnt/data")}
end
execute "mkdir_mnt" do
  command "sudo mkdir /mnt/data"
  action :run
  not_if {File.exists?("/mnt/data")}
end
mount "/mnt/data" do
  device "#{device}"  # "/dev/xvdl"
  fstype "ext3"
  action [:mount, :enable]
end

#
# include_recipe "aws"
# data_bag("my_data_bag")
# db = data_bag_item("my_data_bag", "my")
# aws = db['development']['aws']
#
# aws_ebs_volume "db_ebs_volume" do
#   aws_access_key aws['aws_access_key_id']
#   aws_secret_access_key aws['aws_secret_access_key']
#   size 50
#   device "/dev/sdi"
#   action [ :create, :attach ]
# end
