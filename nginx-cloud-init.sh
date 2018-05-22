#!/bin/bash

setupNginxServer () {
  printf '=================================== Setting up Nginx server ============================================ \n'

  createNginxSettingFile
  sudo mv /home/ubuntu/nginx-yummy-recipes /etc/nginx/sites-available/
  sudo ln -s /etc/nginx/sites-available/nginx-yummy-recipes /etc/nginx/sites-enabled
  sudo nginx -t
  sudo systemctl restart nginx

  sudo ufw allow 'Nginx Full'
}

# Create Nginx settings file that will connect to the app
createNginxSettingFile () {
  ipaddress=$(curl "http://169.254.169.254/latest/meta-data/public-ipv4")
  cat > /home/ubuntu/nginx-yummy-recipes <<EOF
server {
    listen 80;
    server_name ${ipaddress};

    location / {
        include uwsgi_params;
        uwsgi_pass unix:/home/ubuntu/Yummy-Recipes/Yummy-Recipes-Ch3/yummy-recipes.sock;
    }
}
EOF
}

setupNginxServer
