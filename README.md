# fluffy-carnival

## Installation

### Prerequisites

There are some prerequisites to have already installed and configured to run this project.

#### Docker

We will be running this project in containers. [Docker Desktop](https://docs.docker.com/desktop/) is this easiest way to get started. Follow the installation guide for one of your platforms

- MacOS [https://docs.docker.com/desktop/setup/install/mac-install/]
- Windows [https://docs.docker.com/desktop/setup/install/windows-install/]
- Linux [https://docs.docker.com/desktop/setup/install/linux/]

Once installed check the docker daemon is running

```sh
docker info
```

#### Minikube

Minikube is the kubernetes cluster which will run all the nessissary infrastructure to support the API.

Install it by going to this site and choosing your choice of installation and platform relevent to your machine.

[https://minikube.sigs.k8s.io/docs/start]

Verify the minikube command works

```sh
minikube version
```

#### Terraform

Terraform is used to apply some configuration to the database

Install it by going to this site and choosing your choice of installation and platform relevent to your machine.

[https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli]

Verify the terraform command works

```sh
terraform version
```

### Setup

Create a New Repository on GitHub:

- Go to GitHub and log in to your account.
- Click on the "+" icon in the top right corner and select "New repository".
- Enter a repository name (e.g., new-repo) and optionally a description.
- Choose to make the repository public.
- Click "Create repository".

Clone the New Repository to Your Local Machine:

```sh
# Replace <username> and <new-repo> with your GitHub username and the new repository name
git clone https://github.com/<username>/<new-repo>.git
cd <new-repo>
```

Download This Repository as a Zip File:

```sh
curl -L https://github.com/wooden-spoon-leg-warmers/fluffy-carnival/archive/refs/heads/main.zip -o repo.zip && unzip repo.zip && rm repo.zip
```

Move the Extracted Files to the New Repository Directory

```sh
# move the extracted files to the new repository directory
mv fluffy-carnival-main/* .

# Clean Up the Extracted Folder
rm -rf fluffy-carnival-main
```

Add and Commit the Changes to the New Repository

```sh
git add .

# Commit the changes with a message:
git commit -m "Initial commit with files from the existing repository"

# Push the Changes to GitHub
git push origin main
```

```sh
# Set the environment variable to your new repository name
export GITHUB_REPOSITORY=<username>/<new-repo>

# Run the bootstrap command
make bootstrap
```

### Usage

While the last process in the bootstrap is still running (the port fowarding) the below commands will work to hit the endpoint.

```sh
curl http://localhost:3000/myapi

curl http://localhost:3000/myapi2
```

For any updates the mapping, ArgoCD will pick up any changes to the helm chart.

```sh
# Change the mapping under, the mapping value takes an list of objects.
cat api/helm/api/values.yaml

# Commit and Push the changes to main
git add .
git commit -m "changed the mappings"
git push

# You will need to wait 3-5mins for ArgoCD to pickup the changes.
# This is a limitation due to local cluster.
```

### Cleanup

```sh
make cleanup
```

## Journal

> Created a little journal to walk through my thought process while taking on this task, it was super interesting to myself to see the iteration and decisions I made. Also I was not working on this for the whole timeframe i captured here, lots of jumping in and out here and there.

### 6:40pm

Initial read through of the task, is mostly clear. The uncertain parts are mainly around how I would like to implement this to make it as simple as possible for the user to reproduce it. The questions that come to mind:

- What should the repository look like? Is remote allowed? If not, what does creating CI/CD locally look like?
- Config-as-Code? I think it makes sense, reminds me of examples like policy as code in OPA.
- Python implementation is a little intimidating, due to the lack of pythons lib ecosystem but seems simple enough to overcome and nothing some docs on google cant fix.

### 6:50pm

Got some ideas of where to start with an image of what the overall product should look like. Reading the task again looking for answers/directions for the uncertain parts to help modify my idea. Mostly answered my questions by reading the example code, which helped quite a bit still uncertain on the implementation but I wont know that until I start hacking at it.

So overall design so far:

- Since of the top of my head I can't think of a "nice" way to implement a repo with ci/cd locally without mounting volumes and trying to point to it and also I noticed I am allowed to link to my repo when submitting my finished product. I am assuming a remote repo will be suffice. Github.. ticks lots of boxes:
- Github Actions for CI
- ghcr.io for container/helm registry
- has a remote endpoint I can point CD to watch for changes.
- ArgoCD for watching any changes happening on the repo this ticks the gitops approach, super familiar with it and easy to setup.
- Infrastructure of k8s is left ill be assuming docker is installed on the users computer and get them to install kind or even minikube. depends how easy exposing the services are, been a little while since doing it with both

### 7:01pm

I want to setup all infrastructure and linking of things first, create repo and gh user setup all that stuff.

### 7:15pm

Applied Journal notes into new gh repo, start investigating and building out folder structure. Mess around with the scripting to create the k8s clusters.

### 7:19pm

Going to use kustomization to apply the resources to support this setup. Just easy that way.

Will be just going with a mono repo for this, i am 95% confident argocd and gh actions can handle this behaviour to watch in directories. In an actual implementation i would rather have these seperate repos.

### 7:52pm
  
Added ci steps to gh actions to build the helm chart and docker image, However i am uncertain of the behaviour of the versioning, might be a little trial and error but since helm only supports semantic versioning with its packaging with OCI registries we must do 0.0.0-main. Might change to point to the repository directly in argocd app if its a pain and causes any problems. Going to test and see what i need to tweak, then move on to the boostrapping of the local k8s cluster.

Couple things I will need to setup for k8s to work properly..

- Generate a token in gh for registry and repository access.
- Will need 3 secrets, one for the image pulling and the 2 others for argocd to helm and repo changes.
- Also might look at terraform to bootstrap the db and tables in postgres.

### 8:08pm

Tested the ci steps to build and push to the repo had a few issues I thought were due to the pathing that ghcr allows but it ended up being a tick box in the UI to allow read and write perms for gh actions. Both helm and api look to be in the ghcr. Next will look at setting up the local k8s cluster.

### 8:44pm

Looked at the whole setup of minikube and installed and tested on my local machine, installed argocd into it. Decided to generate argocd resources with kustomization locally and stored them in the argocd folder to commit, this decision means reducing the need for the end user to install helm and kubectl on their machine.

### 9:10pm

Setup basic secrets for argocd to access gh and for k8s to pull from ghcr.

### 8:40am

Decided to go down the path of using a make file to help manage the commands, this allows us to configure a top level .env file with the secrets and any other variables we need which can filter throughout the bootstrapping to configure certain things. Trying to make things repo agnostic so forks just work to help reproduce the project, but we will see if i run into any roadblocks here.

- uncertain how I am going to approach one of the behaviours to implement: changes to the db IaC in main restart the database deployment. Don't exactly know the best approach for this since our database has no public access or tunnels currently, so gh actions cannot communicate with the db to either run tf against it or anything else. In a realworld scenario this isn't usually an issue. I don't think its nessissary to go down the path of creating a tunnel for this project. Could also look at argo events to watch the main branch and trigger a rollout restart of the db pod. (which is funny to me to restart the db 😅 on every IaC change)
- looking at how to apply the yaml mapping of endpoint to query, I've decided to go down the path of storing it in a configmap inside its helm chart. I don't necessarily like this approach, I feel there could be a more elegent way to do things but its not standing out to me at this moment.

### 8:58am

Just realised I don't need any secrets... since that all this is in a public repo. I look to have it etched in my head that everything needs access to the repos.

### 9:30am

Was testing changes to the api and was getting issues with argocd cache on helm chart, since I wasn't versioning anything and pushing only to a main tag it wasn't invalidating the cache and showing the updates. Ive decided to revert to pointing argocd application directly to the api's helm chart repo path which will remove this. Changes my other tagging startegy for the containers aswell to just latest, seems more straight forward for this.

### 12:24pm

Focused mostly on the bootstrapping, this highlighted quite abit of bloat which is not needed for the end product. Quite a bit of cleanup simplifying parts, running make bootstrap will build all the infrastructure and runs all the pieces.

- still unsure on how to get the database rollout restart working, looked briefly at argo events and it doesn't support a polling event on repos which means it could only do webooks. That wont work due as the local cluster is not exposed to the internet.
- created a seeder and migration script job in the api to populate the table and data for the mapping
- created a basic db terraform setup
- make things simple to reduce any issues and the need to manage secrets and set the postgres user pw to password

### 2:00pm

Final testing an tweaking, tested few things and found little bugs here and there. Wrote up a installation guide, will be testing the IaC syncing part now and the general code of the api to see how it handles now all the infra is setup and i am happy with it.

### 2:21pm

So after some testing it seems to be working as expected. There is a behaviour with argocd that when polling its around every 3 minutes before you see changes and it will run the updates, this would not be an issue with webhooks if the cluster was routable.

- would like to test a couple more times and do a full tests in a new repo.
- restarting the database behaviour wasn't implemented, would of been very simple if the cluster was accesssable by the ci platform. A way around I thought of was to create a Cron resource with a script to watch the repo but i feel like its un needed at this point.