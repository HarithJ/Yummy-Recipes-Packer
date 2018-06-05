# Yummy-Recipes

This repo is there to setup **Yummy Recipes** app. After having completed all the steps mentioned, you will have this kind of architecture:

A VPC that will contain four subnets; two subnets will be public and the other two will be private. The two public subnets will contain one instance of frontend react app each. Both of these instances will be made available through an internet-facing, elastic load balancer. The two private subnets will contain a single instance of API service, which will also be exposed by an internet-facing load balancer. The frontend will be communicating with the API. You would also provide it with your domain name without any prefix, and it will create two routes from it: one with a `www` prefix connecting to frontend, and the other with `api` prefix connecting to the API.

## Launching AMIs

Before we set up the architecture for our app, we would need AMI images that would have our frontend and API running. Lets start by creating AMI for the API (we would be using packer to create AMI), open up the shell and follow these steps:

1. cd into the CP3 folder.

2. export your *AWS Access Key* and *AWS Secret Key* as *Environment Variables*:

`export aws_access_key="your aws access key"`

`export aws_secret_key="your aws secret key"`

3. Run the packer build command:

`packer build packer-yummy-recipes.json`

**You will have an yummy-recipes-api AMI in your AWS account!**

Now, onto creating AMI for the frontend:

1. cd into the CP4 folder.

2. Run the packer build command:

`packer build packer-yummy-recipes-cp4.json`

**You will have an yummy-recipes-frontend AMI in your AWS account!**

## Building the architecture:

To build the architecture of our app, we would be using *Terraform*. Before you get started, you would need to have a *variables* file with the extension of *tfvars*. In that file, you would need to set five variables:
```aws_access_key = "your-aws-access-key"
aws_secret_key = "your-aws-secret-key"
key_name = "key-name-you-want-to-use-for-your-instances"
private_key_path = "the-path-to-your-private-key"
domain_name = "your-domain-name-without-any-prefix"
```

After having set those variables, execute the following in your shell:

1. cd into the terraform folder

2. run the init command:
`terraform init`

3. run the terraform apply command:
`terraform apply -var-file="/path/to/the/terraform/variables/file"`

4. enter `yes` when it prompts you to.

## The last step:

You would have to manually set the `nameservers` from where you had bought your domain so that they point to the correct nameservers and the app would work as expected.
NOTE: It may take upto 24 hours for you domain registrer to update the nameservers.

**Thats it!**

