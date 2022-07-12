#!/bin/bash

# using a function so that commands will work when executed in sub shell
function deploy_wordpress() {

export AWS_DEFAULT_REGION=us-east-1

sudo yum install -y jq

password=$(aws secretsmanager get-secret-value --secret-id main-rds-password --query 'SecretString' --output text | jq .password | tr -d '"')

username=$(aws rds describe-db-instances --db-instance-identifier wordpress --query DBInstances[0] --output json | jq .MasterUsername | tr -d '"')

database_name=$(aws rds describe-db-instances --db-instance-identifier wordpress --query DBInstances[0] --output json | jq .DBName | tr -d '"')

db_host=$(aws rds describe-db-instances --db-instance-identifier wordpress --query DBInstances[0] --output json | jq .Endpoint.Address | tr -d '"')

unique_keys_salts=$(aws secretsmanager get-secret-value --secret-id keys-salts --query 'SecretString' --output text)

# installing apache
sudo yum install -y httpd;

# starting apache
sudo service httpd start;

# downloading worpdress setup files
sudo wget https://wordpress.org/latest.tar.gz;

# unzipping wordpress setup files
sudo tar -xzf latest.tar.gz;

#Copy wp-config file to wordpress folder
sudo cp wp-config.php /wordpress/;

# changing to wordpress dir
cd /wordpress/;

# passing database name to config file
sudo sed -i "s/database_name_here/${database_name}/g" wp-config.php,

# passing username to config file
sudo sed -i "s/username_here/${username}/g" wp-config.php,

# passing password to config file
sudo sed -i "s/password_here/${password}/g" wp-config.php,

# passing endpoint to config file
sudo sed -i "s/localhost/db_host/g" wp-config.php,

# passing unique_keys_salts to config file
sudo sed -i "s/unique_keys_salts/${unique_keys_salts}/g" wp-config.php,

# installing wordpress dependcies 
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2;

# copying wordpress setup files to html dir
sudo cp -r * /var/www/html/;

# restarting apache web server
sudo service httpd restart;
}

deploy_wordpress