#!/bin/bash

# using a function so that commands will work when executed in sub shell
function deploy_wordpress() {

export AWS_DEFAULT_REGION=us-east-1;

sudo yum install -y jq;

password=$(aws secretsmanager get-secret-value --secret-id main-rds-password --query 'SecretString' --output text | jq .password | tr -d '"')

username=$(aws rds describe-db-instances --db-instance-identifier wordpress --query DBInstances[0] --output json | jq .MasterUsername | tr -d '"')

database_name=$(aws rds describe-db-instances --db-instance-identifier wordpress --query DBInstances[0] --output json | jq .DBName | tr -d '"')

db_host=$(aws rds describe-db-instances --db-instance-identifier wordpress --query DBInstances[0] --output json | jq .Endpoint.Address | tr -d '"')

auth_key=$(aws secretsmanager get-secret-value --secret-id keys --query 'SecretString' --output text | jq .authkey | tr -d '"')

secure_auth_key=$(aws secretsmanager get-secret-value --secret-id keys --query 'SecretString' --output text | jq .secureauthkey | tr -d '"')

logged_in_key=$(aws secretsmanager get-secret-value --secret-id keys --query 'SecretString' --output text | jq .loggedinkey | tr -d '"')

nonce_key=$(aws secretsmanager get-secret-value --secret-id keys --query 'SecretString' --output text | jq .noncekey | tr -d '"')

auth_salt=$(aws secretsmanager get-secret-value --secret-id keys --query 'SecretString' --output text | jq .authsalt | tr -d '"')

secure_auth_salt=$(aws secretsmanager get-secret-value --secret-id keys --query 'SecretString' --output text | jq .secureauthsalt | tr -d '"')

logged_in_salt=$(aws secretsmanager get-secret-value --secret-id keys --query 'SecretString' --output text | jq .loggedinsalt | tr -d '"')

nonce_salt=$(aws secretsmanager get-secret-value --secret-id keys --query 'SecretString' --output text | jq .noncesalt | tr -d '"')

# installing apache
sudo yum install -y httpd;

# starting apache
sudo service httpd start;

# downloading worpdress setup files
sudo wget https://wordpress.org/latest.tar.gz;

# unzipping wordpress setup files
sudo tar -xzf latest.tar.gz;

# changing to aws-wordpress-directory
cd aws-wordpress-appconfig/;

# passing database name to config file
sudo sed -i "s/database_name_here/${database_name}/g" wp-config.php;

# passing username to config file
sudo sed -i "s/username_here/${username}/g" wp-config.php;

# passing password to config file
sudo sed -i "s/password_here/${password}/g" wp-config.php;

# passing endpoint to config file
sudo sed -i "s/localhost/${db_host}/g" wp-config.php;

# passing unique_keys_salts to config file
sudo sed -i "s/auth_key/${auth_key}/" wp-config.php;
sudo sed -i "s/key_secure/${secure_auth_key}/" wp-config.php;
sudo sed -i "s:logged_in_key:${logged_in_key}:" wp-config.php;
sudo sed -i "s%nonce_key%${nonce_key}%" wp-config.php;
sudo sed -i "s/auth_salt/${auth_salt}/" wp-config.php;
sudo sed -i "s/salt_secure/${secure_auth_salt}/" wp-config.php;
sudo sed -i "s:logged_in_salt:${logged_in_salt}:" wp-config.php;
sudo sed -i "s/nonce_salt/${nonce_salt}/" wp-config.php;

#Copy wp-config file to wordpress folder
sudo cp wp-config.php /wordpress/;

# changing to wordpress dir
cd ../wordpress/;

# installing wordpress dependcies 
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2;

# copying wordpress setup files to html dir
sudo cp -r * /var/www/html/;

# restarting apache web server
sudo service httpd restart;
}

deploy_wordpress