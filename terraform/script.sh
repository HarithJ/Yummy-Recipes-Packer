#!/bin/sh
sudo sed -i "/baseURL/c\  baseURL: 'http://api.$1/api/v1.0/'" /var/project/Yummy-Recipes-CP4/src/axiosSettings.js
