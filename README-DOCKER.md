# Docker

## Summary

[Docker](http://docker.com/) is a tool designed to make it easier to create, deploy, and run applications by using containers.

Containers provide an easy way for us to create lightweight isolated environments that are defined by a configuration file. They may be used again and again across your team and infrastructure to ensure that everyone working on the codebase shares the same environment with each other and production.

## Docker Overview

### Docker Containers

Containers are runtime environments. You usually run only a single main process in one Docker container. So basically, one Docker container provides one service in your project.

For example, you can start one container to be your node server and start another container to be your postgres database and connect these containers together to get a full stack project set up on your development machine.

### Docker Images

In order to create a container, you will need to create a Docker image. A Docker image can be thought of as a template derived from a recipe of technologies. A Docker image is _not a runtime_, it’s rather a collection of files, libraries and configuration files that build up an environment. Docker images can be built on the command line, but are most commonly constructed using _Dockerfiles_

Images can be layered on top of each other to add further utilities/libraries/etc to the environment. There is a great resource of community and official images on [Docker Hub](https://hub.docker.com/search?q=&type=image). These files can be accessed using the FROM keyword in your Dockerfile, (or you can pull the image manually with the `docker pull` command.)

Containers are created from images with the `docker run` command.

#### Dockerfile

- The Dockerfile is a text file that contains the instructions that you would execute on the command line to create an image.
- A Dockerfile is a step by step set of instructions.
- Docker provides a set of standard instructions to be used in the Dockerfile, like `FROM, COPY, RUN, ENV, EXPOSE, CMD`
- Docker will build a Docker image automatically by reading these instructions from the Dockerfile.
- By default, the `docker run` command will look for a file named **Dockerfile** in the local directory. You can specify a different Dockerfile name by passing the `-f` parameter

### Docker Volumes

[Volumes](https://container-solutions.com/understanding-volumes-docker/) are Docker’s mechanism for sharing and persisting data beyond the life of a container. Volumes are created outside of Docker's Union File System and serve as mount points for your host file system. Volumes can be created via the command line with the -v parameter or in docker-compose files (which you'll be learning about today):

```yaml
volumes:
  - ./:/usr/src/app
```

This would mount the current directory: `./` to `/usr/src/app` in the container. This means that files created/edited in the current directory are also created/edited in the container and vice versa.

## Setup

1. Install Docker

   - Each pair partner should go to [docker.com](http://docker.com/), then download and install Docker for your OS. (You'll be required to create a docker account to do this. Remember your dockerId, you'll use it in the next step)

   - Native Windows and WSL Users: Follow this [link](https://github.com/CodesmithLLC/unit-13-devops/blob/master/README-WSL.md).

2. Create a Docker Hub account

   We have a way to collaboratively share code with Github. Docker Hub gives us a way to collaboratively share images.

   - One of you head over to [Docker Hub](https://hub.docker.com) and create an account with the dockerID that you used when you installed Docker.

   - Create an organization. The name will need to be unique across all of Docker Hub, so this may take a couple of attempts. You'll use this name as you go through the challenge anywhere you see `[orgname]`. 
      - You will be asked to select a plan for your new organization. Choose the ‘buy now’ option on the Team plan and disregard the pricing info, we will be bypassing this to create a free version. When asked to set up your organization’s size, use the default settings and continue to the payment section. At this point you will be asked to enter your payment info. To bypass this, click the ‘Organizations’ tab on the top navbar to redirect to your newly created free organization.

   - Add your partner to the **owners** team by entering their dockerID

Okay, setup complete! On to the...

## Challenges

This repo contains a full stack version of the MegaMarkets application built in React/Redux/Node/Express fronting a postgres database. The application is completely built out. The goal of this two day unit is for you to deploy a **containerized** version of this full stack application to **AWS** using **GitHub Actions**.

We'll begin by containerizing this application. For now, let's just get an image configured with a stable version of node and make sure that all of our node_modules are built within our container. This will ensure that everyone who uses this image will be on the same page.

### Troubleshooting - In case things get weird

Configuring Docker _can_ be a bit confusing at times. You may find that your docker images, containers, or volumes aren't working as you hoped. Don't worry! Here are a couple of things you can do to set things right.

#### Login to a _running_ container

Any time you're wondering what's _really_ going on in your container, you can always just login through an _interactive terminal_ and take a look.

```bash
docker exec -it <container-name> /bin/bash
```

You can run any linux command that would run in the container after the `<container-name>`. In this case, we're starting up a bash shell to get to the command line inside of our container. You could also login to a database in a container running postgres by invoking

```bash
docker exec -it <container-name> psql -U <username> <database-name>
```

#### Stop containers

First, try stopping all of your running containers. We can do this using the linux `$()` construct. This will execute a command and return what would have been written to the screen (or STDOUT). The -f parameter here is useful if you have more than one project using Docker. This ensures that you're only affecting the containers for this project. If you only have this project using Docker, you don't need to use that parameter.

```bash
docker stop $(docker ps -q -a -f 'name=mm-' --filter status=running)
```

Furthermore, these Docker assets can all be recreated very easily. All you need to do first is clear out the images, containers, and volumes that are aren't cooperating. This is how:

#### Remove containers

```bash
docker rm $(docker ps -q -a -f 'name=mm-') --force
```

#### Remove images

```bash
docker image rm $(docker images [orgname]/mm* -q) --force
```

#### Remove volumes

```bash
docker volume rm $(docker volume ls -q -f 'name=unit-13*') --force
```

One _could_ even consider putting these commands together in their package.json script using `&&` to ensure that each prior command was successful before executing the next in the chain...

```bash
docker-remove-all: docker rm $(docker ps -q -a -f 'name=mm-') --force && docker image rm $(docker images [orgname]/mm* -q) --force && docker volume rm $(docker volume ls -q -f 'name=unit-13*') --force
```

### Part 1 - Dockerfile

1. Let's start by creating our production Dockerfile. Create a file in the top level directory and name it `Dockerfile` that implements the following

   - Start FROM a baseline image of node v16.13

   - Set up a WORKDIR for application in the container and set it to `/usr/src/app`.

   - COPY all of your application files to the WORKDIR in the container

   - RUN a command to npm install your node_modules in the container

   - RUN a command to build your application in the container

   - EXPOSE your server port (3000)

   - Create an [ENTRYPOINT](https://docs.docker.com/engine/reference/builder/#entrypoint) where you'll run `node ./server/server.js`

2. Build the docker image from Dockerfile

   Tag the image as mm-prod so it will be easy to recognize and reference. By default, docker will look for a file named Dockerfile. We'll take advantage of that later when we upload this repo to AWS. Finally tell it to build in the current directory with `.`.

   `docker build -t [orgname]/mm-prod .`

   We can verify that the image has been created by listing the docker images on your machine.

   `docker images`

3. Create the container by running the image

   We'll open port 3001 on our localhost and point to port 3000 in the container. (These could be the same value, we're just differentiating for clarity here)

   `docker run -p 3001:3000 [orgname]/mm-prod`

   You should see the server start up. Now just go to your browser and navigate to localhost:3001 to see the application running from within your container! (You can also run the container in 'detached' mode by passing the `-d` flag. This will run the container and give you access to your command line.)

   You can also verify that the container has been created by listing the current running containers

   `docker ps`

   Note the NAME in the output. Docker generates a random name for us that we can use to reference the container. We can specify the name if we include a `--name <name>` parameter when we invoke `docker run`.

   We can stop our container by hitting `^C` or by issuing the stop command (either from another terminal or if you're running in detached mode.)

   `docker stop <container_name>`

### Part 2 - Docker Compose

So we can build an image that creates a container that runs our application. Great!

But meanwhile, what about development? Our production container isn't running webpack-dev-server, so we're not getting live reloading/HMR.

Wouldn't it be really cool if we could get the benefits of live reloading/HMR by running webpack-dev-server in a development container? Wouldn't it also be swell if we had another container that hosted a local version of our database to use for development? You bet it would. And we can. All we need to do is build these images and run the containers.

And we can rest assured that the dependencies across our production and development containers will stay in sync because we'll npm install from the same package.json and package-lock.json in those containers.

Now, we could spin up these development containers in proper order manually every time we wanted to run our app, but wouldn't it be _even better_ if we could write up a configuration file that would handle all of that with a single command? Yes, yes it would.

All of this can be ours by building a couple of images and orchestrating them with the **docker-compose** utility.

To begin, let's build an image that will create a container running webpack-dev-server.

1. Create a file in the top level directory called `Dockerfile-dev` that implements the following

   - Start FROM a baseline image of node v16.13

   - RUN a command to npm install webpack globally in the container

   - Set up a WORKDIR for application in the container

   - COPY your package\*.json (to get both package and package-lock) files to the WORKDIR in the container

   - RUN a command to npm install your node_modules in the container

   - EXPOSE your server port

2. Build the docker image from Dockerfile-dev

   Tag the image as mm-dev so it will be easy to recognize and reference. This time, we'll tell docker to use our Dockerfile-dev file using the -f parameter

   `docker build -t [orgname]/mm-dev -f Dockerfile-dev .`

   Let's verify that the image has been created by listing the docker images on your machine.

   `docker images`

3. Create the container using docker-compose

   This time, instead of running the image to create the container using the command line, we're going to make use of the docker-compose utility to run multiple containers (one for node_modules and another for our dev database).

   First, we'll create a configuration file that docker-compose will use to orchestrate our containers. You'll want to refer to the [docker docs](https://docs.docker.com/compose/overview/) to learn more about configuring docker-compose.

   The file format for this configuration file will be [yaml](https://rollout.io/blog/yaml-tutorial-everything-you-need-get-started/), which stands for 'YAML Ain't Markup Language'. It's useful as a simple human-readable structured data format. Yaml format is used a lot in the industry for configuration files.

4. Create a file in the top level directory called `docker-compose-dev-hot.yml` that implements the following

   - Set the docker-compose **version** to 3

   - Create a **services** dictionary

     - Create a **dev** dictionary as the first key in the **services** dictionary

     - Under **dev**, create the following:

       - An **image** key pointing to your [orgname]/mm-dev image

       - A **container_name** key set to something meaningful like 'mm-dev-hot'

       - A **ports** key that contains an array. We'll just have one value that will route requests from port 8080 on the host to port 8080 in the container.

       - A **volumes** key that contains an array.

         - In our first element, we'll want to mount the current directory on our host machine to the `/usr/src/app` directory in the container. This will allow the webpack-dev-server running in the container to watch for code changes in our file system outside the container. This is great because now we have live reloading and HMR.

           However, it's important to note that by virtue of mounting our current directory here (which does not include the files in node_modules), we are effectively overwriting the node_modules from our mm-dev image (that we populated in the image by running npm install) with an empty directory in our container. So, in order to preserve our node modules, we'll mount a [named volume](https://nickjanetakis.com/blog/docker-tip-28-named-volumes-vs-path-based-volumes) in the next element.

           The main difference between a named volume and a path based volume (as we used in our first element) is that Docker handles the question of _where_ to create named volumes in your host filesystem. If you just need the data to persist and don't care necessarily _where_ it persists, use a named volume. (You'll just need to include the named volume under the top level `volumes` key, which we'll do below)

           Another difference between a named volume and a path based volume (and the aspect that allows access to the node_modules we installed in our image) is that named volumes are initialized when a container is created. If the container’s base image contains data at the specified mount point, that **existing data is copied into the new volume** upon volume initialization, which makes it available within the container. This does not apply when mounting a host directory.

         - And so, in our next element, we'll mount a named volume we'll simply call 'node_modules' to `/usr/src/app/node_modules` in the container.

       - A **command** key that executes `npm run dev:hot` in the container. You'll see in `package.json` that this starts your node server and webpack-dev-server. The `proxy` settings in our `webpack.config.js` will route all traffic to the `api` route to the node server at port 3000.

   - Create a **volumes** dictionary where we'll create the named volume(s) we're mounting in our container(s)

     - Create an empty **node_modules** key.

5. Run the container using docker-compose

   `docker-compose -f docker-compose-dev-hot.yml up`

- Check out your running application at localhost:8080. Then let's verify that the live reloading is working by changing the text color in your styles.css file. It should reload the page with the new color. Voila!

  If you want to stop the container, you can hit `^C`, or

  `docker-compose -f docker-compose-dev-hot.yml down`

Okay, we've got a containerized environment with live reloading/HMR working for our application. But we still want to add a local development database. This will enable us to work on new features without worrying about our test data affecting production.

1. Create a file in the top level directory called `Dockerfile-postgres` that implements the following

   - Start FROM a baseline image of postgres v12.8

   - COPY the sql script from `./scripts/db_init.sql` to `/docker-entrypoint-initdb.d/` in the container. Whenever the container spins up, scripts in that directory get executed automatically. This will create and populate our database in the container.

2. Build the docker image from Dockerfile-postgres

   Tag the image as mm-postgres so it will be easy to recognize and reference. We'll tell it to look for the Dockerfile-postgres using the -f parameter

   `docker build -t [orgname]/mm-postgres -f Dockerfile-postgres .`

   Let's verify that the image has been created by listing the docker images on your machine.

   `docker images`

3. Edit `docker-compose-dev-hot.yml` to add our postgres container configuration

   - Create a **postgres-db** dictionary as the second key in the **services** dictionary

   - Under **postgres-db**, create the following:

     - An **image** key pointing to your [orgname]/mm-postgres image

     - A **container_name** key set to something meaningful like 'mm-database'

     - An **environment** key that contains an array. We'll add three elements to the array:

       - POSTGRES_PASSWORD=admin
       - POSTGRES_USER=mmadmin
       - POSTGRES_DB=mmdb

     - A **volumes** key that contains an array.

       - In our single element here, we'll want to mount a named volume we'll call 'dev-db-volume' to the `/var/lib/postgresql/data` directory in the container. This is where postgres stores the actual data files that make up your database. This volume will persist the data between container starts and stops.

   - Under the **volumes** dictionary, create the named volume with an empty **dev-db-volume** key.

   - We only want our **dev** service to start _after_ our **postgres-db** service has started. We can do that by adding a **depends_on** array to our **dev** dictionary and set the first element to **postgres-db**

4. Finally, we just need to let our application know that we want to use our development database hosted in the container rather than the production database. Look at the ./server/models/mmModel.js file to see how we're doing this by using an environment variable called NODE_ENV.

   - In order to pass that environment variable to our server, we can update the 'dev:hot' script in package.json to pass that key (NODE_ENV) with the value 'development'. Now we'll point to the containerized database.

5. Make your life even easier by using npm scripts

   It's good to know the docker-compose command to start up your containers, but once you know how to do it, it's nice to make it simple to kick off by adding it as a command in your script object in package.json. You can see where this has already been added as 'docker-dev:hot'

### Part 3 - Testing

We know the value of testing. Let's set up another docker-compose config that will spin up some test containers for us. We'll also be able to use these when we incorporate automated Continuous Integration with GitHub Actions later.

1. Create a file called `docker-compose-test.yml`. This file will look a lot like the one we created to run webpack-dev-server, with some important differences.

   - Set the docker-compose **version** to 3

   - Create a **services** dictionary

     - Create a **test** dictionary as the first key in the **services** dictionary

     - Under **test**, create the following:

       - An **image** key pointing to your [orgname]/mm-dev image

       - A **container_name** key set to something meaningful like 'mm-test'

       - A **ports** key that contains an array. We'll just have one value that will route requests from port 3000 on the host to port 3000 in the container.

       - A **volumes** key that contains an array.

         - In our first element, we'll want to mount our current directory to the `/usr/src/app` directory in the container.

         - In our next element, we'll mount a named volume we'll simply call 'node_modules' to `/usr/src/app/node_modules` in the container.

       - A **command** key that executes `npm run test`

     - Now create a **postgres-db-test** dictionary as the second key in the **services** dictionary

     - Under **postgres-db-test**, create the following:

       - An **image** key pointing to your [orgname]/mm-postgres image

       - A **container_name** key set to something meaningful like 'mm-test-database'

       - Create an **environment** key that contains an array. We'll add three elements to the array:

         - POSTGRES_PASSWORD=admin
         - POSTGRES_USER=mmadmin
         - POSTGRES_DB=mmdb

       - Create a **volumes** key that contains an array.

         - In our single element here, we'll want to mount a named volume we'll call 'test-db-volume' to the `/var/lib/postgresql/data` directory in the container. This is where postgres stores the actual data files that make up your database. This volume will persist the data between container starts and stops.

   - We only want our **test** service to start _after_ our **postgres-db-test** service has started. We can do that by adding a **depends_on** array to our **test** dictionary and set the first element to **postgres-db-test**

   - Create a **volumes** dictionary where we'll create the named volume(s) we're mounting in our container(s)

     - Create an empty **node_modules** key.
     - Create an empty **test-db-volume** key.

2. Let's run it and see if our tests pass!

   `docker-compose -f docker-compose-test.yml up`

### Part 4 - Docker Hub

1. Now we can push our images up to Docker Hub to be shared with the development team

   - `docker push [orgname]/mm-postgres`
   - `docker push [orgname]/mm-dev`
   - `docker push [orgname]/mm-prod`

2. Check the 'Repositories' tab in Docker Hub to verify that your images are there

3. Push your feature branch up to your forked repo in github, create a Pull Request to your master branch, then merge that request.

4. And now for the final test! Have your partner clone your forked repo to their local machine and run
   - `npm run docker-dev:hot`


### Building multiplatform Docker images (M1 Mac)

If you're using an M1 Mac, the above build process will allow you to run your containerized application locally on your machine. However, in order to successfully integrate the GitHub Actions service for CI/CD later on in the unit, you'll need to follow some additional steps.

Macs with the M1 chip have a Silicon processor, which uses a different CPU architecture (ARM) than computers with Intel processors (AMD). This means that there are differences between images built on these machines. There's one problem here: images built on ARM machines are not compatible with AMD machines, and vice versa. In the case of GitHub Actions, its servers use AMD architecture, which means that they cannot run the ARM images built on M1 Macs.

Go to your account page on DockerHub and open one of your image repositories, then open the "Tags" section to view your image. You'll be able to see which CPU architecture your image corresponds with: if you're using an Intel machine, this will be **amd64**, and if you're using an M1 machine, it will be **arm64**.

Luckily, there's a solution: we can use a plugin called [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/) to build images for multiple platforms.

First, we'll want to create a new builder instance, which will provide an isolated, scoped environment for our build. We can do this using the `create` command:

`docker buildx create --name mm-builder`

We can then specify that we want to use our `mm-builder` instance with the `use` command.

`docker buildx use mm-builder`

To build images with Buildx, use the `docker buildx build` command. You'll need to include the `--platform` option to specify which architectures to build images for, and the `--push` option to push your images to Docker Hub. Let's first try rebuilding your `mm-prod` image with Buildx:

```
docker buildx build \
   --platform linux/amd64,linux/arm64,linux/arm/v7 \
   -t [orgname]/mm-prod:latest \
   --push \
   .
```

In the tags section of your `mm-prod` repository on Docker Hub, you should now see that there are three different images for amd64, arm64, and arm architectures, each with a unique digest.

Now, go ahead and build your `mm-dev` and `mm-postgres` images as well using the above steps. 
> **IMPORTANT:** When rebuilding these images, you **MUST** include the `-f` flag to specify which Dockerfiles to use. Changing the tag alone is not enough!
> 
> This is one of the most common issues during this unit.
If successful, you'll now be able to see three different images under all of your repositories in Docker Hub. 

## On to AWS

Once you have successfully containerized your application and **both** partners are able to access it, open up the [README-AWS](https://github.com/CodesmithLLC/unit-13-devops/blob/master/README-AWS.md) file and start getting your application set up in the cloud!

## Extensions

1. ### Install a new dependency

   So if we shouldn't run `npm install` in this repo, how do we add new dependencies to our project?

   Fair question. What we'll need to do will depend on whether or not you know what version of the package you want. If you know the version, simply update your package.json and skip to step 3.

   1. Create a file in your top level repo directory called `docker-compose-extension.yml`. This is the docker-compose default configuration file.

      - Set the docker-compose **version** to 3

      - Create a **volumes** dictionary where we'll create the named volume(s) we're mounting in our container(s)

        - Create an empty **node_modules** key.

   - Create a **services** dictionary

     - Under **services**, create a **bash** dictionary, so when we run `docker-compose bash`, it will know to look here. We'll add other services later when we incorporate CI/CD. For now, the rest of this goes under the **bash** dictionary.

     - Create an **image** element pointing to your [orgname]/mm-dev image

     - Create a **container_name** element set to something meaningful like 'mm-dev'

     - Create a **ports** element that contains an array. We'll just have one value that will route requests from port 8080 on the host to port 8080 in the container.

       - Create a **volumes** element that contains an array.

         - In our first element, we'll want to mount our current directory to the `/usr/src/app` directory in the container. This will allow us to update our package.json with the current version of the package.

         - In our next element, we'll mount a named volume we'll simply call 'node_modules' to `/usr/src/app/node_modules` in the container.

   2. We can now run this container and install the new dependency using

      `docker-compose-extension run --rm --service-ports bash npm install --save (or --save-dev) [package-name]`

   3. Remove the current mm-dev image

      `docker image rm [orgname]/mm-dev --force`

   4. Build a new image with your updated package.json

      `docker build -t [orgname]/mm-dev -f Dockerfile-dev .`

   5. Now we can push our new image with the updated dependencies to Docker hub.

      `docker push [orgname]/mm-dev`

      Note: In order for other members of your team to get access to your new image, they'll need to clear out the image on their machines and pull the latest version.
