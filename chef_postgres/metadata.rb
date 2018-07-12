# frozen_string_literal: true
name "chef_postgres"
maintainer "Brian Broderick"
maintainer_email "brianbroderick19 at gmail dot com"
license "MIT"
description "Install and configure Postgresql on Amazon EC2"
long_description "Install and configure Postgresql on Amazon EC2"
version "0.1.0"
chef_version ">= 12.1" if respond_to?(:chef_version)
issues_url "https://github.com/brianbroderick/chef_postgres/issues" if respond_to?(:issues_url)
source_url "https://github.com/brianbroderick/chef_postgres" if respond_to?(:source_url)
supports "ubuntu"
depends "sysctl"
#depends "aws"
