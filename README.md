# Yummy-Recipes-Packer

This repository contains packer script which launches *AMI* image on Amazon Web Services. In order for you to run this script, you would need to provide it with your *AWS Access Key* and *AWS Secret Key* as *Environment Variables*:

`export aws_access_key="your aws access key"`

`export aws_secret_key="your aws secret key"`

After that you can successfully run the *packer* file as follows:

`packer build packer-yummy-recipes.json`

This will create an AMI on AWS which will have **Yummy-Recipes API** up and running on **port 80**. You can launch it by selecting the **services** tab (*top-right*), and than selecting **EC2** service under ***Compute***. After that, you can select the **Launch Instance** button and select **My AMIs** located on the left panel. You will see an AMI named **yummy-recipes** followed by some numbers (these are timestamp numbers). You can than set **Security Groups**, and launch the instance. To see the app running, just copy the **public IPv4** address of that instance into your browser, and ***VOILA***!
