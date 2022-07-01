# Description
This repo contains the example app from https://dotnet.microsoft.com/en-us/learn/aspnet/hello-world-tutorial/intro, as well as a simple Dockerfile and a Helm chart for it.

Your goal is to deploy the included application (under `app/`) to the EKS cluster you have created using the provided, rudimentary Dockerfile and Helm chart, in a namespace named as your firstname while also completing the following objectives.

<br>

## Objectives:

1. Enable HPA for the deployment and set the target utilization to 80% for CPU and 85% for memory.
2. Set CPU request to 150m.
3. Make the application highly available.
4. Expose the application via a service to the cluster.
5. Expose the application to the internet. You may use the Route53 zone that has already been created in the provided AWS account, in region `eu-west-1`.
6. Make the application's index page show `Hello {GREET_VAR}` instead of "Hello world", where `GREET_VAR` is an environment variable. The variable should get its value from the `values.yaml` file.
7. Fix the provided Dockerfile, so it runs the application on startup.

<br>

## Notes:
1. Feel free to use any docker registry you want.
2. Document your work, to help us understand your thoughts and implementation.

# Solution
This part is the solution from Minfei He.

## .Net core web app.
**Make the application's index page show `Hello {GREET_VAR}` instead of "Hello world", where `GREET_VAR` is an environment variable. The variable should get its value from the `values.yaml` file.**
For the web app picking up the environment variable ${GREET_VAR}, I defined a string property `Greeting` and use System library to pass system environment variable to the `Greeting` property. As it's in MVC pattern, I just need to pass the property from model to view and display it in the `index.cshtml`.

The environment variable ${GREET_VAR} is defined in the container environment on k8s level instead of passed in during `docker build` phase due to flexibility.

## Docker
**Fix the provided Dockerfile, so it runs the application on startup.**
For this objective, I have seperated the Dockerfile into a builder and server. The server is copying the published file and run it from entry point with `dotnet` command. It makes the docker image light weighted.

## Container Registry
I have manually create a [elastic container registry](https://eu-west-1.console.aws.amazon.com/ecr/repositories?region=eu-west-1) in provided AWS account and a repo in it. I didn't provision it with EKS Terraform project as I think it should be in different life-cycle of EKS. EKS is more on the processing layer and ECR is persistent layer. 

To improve it later, ECR should be managed by Terraform with other AWS resource on persistent layer with their own life-cycle.

## Helm configuration
**Enable HPA for the deployment and set the target utilization to 80% for CPU and 85% for memory.**
**Set CPU request to 150m.**
With helm values.yaml file, we can configure the application.

**Make the application highly available.**
For high availability of the app, HPA is horizontally autoscaling the app under the circumstance that app is overloaded by traffic. I have added Pod Disruption Budget with minimum 1 available pod in the case that system is upgrading or distupted.

**Expose the application via a service to the cluster.**
Since we are exposing application on service layer with HTTP protocol. Service type is configured to `LoadBalancer` and exposed port 80.

**Expose the application to the internet. You may use the Route53 zone that has already been created in the provided AWS account, in region `eu-west-1`.**
Once the Load balancer that is associated with app service, I manually added the DNS record in the provided Route53 hosted zone. It's an A-record that points to the right AWS classic load balancer.

With Helm, I've also added a secret `${mywebapp}-image-pull-secret` template. It generates ECR access secret with registry Url, ECR username and ECR token, which are stored in Azure DevOps library. Deployment is referencing to the `${mywebapp}-image-pull-secret` for pulling the image.

## CI/CD
For CI/CD solution, an Azure DevOps YAML pipeline is provided. It follows
On condition of `install`
    DockerLogin ==> DockerBuild ==> DockerPush ==> EKSAuth ==> HelmDeploy
On condition of `uninstall`
    HelmUninstall

**Improvements**
- To make it production ready, the CI/CD could integrate `linting`, `commit linting`, `unit tests`, `integration tests`, `code quality check` and other best practices.
- Tagging strategy could also be considered and implemented on CI/CD level.
- Pipeline structure can be templated in a centralized way.
