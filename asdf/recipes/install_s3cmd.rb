
template "s3cmd_aws.conf" do
  owner "ubuntu"
  group "ubuntu"
  path "~/.s3cfg"
  source "s3cmd_aws_conf.erb"
  variables({ config: { aws_access_key: node["asdf"]["etc_environment"]["AWS_ACCESS_KEY_ID"],
                        aws_secret_key: node["asdf"]["etc_environment"]["AWS_SECRET_ACCESS_KEY"] } })
end
