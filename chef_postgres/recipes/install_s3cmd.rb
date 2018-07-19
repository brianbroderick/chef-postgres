
template "s3cmd_aws.conf" do
  owner "ubuntu"
  group "ubuntu"
  path "/home/ubuntu/.s3cfg"
  source "s3cmd_aws_conf.erb"
  variables({ config: { aws_access_key: node["chef_postgres"]["s3"]["access_key_id"],
                        aws_secret_key: node["chef_postgres"]["s3"]["secret_access_key"] } })
end
