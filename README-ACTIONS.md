# CI/CD with GitHub Actions

## Summary

GitHub Actions is a GitHub's built-in continuous integration and delivery/deployment platform. It automates the process of building, testing, and deploying software projects hosted on GitHub.

Actions for a given project are made up of **workflows**, which are configuration files describing one or more **jobs** that should run in response to a specific **event**, such as a pull request or merge. When a workflow is triggered by one of these events to run, GitHub will spin up a virtual machine (called a "runner") to run each specified job.

You can find further information about how Actions work in [GitHub's official docs](https://docs.github.com/en/actions). Keep the docs handy and open - they will be a helpful reference from this point on!

In this part of the challenge, we'll be setting up workflows for the continuous integration and deployment of our MegaMarkets app. The end result will be as follows:

- Whenever a pull request is made to the `main` branch, GitHub will run our unit tests (`/client/test/reducer-test.js`) for continuous integration.
- When any changes are pushed onto or merged into the `main` branch, GitHub will first run our tests, and if they pass, deploy the updated code to AWS.

## Challenges

### Setup

#### Enable Actions

To start off, you'll need to ensure that Actions are enabled on your GitHub repo. To do this:

- Navigate to the _"Settings"_ tab
- Expand the _"Actions"_ menu
- Make sure the _"Allow actions and reusable workflows"_ option is selected
- Click _"Save"_

#### .github directory

Actions workflows must always be stored in a `.github` directory at the top level of your repository.

- [ ] Create this directory, and add a subfolder called `workflows`. By default, GitHub will look here to find any workflows that it should run.

Each workflow should be stored as an individual YAML file within the `.github/workflows` directory. We'll first be creating our workflow for integration testing, so let's move on!

### Part 1 - Integration Testing

Our integration testing workflow will run our unit tests on any pull requests made to the `main` branch, so that we can ensure the new code passes before merging it in. We'll be instructing GitHub to use our public Docker images to spin up a container and run the tests.

- [ ] Within the `.github/workflows` folder, create a file `build-tests.yml`. This file will define our workflow for testing our build.

- [ ] In this YAML file, you'll first want to define a `name` key. This will be what GitHub displays on its UI when the workflow is running. Let's set its value to `build-tests`.

- [ ] The `on` dictionary will define which event(s) should trigger our workflow to run. Each applicable event may be stored as a separate dictionary within it. In this case, we'll want to create a `pull_request` dictionary that contains an array of `branches` that we want our workflow to apply to. In this case, we'll just be using the `main` branch.

- [ ] The `jobs` dictionary contains a key for every job that is part of a workflow. As above, each job will be stored as another dictionary. Our workflow, for now, will just have one job - let's call it `unit-testing`. (If we also had integration or end-to-end tests set up, we could add separate jobs for these as well.)

- Our unit-testing job should include the following keys:

  - [ ] `runs-on` will determine which type of machine the job will run on. GitHub offers various MacOS, Windows, and Linux runners - here, we'll be using the latest version of Ubuntu. Set this key's value to `ubuntu-latest`.

  - [ ] `steps` defines the sequence of tasks that will make up our job. It will be an array of key-value pairs.

    - [ ] Our first step will make use of a pre-published, reusable Actions workflow called [Checkout](https://github.com/actions/checkout), which checks out our latest commit to the runner's default working directory. This allows our workflow to access it. To use Checkout, we'll include a key called `uses` and set its value to `actions/checkout@v4`.

    - [ ] Our next step will actually run our tests. It will consist of a `run` key, whose value is the script we want to run. We'll be using `docker-compose` to build our testing container that we configured with our `docker-compose-test.yml` file. We'll add a flag to tell GitHub to abort if we exit from the container.

  ```yaml
  docker-compose -f docker-compose-test.yml up --abort-on-container-exit
  ```

It's time to test your workflow!

1. Create a new feature branch in your source repo.
2. Change some code. For example, update the color of your text in `styles.css`.
3. Add, commit, and push your feature branch up to GitHub.
4. In GitHub, create a Pull Request requesting to merge your feature branch into the `main` branch.
   - **Note:** When creating a pull request from your fork, you will generally be redirected to the Pull Request page in the CodesmithLLC base repository. At the time of writing, the GitHub site has a glitch affecting certain repos with over 200 forks, which may prevent you from being able to search for your own fork in the dropdown menu to set it as your base. If this is the case, you will need to change `CodesmithLLC` in the URL to your own GitHub handle to redirect the PR back to your fork.
5. You'll be able to view your Actions workflows from either the "Actions" tab on the main repo, or the "Checks" tab on the Pull Request page. If you've set everything up correctly, you should see your `build-tests` workflow running, and the tests should pass. If your workflow fails, you'll want to expand it to look at the error messages, and debug from there. If it passes, you're ready to move on to the next section and set up continuous deployment!

### Part 2 - Continuous Integration & Continuous Delivery/Deployment (CI/CD)

We're going to create a new workflow for deployment. This worfklow will run two jobs: our tests, and then a script to deploy our application to Elastic Beanstalk.

#### Step 1 - Add secrets to our repository

This script will make use of the AWS access keys we previously created. First things first - we'll need to configure GitHub to be able to use them.

- [ ] In your repository, navigate to the 'Settings' tab. On the lefthand side menu, under 'Security', you'll see an option for 'Secrets and Variables`. Expand this, and click on 'Actions'.

- [ ] Click on the 'New repository secret' button to create a secret. Set its name to `AWS_ACCESS_KEY_ID`, and its value to the _access key_ you created in AWS.

- [ ] Now, create another secret named `AWS_SECRET_ACCESS_KEY`, and set its value to the access key's corresponding _secret key_. (Remember, you cannot find this secret in AWS if you didn't save it. In this case, you'll need to create a new access/secret key pair.)

And that's it! Our access keys are now saved in our repository as secrets. Let's move on to setting up our workflow.

#### Step 2 - Configure the deployment workflow

- [ ] In the `.github/workflows` directory, create a new file called `deploy.yml`.

- Give this workflow a name of `deploy`, and set it to be triggered by a `push` event on the `main` branch.

- [ ] Set up the first job to run our unit tests, as you did for the previous workflow.

- [ ] Directly below, add a second job called `deploy`.

  - GitHub Actions runs jobs _concurrently_ by default, but that's not what we want here - we'll want to wait until our `unit-testing` job finishes successfully before running this one (i.e. we don't deploy to AWS unless our tests have passed!). To configure this, add a `needs` key to the second job. This key's value may be set to either a single value or an array, specifying the name of any job(s) that must complete before the current one runs.

- [ ] As with our previous job, set this one to run on `ubuntu-latest`.

- Next, we'll add the steps to compete our job. This one will have a few more:

  - [ ] Once again, we'll be using `actions/checkout@v4` to make our repo available to the workflow.

  - [ ] We'll be using a second reusable workflow, [setup-python](https://github.com/actions/setup-python), to install Python for the AWS CLI to use. Our second step will be a dictionary with two keys:

    - `uses`, set to `actions/setup-python@v5`
    - `with`, set to another dictionary with a key of `version` and a value of `'3.x'`. This will tell the workflow to use the latest Python 3 release.

  - [ ] The AWS CLI requires a specific pre-installed version of pip (Python's package management system), so we'll want to make sure this is up to date. To do this, add another step to `run` the script `python3 -m pip install --upgrade pip`.

  - [ ] Next, we'll use Python's installer to install and configure the AWS command line interface inside of our virtual machine. Add another step to run the following script: `python3 -m pip install --user awscli`.

  - [ ] Our final step will be to run a bash script for deployment - which we haven't created quite yet, but will be in a later step. For now, add another `run` key with a value of `sh ./scripts/deploy.sh`.

- [ ] Our bash script will make use of a few additional pieces. It will need a reference to our AWS access/secret keys, as well the **head** (i.e. most recent) commit hash of our `main` branch. We'll be storing these as environment variables so the script can access them. To do this, add an `env` dictionary to the deploy job. It will consist of the following key-value pairs:

  - [ ] A key named `AWS_ACCESS_KEY_ID`, with a value set to `${{ secrets.AWS_ACCESS_KEY_ID }}`. This will reference the AWS_ACCESS_KEY_ID secret we saved earlier.
  - [ ] Do the same for the `AWS_SECRET_ACCESS_KEY`.
  - [ ] A key named `GITHUB_SHA`, whose value is set to `${{ github.sha }}`. This references the hash of our `main` branch's **head** commit.

We're getting close! We'll just need a couple more files before we're ready to go.

#### Step 3 - Create `Dockerrun.aws.json`

- [ ] In your repo's top level directory, add a file called `Dockerrun.aws.json`.

A [Dockerrun.aws.json](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/single-container-docker-configuration.html#single-container-docker-configuration.dockerrun) file describes how to deploy a remote Docker image as an Elastic Beanstalk application.

This `.json` file should do the following:

- [ ] Set the Dockerrun version to 1
- [ ] Instruct AWS to `pull` the image from the Elastic Container Registry (ECR) repo
  - [ ] ...and overwrite any cached images
- [ ] Route requests to the appropriate container port

Note the `<VERSION>` tag in the image name. This text will be replaced by the GitHub SHA when GitHub runs our bash script.

Make sure to replace [ECR URI] with your Elastic Container Registry URI.

```json
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "[ECR URI]:<VERSION>",
    "Update": "true"
  },
  "Ports": [
    {
      "ContainerPort": "3000"
    }
  ]
}
```

### Part 3 - Create bash script for deployment

Our penultimate step will be to create the bash script that our workflow will run to deploy our build to Elastic Beanstalk.

- [ ] Create a file `deploy.sh` in the `./scripts` directory (as referenced previously in the job's configuration).

This bash script moves all the files from our current build to the appropriate places within AWS to deploy our code. Note that wherever you see `$GITHUB_SHA` refers to an environment variable supplied by GitHub that contains a SHA generated hash key that uniquely identifies this build.

_Remember to swap out any values below in brackets ( [ ] ) with the corresponding values for your specific application (e.g. S3 BUCKET NAME, YOUR AWS REGION, etc.)_

```bash
    echo "Processing deploy.sh"
    # Set the EB BUCKET (you can find this in S3 service within AWS)
    EB_BUCKET=[S3 BUCKET NAME]
    # Set the default region for the AWS CLI
    aws configure set default.region [YOUR AWS REGION]
    # Log in to Elastic Container Registry
    eval $(aws ecr get-login --no-include-email --region [YOUR AWS REGION])
    # Build the Docker image based on our production Dockerfile
    docker build -t [orgname]/mm .
    # Tag the image with the GitHub SHA
    docker tag [orgname]/mm:latest [ECR URI]:$GITHUB_SHA
    # Push the built image to Elastic Container Registry
    docker push [ECR URI]:$GITHUB_SHA
    # Use Linux's 'sed' command to replace '<VERSION>' in our Dockerrun file with the GitHub SHA key
    sed -i='' "s/<VERSION>/$GITHUB_SHA/" Dockerrun.aws.json
    # Zip up our codebase, along with the modified Dockerrun file and our .ebextensions directory
    zip -r mm-prod-deploy.zip Dockerrun.aws.json .ebextensions
    # Upload the zipped file to our S3 bucket
    aws s3 cp mm-prod-deploy.zip s3://$EB_BUCKET/mm-prod-deploy.zip
    # Create a new application version
    aws elasticbeanstalk create-application-version --application-name [your EB application name] --version-label $GITHUB_SHA --source-bundle S3Bucket=$EB_BUCKET,S3Key=mm-prod-deploy.zip
    # Update the environment to use the new version number
    aws elasticbeanstalk update-environment --environment-name [your EB environment name] --version-label $GITHUB_SHA
```

### Part 4 - Deploy!

It's all come down to this moment.

We've containerized our application. We've manually deployed it in the cloud. We've set up CI/CD.

Let's see it all work!

1. Create another feature branch. Make some changes, add, commit, push it up to GitHub, and make a pull request to your `main` branch! (Alternatively, you can update your `main` branch locally and push up the changes - either approach should trigger your deployment workflow to run.)

2. Once you merge the PR, go back and watch your Actions workflow in progress. If the `unit-testing` job passes, GitHub will move on to run the `deploy` job. If that's successful, head over to Elastic Beanstalk to watch your environment update in real time.

3. When the environment finishes updating, go check out your **live, full stack, containerized React/Redux application built with full continuous integration and deployment!!!**

4. **CELEBRATE!!! HIGH FIVE!! OMG!!**

5. When you're done celebrating, head back to README-AWS to methodically tear down all of your AWS instances!
