This cookbook is designed to make it easy to install Postgres 9.1+ on an EC2 Ubuntu instance using Chef or Amazon Opsworks version 12+.

The root recipes are chef_postgres::master and chef_postgres::standby. Set up the master first. This will create a pg_basebackup dump that is uploaded to S3 (partially using the server_name in the S3 path) along with the settings required for the recovery.conf file on the standby.

Once the master is set up, run chef_postgres::standby. This grabs the backup from S3 and uses this to deploy the standby.

The data_device is for the data drive added to the machine. When you add this in Aws match the last letter from the device name.  i.e.
Aws drop down option "/dev/sdk" Translates to "/dev/xvdk". It will always be xvd you just have to change the last letter to match. The default is listed below.   

To change the default settings, pass in custom JSON.  These are the defaults:

```
{
  "chef_postgres":  {
    "server_name": "default",
    "release_apt_codename": "codename_reported_by_ec2",
    "version": "9.6",
    "workload": "oltp",
    "data_device": "/dev/xvdl"
    "s3":  {
      "region": "",
      "bucket": "",
      "access_key_id": "",
      "secret_access_key": ""
    }
  }  
}
```

For workload, the options are:

"dw" - Data Warehouse
  * Generally I/O or RAM intensive, though aggregate queries can use a lot of CPU
  * Large bulk inserts
  * Large complex reporting queries
  * Also called "Business Intelligence" or "BI"

"oltp" - Online Transaction Processing
  * Generally CPU or I/O intensive
  * DB can be slightly larger than RAM
  * Writes are usually small
  * Some long transactions and complex read queries

"web" - Web Application
  * Generally CPU or I/O intensive
  * DB much smaller than RAM
  * Mostly simple queries

"mixed" - Mixed DW and OLTP characteristics
  * A generic workhorse

"desktop" - Not a dedicated database
  * A dev environment
