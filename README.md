## Mert Alnuaimi - Solution
The repository is made into a fully working Terraform deployment with the application running live on AWS at:<br>https://go.app.faceit.challenge-task.link/health
### FACEIT Infra Diagram
![faceit-infra-diagram](diagrams/faceit_infra.png)

### FACEIT CICD Diagram
![faceit-cicd-diagram](diagrams/faceit_cicd.png)

Notes:
- The solution dockerizes the Go application and pushes it to ECR.
- The application is deployed to an ECS cluster in 2 AZs.
- The application is fronted with an ALB for load balancing.
- The application receives the RDS Postgres credentials as environment variables in the container runtime.
- The RDS Postgres credentials are generated by Terraform and stored in SSM.
-  






# FACEIT DevOps Challenge

You have been asked to create the infrastructure for running a web application on a cloud platform of your preference (Google Cloud Platform preferred, AWS or Azure are also fine).

The [web application](test-app/README.md) can be found in the `test-app/` directory. Its only requirements are to be able to connect to a PostgreSQL database and perform PING requests.    

The goal of the challenge is to demonstrate hosting, managing, documenting and scaling a production-ready system.

This is not about website content or UI.

## Requirements

- Deliver the tooling to set up the application using Terraform on the cloud platform of your choice (free tiers are fine)
- Provide basic architecture diagrams and documentation on how to initialise the infrastructure along with any other documentation you think is appropriate
- Provide and document a mechanism for scaling the service and delivering the application to a larger audience
- Describe a possible solution for CI and/or CI/CD in order to release a new version of the application to production without any downtime

Be prepared to explain your choices

## Extra Mile Bonus (not a requirement)

In addition to the above, time permitting, consider the following suggestions for taking your implementation a step further:

- Monitoring/Alerting
- Implement CI/CD (github actions, travis, circleci, ...)
- Security

## General guidance

- We recommend using this repository as a starting point, you can clone it and add your code/docs to that repository
- Please do no open pull request with your challenge against **this repository**
- Submission of the challenge can be done either via your own public repository or zip file containing `.git` folder

