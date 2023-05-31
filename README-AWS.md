# AWS

## Summary

[AWS](https://aws.amazon.com/) is an IaaS (Infrastructure as a Service) provider that gives us access to dozens of professional infrastructure solutions.  

## Challenges

### Part 1 - Sign up for AWS

1. Head over to the AWS console at https://aws.amazon.com/console/ and create a free AWS account.  If you're prompted to choose between professional and personal, go with personal for now.  

    *You will be asked for a credit card* but we will be staying on the **free tier** so you should not be charged as long as you follow these instructions carefully!  (There are some extensions that will incur nominal charges if you choose to complete them.)

2. Sign in to the Console and log in using the email and password you used to create your account.

    By default, your starting region will be Ohio.  You should see this on the upper right navbar once you log in.  Remember that regions are independent.  What you have in one region is not replicated in another region unless you set that up.  

    Click on the region and change it to a region closest to you geographically.  If you ever log in to AWS and don't see the configurations you expect, always check first to see if you're looking at the correct region!

### Part 2 - IAM

You are currently signed in with your root account.  This account should only be used for billing purposes and setting up your admin group. Search for IAM in services.

1. #### Create an admin group

    - Create a group called `admin` and attach the `AdministratorAccess` policy to it.

2. #### Create users

    - Add both partners as users with Programmatic and Console access.

    - Provide a simple password and make sure that both users will need to change their password upon login.

    - Add both users to the `admin` group.

    - Once you've added both users, you will see a 'success' screen where you'll have the opportunity to download a .csv containing the Access Key ID and Secret Access Key for both.  
    
    - Apply an IAMUserChangePassword to create rules for IAM user passwords.


        **DOWNLOAD THIS FILE!!**  

        This will be the **only** opportunity to get your Secret Access Key. Make sure each partner makes note of their Access Key Id and Secret Access Key.


3. #### Sign in with your new admin user account

    - Sign out of your account and follow the console sign-in link in the CSV to log back in with your admin user and set up your new password.

    - From the Dashboard, you can customize your sign-in link.  If you do, you'll use this new custom name as the Account ID when you log in (before you enter your username and password)

4. #### Create EC2 Instance Profile

    - From the IAM dashboard, create a new **role**

    - This role should be an AWS service entity type with EC2 use case

    - Attach the 'AdministratorAccess-AWSElasticBeanstalk' permission policy

    - Name your role something like aws-elasticbeanstalk-ec2-role (this is the default name for the Elastic Beanstalk EC2 role)

### Part 3 - Elastic Beanstalk

Great, we have an AWS account!  Let's use it.  We'll start by creating a new application with Elastic Beanstalk, which you'll find in the Services menu dropdown.

1. #### Create a new application

    - We're going to deploy the megamarkets app, so name your application appropriately

2. #### Create a production environment

    - We're going to deploy a containerized application, so select Docker as your preconfigured platform.
    - For the current configuation of our Docker containerization, you'll want to change your **Platform Branch** to:

      - `Docker running on 64bit Amazon Linux 2`

    - In order to deploy your initial code, you'll need to zip it up into an archive file.  We should use git to do this. Run the following git command locally in the top level of your application's directory:

      -  `git archive -v -o myMM.zip --format=zip HEAD`

    - Upload this zipped file.

    - On the next page, select the role you created for 'EC2 instance profile'. For the service role, you can select 'Create and use new service role'. You can use an existing service role if you've already created one on this page, but your service role and EC2 instance profile must **not** be the same.

    - There are more optional pages after this one, but we can just click 'Skip to review'.

    - Along with your application, Elastic Beanstalk will automatically generate an environment for you. An *environment* is a collection of AWS resources running an application version. Wait a few minutes while AWS creates an S3 bucket, sets up security groups and spins up your EC2 instance complete with your application running in a docker container.

    - Note that upon creating your first application, the default environment name will be something like "[APPLICATION_NAME]-env". For our purposes, this will suffice, however in practice, it's best to name your environments descriptively to something that easily identifies this as the production environment for the megamarkets application. 
    <br/> <br/>
    In general, you can deploy multiple environments when you need to run multiple versions of your application. For example, you may need a development, staging, and a production environments. In this case, you would want to ensure that your environment names are more descriptive.

    - Once this is complete, open the Dashboard for your new environment and follow the URL at the top to see your application running in the cloud.


### Part 4 - Getting CLI Access to your EC2 instance

Well that wasn't too bad at all.  We've got a server running in the cloud, hosting our full stack React/Redux application.  So, how can we log into this server and check things out from the command line?

We're going to use a network protocol called SSH (Secure Shell).  This will allow us to log in to our EC2 instance across a secure channel.  We'll also be able to log in without having to enter a password.  

*Wait, a secure channel without a password?*

Yep!  SSH allows us to use a **key pair** where the server has a public key and the client has a private key.  When you set up your client with the private key, every login verifies it against the public key.  If it's a match, you're in!  

1. #### Set up your key pair
    - Go to EC2 under the Services menu and select 'Key Pairs'.
    - Create a new key pair and give it a meaningful name like 'mm-ec2-key' and select "pem" as the file format.
    - This will create the public key and download a .pem file to your local machine.  You will want to take this file and place it in your ~/.ssh directory (create this if you don't have one already)
    - Private keys must have tight [file level security](https://www.linux.org/threads/file-permissions-chmod.4124/), so we'll change that using the linux command to 'change mode' on the file
        - `chmod 400 ~/.ssh/mm-ec2-key.pem`
    - Now go over to the Elastic Beanstalk service and open the dashboard for your production environment.
    - Select Configuration -> Security and set your mm-ec2-key up as the EC2 key pair and wait for the environment to update. Updating the environment will most likely prompt AWS to create a new EC2 instance to reflect this security change, so ensure to reference the new EC2 instance for the following steps.
    - Now we can login to our instance from the command line by invoking ssh, providing the private key, and logging in as `ec2-user` (which is the default for new EC2 instances)
        - `ssh -i ~/.ssh/mm-ec2-key.pem ec2-user@your-ec2-public-address`. To find your EC2 Public IPv4 address, go to Services -> EC2 -> Instances, click on your running EC2 instance and in the instance summary, you should find the Public IPv4 address for the EC2 instance.
        - 1st NOTE: When running the above command, if the ssh network request times out, ensure that you are providing the correct Public address for you EC2 Instance. 
        - 2nd NOTE: After running the command, if you are given the following prompt: "Are you sure you want to continue connecting (yes/no/[fingerprint])?" Simply copy and paste the ECDSA key fingerprint given to you in the terminal, and hit Enter.
    - To see your code
        - `cd /var/app/current/`
    - To see your server log files
        - `cd /var/log/eb-docker/containers/eb-current-app/`
    - To see them sorted by date
        - `ls -ltr`

### Part 5 - RDS

Of course, we can't do anything with the application yet.  We'll need to hook up the database first, so we've still got some work to do.

1. #### Create a new RDS instance
    - In order to create a database that isn't tied directly to the lifecycle of our Elastic Beanstalk environment, we'll go back to the Services menu and select RDS.

    - Click "Create Database" to begin the process of generating a AWS hosted database  
    
    - For the database creation method select "Standard Create", for engine type select "PostgreSQL" (v12.8-R1 for consistency with our Docker Image), and for Templates select "Free Tier". 

    - Under Settings, first provide your DB instance with a meaningful name, `mmdb-prod-instance-1`, that indicates what database it will contain and which environment it is for. Second, set the  "Master username" to `mmadmin`. Remember the password that you provide here, as you'll need it when accessing your database from your EC2 instance.

    -  Check 'Include previous generation classes'. Keep the defaults for DB instance size (instance class should be db.t2.micro), Storage type (General Purpose SSD), and Allocated storage (20Gb). Additionally, **Uncheck** "Enable storage autoscaling". This is to ensure that we stay in the free tier. Note that you *could* set up a replica of your database in a separate Availability Zone here (but that could incur a charge).

    - Under "Connectivity", expand the "Additional connectivity configuration" tab to configure more options regarding your RDS securtiy group. In typical production environments, you do not make your database publicly accessible.  They should only be accessible from our EC2 server. We'll follow that rule here.
        - Under "VPC security group", select "Create new" and give the VPC Security group the name `mm-db-sg`. Then select the availability zone closest to you. Leave the Database port as the default for PostgresQL databases (`5432`).

    - Finally, expand the "Additional Configuration" tab. Name your database `mmdb` under "Initial Database Name". Additionally, **Uncheck** "Enable automatic backups" to ensure that you stay within the free tier.

    - Hit "Create Database" at the bottom of the page and wait a few minutes while your database is created and an instance of the database is launched.

### Part 6 - Security Groups

Once your database is up and running, we'll need to make sure that your EC2 instances can communicate with it. To do that, we'll need to edit the settings for their respective security groups.

1. #### Edit Security Group settings
    
    - Navigate to `Services -> EC2 -> Security Groups`, where we can see a list of our security groups. There should be at least three security groups: 1. "default" (your default VPC's security group), 2. a randomly generated string of characters (this is the security group of your Elastic Beanstalk EC2 application), and 3. "mm-db-sg" which is the RDS security group we just created. 

    - First, tag your RDS security group with a 'Name' and set it to `mm-db-prod-sg`. You can also set your EC2 security group to `mm-prod-sg`. This will make them easier to identify in the future.

    - Let's now give the EC2 instance access by creating a new inbound rule for our 'mm-db-prod-sg' security group that allows postgres traffic from our 'mm-prod-sg' security group. (To do this, you'll need to get the id of the 'mm-prod-sg' group.) 
        - Click on the Security group ID for your RDS security group (mm-db-prod-sg).
        - In the bottom panel, select "Inbound rules" and then select "Edit Inbound rules"
        - Within the "Edit inbound rules" menu, select "Add rule".
        - For this new rule, for "Type" select "PostgresQL". For "Source", select "Custom" from the dropdown menu. Clicking on the "Source" textbox should now provide a dropdown of options. Scroll down to the "Security Groups" subsection, and select the security group associated with your Elastic Beanstalk EC2 environment. *(If you have more than one security group for your EB environment, add all of them to this rule)*
        - Finally, click "Save rules" at the bottom of the page.

### Part 7 - Creating your database

The RDS instance is running.  The EC2 instance can see it.  Now we just need to create all of the tables in our mmdb database.  Since we've restricted access to our RDS instance to traffic coming from our EC2 instance, we'll need to run our database creation script from there.

- Note the .ebextensions folder in this repo.  This folder allows us to provide Elastic Beanstalk with [configuration scripts](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/customize-containers-ec2.html) to run for each EC2 instance started up within the environment.  We've added a script that installs postgres.  Without this script, you would need to install postgres on your EC2 instance before you could run psql commands.

1. #### Run the db creation script from EC2
    - Login to our EC2 instance from the command line by invoking ssh, providing the private key, and logging in as `ec2-user` as we did previously: `ssh -i ~/.ssh/mm-ec2-key.pem ec2-user@your-ec2-public-dns`.
    - You'll need the DNS or 'endpoint' from your RDS instance. You can find that under Services -> RDS -> DB Instances. Click on your database instance to see more information. Under "Connectivity & security" you'll find the Endpoint needed in the following psql command.
    - With psql, you can run any SQL commands stored in a file by invoking psql, pointing at the database, providing credentials, and adding the `-f [sqlfilename]` parameter
        - `psql -h [RDS instance endpoint] mmdb -U mmadmin -f /var/app/current/scripts/db_init_prod.sql`

### Part 8 - Set up ECR (Elastic Container Registry)

We won't be using ECR immediately, but this will become useful when we incorporate Continuous Deployment from GitHub Actions.  It's really easy to set up.

1. #### Set up ECR
    - Head over to ECR from the Services menu and `Create a repository`.  Let's name it `mm` for megamarkets.

    - Note the URI.  You'll come back for this in your CI/CD setup later.

1. #### Give your EC2 instances access to ECR

While IAM access control for users is managed with 'Users' and 'Groups', access control for AWS services is managed via 'Roles'.  We're going to need to be able to access ECR from our EC2 instance, so let's go over to IAM and authorize!

    - Select 'Roles' from the side menu
    - Find and select `aws-elasticbeanstalk-ec2-role`
    - Attach the `AmazonEC2ContainerRegistryReadOnly` policy to this role.

### Part 9 - Create Access Key

Also for the Continuous Deployment step later on, you'll want to create an Access Key to allow GitHub Actions to access your ECR.

- Click on the dropdown menu for your account settings on the top-righthand side of the page, and click on "Security Credentials."

- Scroll down to the "Access Keys" section, click "Create Access Key", and follow the steps to do so.

- This will generate an **Access Key** as well as a **Secret Key**. You'll be able to view both immediately after creating them - be sure to save them somewhere or download the CSV file, as you won't be able to view the secret key again after this.

### Part 10 - Environment Variables

We're nearly done!  Now all we have to do is give our application all of the information it needs to connect to our database.  Because this requires sensitive data (username and password), best practice is to supply these values through **environment variables**.  We can set these up with Elastic Beanstalk.

1. #### Set up your environment variables
    - Go to your megamarkets production environment and select Configuration -> Software
    - Add the following environment variables
        - NODE_ENV : production
        - RDS_HOSTNAME : [RDS 'endpoint']
        - RDS_DB_NAME : mmdb
        - RDS_USERNAME : mmadmin
        - RDS_PASSWORD : [your password]
        - RDS_PORT : 5432

### Part 11 - Verify that your application is working with the database

1. Open the Dashboard for your environment and follow the URL at the top to see your application running in the cloud.

1. Add some markets, cards, reload the page, **revel in the glory of your achievement!**

1. Don't get carried away with that, though.  We've got one more thing to implement: [CI/CD](https://github.com/CodesmithLLC/unit-13-devops/blob/master/README-ACTIONS.md)

1. Don't forget to tear down your AWS application when the unit is over!  Instructions are at the bottom of this ReadMe.

## Extensions

1. ### Set up AWS and EB CLI
    You can accomplish a lot of the tasks we've been doing with the AWS console from the command line using the AWS and EB CLI tools.  These tools also simplify things like getting your ssh connection to your EC2 instance.  

    1. **Install the AWS and EB CLI tools**
        - Follow the AWS CLI [installation instructions](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) for your OS
        - Follow the EB CLI [installion instructions](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install.html) for your OS
    1. **Configure**
        - Go to your development directory and run `aws configure` to set up your aws cli configuration
            - You'll need the information from your IAM credential csv file
        - Run `eb init` to set up your eb cli configuration
    1. **Login to EC2 using eb ssh**
        - Run `eb ssh` to connect to your current running instance

1. ### Set your environment up as 'high availibility' by adding auto scaling with a load balancer

    Currently, your EB environment is set up as 'single instance', so we only have one virtual machine to handle all of our network traffic.  We've already learned the value of dynamic horizontal scaling in a production environment.  So how do we set this up for our AWS EB application?

    **Note: Auto Scaling does not qualify as free tier.  This could result in AWS charges, so don't leave this up in your environment.**

    1. Go to your EB environment and select Configuration -> Capacity
    1. Change the Environment Type to 'Load Balanced'

        Take the default settings for now.  (The default triggers scale when the average outbound network traffic from each instance is higher than 6 MB or lower than 2 MB over a period of five minutes.)

1. ### Set up DNS with Route 53
    **Note: Domain names are not free with AWS.  If you do this your credit card will be charged for the domain name registration.**

    1. Go to Services -> Route 53
    1. Set up a new Domain Registration (again, this will incur a charge) and may from a few minutes up to a couple of days to process.  Even once it has been registered with AWS, it may take some time to propogate throughout the DNS system.  So it may take some time to finish this one.  
    1. During this process, AWS will automatically create a new 'Hosted Zone' with your new Domain
        - This will provide you with two records:
            - NS (name server)
            - SOA (Start of Authority)
        - You will need to add an 'A' record, this is what creates the mapping between the URL and the IP address of your host
            - Make this an alias record.  This way we can route it to our service rather than a specific IP address.
            - If you've created a load balancer, you'll point your A record at the load balancer.
            - If you have a single instance, you'll point your A record at the Elastic Beanstalk environment
    1. You can check DNS propogation through sites like [dnschecker.org](https://dnschecker.org)

## Tear down your AWS application

1. ### Log in as your IAM User
    Not sure what your IAM user account number is?  Sign in as the root user for your account using your email address, and navigate to the 'Users' page from your IAM dashboard.  Select your IAM administrator name and not the number inside of your User ARN.  This is your IAM account number.

1. ### Tear down Elastic Container Registry (ECR)
    Head on over to Services => Elastic Container Registry.  You will immediately be presented with your ECR repositories.  Select your repository entitled ‘mm’ and click the delete button above.  You will be required to confirm deletion in this step and most other steps in this process.  Be sure to check both your Private and Public tabs and confirm both are empty.

1. ### Tear down your database (RDS)
    Now we can navigate to Services => RDS => Databases and see our RDS instance running.  Select your ‘mmdb-prod-instance-1’ db and select Actions => Delete.  This is going to take a few moments to complete.  During this tear-down process, please wait for deletion to complete at every step.  If you attempt to tear down multiple services at once, you may run into conflicts that will prevent thorough deletion.  Patience is your friend.

1. ### Terminate Elastic Compute Cloud (EC2) instances
    Next up, go to Services => EC2 => Instances and you can see your Elastic Compute Cloud instance running.  If you select your EC2 instance, click Instance State => Terminate Instance, it may give you a notice that your instance is attached to an EC2 auto-scaling group.  In this case, at the bottom of the left sidebar, click Auto-Scaling Groups, select your group(s), click Delete, and wait for completion.

    Go back to Instances and confirm that your instance displays as 'Terminated'.  If you navigate to your EC2 dashboard, you can also click ‘Load Balancers’ and delete your load balancers.

    Again from your dashboard, click ‘Key Pairs’ and delete any key pairs you have.  Lastly, click ‘Security Groups’ and delete all of your security groups for any EC2 instances.  You will have to delete them one at a time, as they are dependent upon each other.  You should be able to successfully delete all but the default security group.

1. ### Chop down your Elastic Beanstalk
    Navigate to Services => Elastic Beanstalk => Applications, select your megamarkets application, then click Actions => Delete Application.  You’ll be shown a notification that indicates that the corresponding environment will be terminated upon deletion of the application.  Go ahead and confirm deletion.

    Navigate to your Environments page and you should see the health of your environment change from red to grey.  The environment is now in the process of being torn down.  Clicking on the environment, you will see a grey spinner.  This is going to take a while, so go grab a snack and wait for your environment to tear down.  When the environment has been successfully terminated, the environment name will display with the (terminated) tag.

1. ### Empty and delete your Simple Storage Systems (S3) bucket
    We’re almost done!  Let’s navigate to Services => S3 to view your storage buckets!  Buckets are containers that store your data in S3.  Go ahead and select your S3 bucket and click Empty.  You cannot delete the bucket until it has been emptied. Upon a successful empty, you will see a green Success banner pop up at the top of your page.

    Now we have to actually delete the bucket itself.  Click Exit to go back to your Buckets page and select your now empty bucket.  You’ll notice that if you select your bucket, click and confirm Delete, you’ll get an authentication error.  Don’t panic.  You just need to delete the bucket policy.  Go back to your Buckets page and click the name of your bucket.  In the Permissions tab, you will see Bucket Policy.  Click Delete.  You’ll see another green Success banner at the top of the page.

    NOW, go back to your Buckets page and try deleting the bucket again.  Should work out real nice for ya.  If not, then you are most definitely experiencing an IAM policy issue, and the error message that appears will point you in the right direction to change your s3:deleteBucket policy from ‘Deny’ to ‘Allow’.

1. ### Topple your CloudFormation stacks
    This step is mostly for verification that your terminations/deletions have been successful.  Go to Services => CloudFormation and ensure you have no stacks on your dashboard.  No stacks here?  Great.  Go to the next step.
    
    If you have a stack on your dashboard, that indicates that there was an issue terminating your Elastic Beanstalk application or environment.  Go back to your Elastic Beanstalk console and try terminating again.  While Elastic Beanstalk is working on terminating your environment, your CloudFormation stack should display DELETE-IN-PROGRESS as its status.

    Go get another snack and wait for your environment to shut down… Again…  You might need to refresh the page to make sure your event logs are updated.  Sometimes it stalls out, so don’t be alarmed.

1. ### Check your billing information
    Log out of your IAM user account and log back in as your AWS root user.  Go ahead and navigate to Services => Billing to see your Billing & Cost Management Dashboard.  If you get an alert email from AWS at any point after completing the above steps, you should probably try looking here first.  You will be able to see how many requests you’re handling per service, and if anything is approaching the limit, you are probably still running something on that AWS service.

    If you are experiencing any issues that are not addressed in this section, feel free to browse the AWS forums for troubleshooting tips or reach out to AWS support directly.
