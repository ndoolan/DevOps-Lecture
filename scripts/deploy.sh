    echo "Processing deploy.sh"
    # Set the EB BUCKET (you can find this in S3 service within AWS)
    EB_BUCKET=elasticbeanstalk-us-east-1-264018060329
    # Set the default region for the AWS CLI
    aws configure set default.region us-east-1
    # Log in to Elastic Container Registry
    eval $(aws ecr get-login --no-include-email --region us-east-1)
    # Build the Docker image based on our production Dockerfile
    docker build -t powerhour/mm .
    # Tag the image with the GitHub SHA
    docker tag powerhour/mm:latest 264018060329.dkr.ecr.us-east-1.amazonaws.com/mm:$GITHUB_SHA
    # Push the built image to Elastic Container Registry
    docker push 264018060329.dkr.ecr.us-east-1.amazonaws.com/mm:$GITHUB_SHA
    # Use Linux's 'sed' command to replace '<VERSION>' in our Dockerrun file with the GitHub SHA key
    sed -i='' "s/<VERSION>/$GITHUB_SHA/" Dockerrun.aws.json
    # Zip up our codebase, along with the modified Dockerrun file and our .ebextensions directory
    zip -r mm-prod-deploy.zip Dockerrun.aws.json .ebextensions
    # Upload the zipped file to our S3 bucket
    aws s3 cp mm-prod-deploy.zip s3://$EB_BUCKET/mm-prod-deploy.zip
    # Create a new application version
    aws elasticbeanstalk create-application-version --application-name MegaMarkets --version-label $GITHUB_SHA --source-bundle S3Bucket=$EB_BUCKET,S3Key=mm-prod-deploy.zip
    # Update the environment to use the new version number
    aws elasticbeanstalk update-environment --environment-name MegaMarkets-env --version-label $GITHUB_SHA