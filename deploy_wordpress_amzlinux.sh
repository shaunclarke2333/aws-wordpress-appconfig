#!/bin/bash

# using a function so that commands will work when executed in sub shell
function deploy_wordpress() {

# aws region environment variable for aws cli
export AWS_DEFAULT_REGION=us-east-1;

# installing jq to parse json output returned from aws cli queries
sudo yum install -y jq;

# Getting rds password from secrets manager and assigning to password variable
password=$(aws secretsmanager get-secret-value --secret-id main-rds-password --query 'SecretString' --output text | jq .password | tr -d '"')

# Getting rds username from rds instance and assigning to username variable
username=$(aws rds describe-db-instances --db-instance-identifier wordpress --query DBInstances[0] --output json | jq .MasterUsername | tr -d '"')

# Getting rds database name from rds instance and assigning to database_name variable
database_name=$(aws rds describe-db-instances --db-instance-identifier wordpress --query DBInstances[0] --output json | jq .DBName | tr -d '"')

# Getting rds endpoint from db instance and assigning to password variable
db_host=$(aws rds describe-db-instances --db-instance-identifier wordpress --query DBInstances[0] --output json | jq .Endpoint.Address | tr -d '"')

# Getting wordpress keys and salts auth_key from secrets manager and assigning to variable
auth_key=$(aws secretsmanager get-secret-value --secret-id keys --query 'SecretString' --output text | jq .authkey | tr -d '"')

# Getting wordpress keys and salts secure suth key from secrets manager and assigning to variable
secure_auth_key=$(aws secretsmanager get-secret-value --secret-id keys --query 'SecretString' --output text | jq .secureauthkey | tr -d '"')

# Getting wordpress keys and salts logged in key from secrets manager and assigning to variable
logged_in_key=$(aws secretsmanager get-secret-value --secret-id keys --query 'SecretString' --output text | jq .loggedinkey | tr -d '"')

# Getting wordpress keys and salts nonce key from secrets manager and assigning to variable
nonce_key=$(aws secretsmanager get-secret-value --secret-id keys --query 'SecretString' --output text | jq .noncekey | tr -d '"')

# Getting wordpress keys and salts auth_salt from secrets manager and assigning to variable
auth_salt=$(aws secretsmanager get-secret-value --secret-id keys --query 'SecretString' --output text | jq .authsalt | tr -d '"')

# Getting wordpress keys and salts secure auth salts from secrets manager and assigning to variable
secure_auth_salt=$(aws secretsmanager get-secret-value --secret-id keys --query 'SecretString' --output text | jq .secureauthsalt | tr -d '"')

# Getting wordpress keys and salts logged in salts from secrets manager and assigning to variable
logged_in_salt=$(aws secretsmanager get-secret-value --secret-id keys --query 'SecretString' --output text | jq .loggedinsalt | tr -d '"')

# Getting wordpress keys and salts nonc salt from secrets manager and assigning to variable
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

# changing to opt directory
cd ../opt;

# download wordpress cli installer
sudo curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar;

# changing permissions to make file executable
sudo chmod +x wp-cli.phar;

# moving file to /usr/local/bin/wp
sudo mv wp-cli.phar /usr/local/bin/wp;

# changing to wordpress directory
cd ../wordpress;

#Getting wordpress admin username and password from secrets manager
wp-admin_name=$(aws secretsmanager get-secret-value --secret-id wp-admin-password --query 'SecretString' --output text | jq .name | tr -d '"')
wp-admin_password=$(aws secretsmanager get-secret-value --secret-id wp-admin-password --query 'SecretString' --output text | jq .password | tr -d '"')

# Using wordpress CLI command to install wordpress and complete setup
wp core install --url="wordpress.shaunsawslab.link" --title="Shauns terraform automated deployment" --admin_user="${wp-admin_name}" \
--admin_password="${wp-admin_password}" --admin_email="shaunclarke43@gmail.com"

}

# calling funcrion
deploy_wordpress
