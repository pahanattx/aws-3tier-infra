# Production-Style 3-Tier AWS Infrastructure with TeamOps

A portfolio project demonstrating a secure 3-tier AWS architecture provisioned with Terraform and Terragrunt, together with a full-stack Task and Incident Management application called **TeamOps**.

## Project Overview

This project was built to demonstrate practical Cloud, DevOps, Infrastructure as Code, networking, security, monitoring, and application deployment skills.

The infrastructure spans multiple AWS Availability Zones and separates the platform into Web, Application, and Database tiers.

TeamOps provides role-based task and incident management for a technical operations team.

---

## Final Deployed Architecture

TeamOps is deployed using a secure three-tier AWS architecture with the Web, Application, and Database tiers isolated inside a custom VPC.

```text
Internet / User
       |
       | HTTPS
       v
Amazon API Gateway HTTP API
       |
       | VPC Link
       v
Private Web Application Load Balancer
       |
       v
Web Auto Scaling Group
2 EC2 instances across 2 Availability Zones
NGINX + TeamOps frontend
       |
       v
Internal Application Load Balancer
       |
       v
Application Auto Scaling Group
2 EC2 instances across 2 Availability Zones
Node.js / Express TeamOps API
       |
       v
Private Amazon RDS MySQL
```

### Architecture Highlights

- Public HTTPS access is provided through an Amazon API Gateway HTTP API.
- API Gateway connects to the private Web ALB through an API Gateway VPC Link.
- The Web ALB remains private and forwards traffic only to the Web Auto Scaling Group.
- The Web tier runs NGINX and serves the TeamOps frontend.
- NGINX proxies `/api/*` requests to the internal Application ALB.
- The Application tier runs the TeamOps Node.js/Express backend across two Availability Zones.
- Amazon RDS MySQL remains private and is accessible only from the Application tier.
- Database credentials are retrieved at runtime from AWS Secrets Manager using the Application EC2 IAM role.
- EC2 administration uses AWS Systems Manager Session Manager instead of public SSH access.
- Auto Scaling Groups use rolling instance refreshes for application deployment.
- Web and Application target groups were verified with two healthy targets each.
- End-to-end health testing confirmed connectivity from the Web tier through the Application tier to RDS.
- TeamOps authentication and role-based access were successfully tested through the public HTTPS endpoint.

### Infrastructure Components

- Custom VPC
- Multiple Availability Zones
- Public and private subnets
- Internet Gateway
- NAT Gateway design
- Amazon API Gateway HTTP API
- API Gateway VPC Link
- Private Web Application Load Balancer
- Internal Application Load Balancer
- Web Auto Scaling Group
- Application Auto Scaling Group
- Amazon RDS MySQL
- AWS Systems Manager Session Manager
- IAM instance roles
- AWS Secrets Manager integration
- Amazon CloudWatch metrics, dashboards and alarms
- Terraform modules
- Terragrunt environment configuration

---

## Original Planned Architecture

The original edge architecture for the project was designed around Amazon CloudFront in front of the private Web tier.

```text
Internet / User
       |
       v
CloudFront
       |
       v
Private Web Load Balancer
       |
       v
Web Auto Scaling Group
       |
       v
Internal Application Load Balancer
       |
       v
Application Auto Scaling Group
       |
       v
Amazon RDS MySQL
```

This design was retained in the repository as a separate CloudFront infrastructure module.

During deployment, AWS account verification restricted creation of the CloudFront distribution.

The project therefore uses Amazon API Gateway HTTP API with a VPC Link as the working public HTTPS entry point while keeping the Web ALB private.

### CloudFront Design

The infrastructure repository contains a CloudFront design using a CloudFront VPC Origin in front of the private Web ALB.

The Terraform configuration and VPC Origin design were validated, but AWS blocked creation of the CloudFront distribution because the AWS account requires additional CloudFront service verification.

The partially created VPC Origin was removed after the failed deployment.

To complete the working deployment without exposing the Web ALB publicly, an Amazon API Gateway HTTP API with a VPC Link was deployed as the HTTPS entry point.

Once the AWS account is approved for new CloudFront resources, CloudFront can replace the API Gateway edge layer without redesigning the Web, Application, or Database tiers.

> This project demonstrates a production-style architecture. The Amazon RDS deployment remains Single-AZ because of AWS Free Plan constraints, so the project does not claim full high availability across every tier.

---

## Security Design

The platform follows a layered security-group model.

```text
Internet / User
       |
       | HTTPS
       v
API Gateway
       |
       | VPC Link
       v
Private Web ALB
       |
       v
Web EC2
       |
       v
Internal App ALB
       |
       v
App EC2
       |
       v
RDS MySQL
```

Key controls include:

- Public traffic enters through an HTTPS API Gateway endpoint.
- The Web ALB remains private.
- No SSH access is exposed to EC2 instances.
- AWS Systems Manager Session Manager is used for administrative access.
- Web and Application compute tiers are deployed in private subnets.
- Amazon RDS is deployed in private database subnets.
- RDS accepts MySQL traffic only from the Application tier.
- Application instances retrieve database credentials from AWS Secrets Manager.
- Database passwords are not stored in the Git repository.
- IAM roles provide controlled access to AWS services.
- IMDSv2 is required on EC2 instances.
- Session cookies use `Secure`, `HttpOnly`, and `SameSite` controls when accessed through HTTPS.
- Security groups restrict traffic between the Web, Application, and Database tiers.

---

## Network Layout

VPC:

```text
10.30.0.0/16
```

### Availability Zone A

```text
Public       10.30.0.0/24
Private Web  10.30.10.0/24
Private App  10.30.20.0/24
Private DB   10.30.30.0/24
```

### Availability Zone B

```text
Public       10.30.1.0/24
Private Web  10.30.11.0/24
Private App  10.30.21.0/24
Private DB   10.30.31.0/24
```

The network design separates internet-facing routing components from private Web, Application, and Database workloads.

---

## TeamOps Application

TeamOps is an internal technical-operations work management application.

It is designed around:

```text
Company
   |
   v
Projects / Systems
   |
   v
Project Members
   |
   +-------------------+
   |                   |
   v                   v
Tasks              Incidents
```

### Features

- Secure login
- Role-based access
- Project membership
- Task assignment
- Incident ownership
- Priority and severity management
- Task status workflow
- Incident status workflow
- Resolution notes
- Activity history
- Team workload overview
- Project-based work visibility

### User Roles

TeamOps supports technical-team roles such as:

- Team Lead
- Frontend
- Backend
- QA
- Cloud
- Support

Users can also have a seniority level such as Junior, Mid, or Senior.

Seniority is stored separately from authorization roles.

### Project Stages

Projects can use the following lifecycle stages:

```text
Development
Maintenance
Archived
```

Archived projects are treated as read-only.

---

## Task Workflow

```text
Open
  |
  v
In Progress
  |
  v
Done
```

An in-progress task that is reassigned is reset to `Open` so the new assignee explicitly starts the work.

### Task Rules

For an `Open` task, authorized users can manage:

- Title
- Description
- Category
- Priority
- Assignee

For an `In Progress` task:

- Title is locked.
- Description is locked.
- Category is locked.
- Priority can still be changed where authorized.
- Assignee can still be changed where authorized.
- Reassignment resets the task to `Open`.

A `Done` task is treated as read-only.

---

## Incident Workflow

```text
New
  |
  v
Investigating
  |
  v
Resolved
```

An investigating incident that is reassigned is reset to `New`.

Resolved incidents retain their resolution note and completion timestamp.

### Incident Rules

For a `New` incident, authorized users can manage:

- Title
- Description
- Category
- Severity
- Owner

For an `Investigating` incident:

- Title is locked.
- Description is locked.
- Category is locked.
- Severity can still be changed where authorized.
- Owner can still be changed where authorized.
- Reassignment resets the incident to `New`.

A resolution note is required when an incident is resolved.

Resolved incidents are treated as read-only.

---

## Role-Based Assignment

Task and incident assignment is validated both in the frontend and backend.

| Category | Eligible Role |
|---|---|
| Frontend | Frontend / Team Lead |
| Backend | Backend / Team Lead |
| QA | QA / Team Lead |
| Infrastructure | Cloud / Team Lead |
| Support | Support / Team Lead |
| General | Any project member |

Team Leads can manage work across the project while regular team members operate within their relevant assignments and project visibility.

---

## Authentication and Sessions

TeamOps uses database-backed authentication sessions.

Sessions are stored in the database so multiple Application EC2 instances can share authentication state.

The application uses a same-origin session cookie named:

```text
teamops_session
```

The cookie uses security controls including:

- `HttpOnly`
- `Secure` when accessed through HTTPS
- `SameSite`

This allows the application to operate correctly behind the load-balanced multi-instance architecture.

---

## Application Stack

### Frontend

- HTML
- CSS
- JavaScript
- NGINX

### Backend

- Node.js
- Express.js
- MySQL2
- bcryptjs
- AWS SDK for JavaScript

### Database

- MySQL / MariaDB locally
- Amazon RDS MySQL for AWS deployment

Authentication sessions are stored in the database so multiple application instances can share session state.

---

## Database Design

The TeamOps database includes core tables for:

- Users
- Projects
- Project members
- Tasks
- Incidents
- Activity logs
- Authentication sessions

```text
users
projects
project_members
tasks
incidents
activity_logs
auth_sessions
```

The database supports role-based work assignment, authentication, project membership, task tracking, incident tracking, and activity history.

Passwords are stored using password hashes rather than plaintext credentials.

---

## Infrastructure as Code

Infrastructure is separated into reusable Terraform modules.

```text
modules/
├── alb
├── api-gateway
├── cloudfront
├── compute
├── iam
├── monitoring
├── networking
├── rds
├── secrets-access
├── security
└── vpc-endpoints
```

Terragrunt manages the production environment under:

```text
live/prod/
```

The infrastructure is managed with Terraform through Terragrunt rather than manual resource creation wherever practical.

Infrastructure changes are reviewed using Terraform/Terragrunt plans before applying them.

---

## Repository Structure

```text
aws-3tier-infra/
│
├── app/
│   ├── backend/
│   ├── database/
│   └── frontend/
│
├── bootstrap/
│
├── live/
│   └── prod/
│
├── modules/
│
└── README.md
```

### Application Directory

```text
app/
├── backend/
├── database/
└── frontend/
```

The application source is deployed to the Web and Application EC2 tiers through instance bootstrap configuration.

---

## Compute and Auto Scaling

The Web and Application tiers are deployed using EC2 Auto Scaling Groups.

### Web Tier

The Web tier runs:

- NGINX
- TeamOps frontend
- API reverse proxy configuration

The Web Auto Scaling Group maintains application instances across multiple Availability Zones.

### Application Tier

The Application tier runs:

- Node.js
- Express.js
- TeamOps backend API
- Runtime database secret retrieval

The Application Auto Scaling Group also spans multiple Availability Zones.

### Rolling Deployment

Auto Scaling Groups use rolling instance refreshes so updated launch-template configurations can replace instances in a controlled manner.

This was used to deploy the final TeamOps application version without manually replacing individual EC2 instances.

---

## Load Balancing

The architecture uses two Application Load Balancers.

### Web Load Balancer

The Web ALB is private.

Public users do not connect directly to it.

Traffic reaches the Web ALB through:

```text
API Gateway
   |
   v
VPC Link
   |
   v
Private Web ALB
```

### Application Load Balancer

The Application ALB is internal.

It receives application API traffic from the Web tier and forwards requests to the Application Auto Scaling Group.

```text
Web Tier
   |
   v
Internal App ALB
   |
   v
Application Tier
```

---

## API Gateway

Amazon API Gateway HTTP API provides the working public HTTPS entry point for TeamOps.

The API Gateway configuration uses a VPC Link to reach the private Web Application Load Balancer.

```text
HTTPS
   |
   v
API Gateway HTTP API
   |
   v
VPC Link
   |
   v
Private Web ALB
```

This allows the application to be accessed publicly without changing the Web ALB to an internet-facing load balancer.

The API Gateway infrastructure is managed through Terraform and Terragrunt.

---

## Monitoring

AWS CloudWatch was configured to monitor infrastructure health and performance.

Monitoring included:

- Web ASG desired vs in-service capacity
- Application ASG desired vs in-service capacity
- ALB request count
- ALB target response time
- RDS CPU utilization
- RDS free storage space
- Unhealthy target alarms
- RDS CPU alarm
- RDS storage alarm

A CloudWatch dashboard was created to provide infrastructure-level visibility for the TeamOps deployment.

---

## Deployment Verification

The final deployment was verified across the full three-tier path.

### Target Health

Both infrastructure tiers were verified with healthy load-balancer targets:

```text
Web Target Group
2 / 2 healthy

Application Target Group
2 / 2 healthy
```

### Application Health

The Application tier health endpoint confirmed:

```text
Application status: healthy
Database: connected
Application version: teamops-flow-v4
```

### End-to-End Private Path

Testing confirmed the internal application path:

```text
Web EC2
   |
   v
Internal App ALB
   |
   v
App EC2
   |
   v
Amazon RDS MySQL
```

### Public HTTPS Path

The final public path was also verified:

```text
Internet
   |
   | HTTPS
   v
API Gateway
   |
   v
VPC Link
   |
   v
Private Web ALB
   |
   v
Web ASG
   |
   v
Internal App ALB
   |
   v
App ASG
   |
   v
RDS
```

The public endpoint successfully returned HTTP `200`.

TeamOps login was successfully tested through the HTTPS endpoint using a Team Lead account.

---

## AWS Systems Manager

EC2 administration uses AWS Systems Manager Session Manager instead of SSH.

This removes the need for:

- SSH key pairs
- Port 22 exposure
- Public administrative access to EC2 instances

Systems Manager was also used during deployment verification and application health testing.

---

## Secrets Management

Amazon RDS master credentials are managed through AWS Secrets Manager.

Application EC2 instances retrieve the required database credentials at runtime through their IAM role.

The repository does not contain plaintext production database passwords.

The application bootstrap process provides database configuration to the Node.js application process without committing sensitive values to source control.

---

## IAM Design

IAM instance roles are used to provide AWS permissions to EC2 instances.

Examples include:

- AWS Systems Manager access
- Runtime access to the required Secrets Manager database secret

IAM access is kept separate from application source code and credentials are not hardcoded into the repository.

---

## EC2 Metadata Security

EC2 instances require IMDSv2.

This provides stronger protection for access to EC2 instance metadata and temporary IAM credentials.

---

## RDS Design

The project uses Amazon RDS MySQL with:

- Private database subnets
- Encrypted storage
- Managed master credentials
- Secrets Manager integration
- Restricted security-group access
- Automated backup configuration

The deployed database instance is Single-AZ because the AWS Free Plan used for this project did not allow an RDS Multi-AZ deployment.

The wider Web and Application infrastructure spans multiple Availability Zones.

The project therefore does not claim that the entire stack is fully Multi-AZ or fully highly available.

---

## CloudFront

CloudFront integration was designed for private origin access to the Web tier.

The repository includes a separate CloudFront Terraform module using a CloudFront VPC Origin design.

During development, AWS account verification restricted creation of the final CloudFront distribution.

The Terraform configuration was valid, but AWS returned an account-verification restriction when attempting to create the distribution.

A VPC Origin resource that had been created during the failed deployment was later removed cleanly through Terraform/Terragrunt.

The repository therefore retains the CloudFront design without claiming that the distribution is currently deployed.

The working public entry point is Amazon API Gateway HTTP API with a VPC Link.

---

## Cost Management

The project was built using AWS Free Plan credits with active cost controls.

During development, expensive infrastructure components were removed, stopped, or scaled down when not required while Terraform/Terragrunt configuration was retained for reproducible deployment.

Cost-control decisions included:

- Avoiding unnecessary permanent resource usage
- Stopping development resources when practical
- Destroying unused infrastructure through Terraform/Terragrunt
- Removing the partially created CloudFront VPC Origin after CloudFront deployment was blocked
- Retaining Infrastructure as Code so resources can be recreated later
- Avoiding unnecessary manual infrastructure changes

The architecture can be recreated using the Terraform/Terragrunt configuration when demonstration or testing is required.

---

## Security Notes

This repository intentionally excludes:

- `.env` files
- AWS credentials
- Terraform state
- Private keys
- Account-specific identifiers
- Sensitive database credentials

Environment-specific state configuration is supplied outside the repository.

Sensitive values such as:

- AWS access keys
- Database passwords
- Secrets Manager values
- Terraform state
- Account-specific resource identifiers

must not be committed to the repository.

---

## Local Application Setup

Install backend dependencies:

```bash
cd app/backend
npm install
```

Create a private `.env` file with the required database and application settings.

Then run:

```bash
npm start
```

The `.env` file must not be committed to Git.

---

## AWS Deployment Model

The AWS deployment does not depend on the local `.env` file for production database credentials.

Instead:

```text
Application EC2 IAM Role
        |
        v
AWS Secrets Manager
        |
        v
RDS Credentials
        |
        v
TeamOps Node.js Process
```

Application instances retrieve database credentials dynamically at runtime.

---

## Application Version

The deployed TeamOps application health endpoint identifies the current application flow version as:

```text
teamops-flow-v4
```

This version includes the finalized task and incident workflows, role-based authorization, project visibility, authentication, activity logging, and database-backed sessions.

---

## Skills Demonstrated

- AWS architecture
- Terraform
- Terragrunt
- Infrastructure as Code
- VPC design
- Multi-AZ networking
- Public and private subnet design
- Auto Scaling
- Rolling instance refresh
- Application Load Balancing
- Amazon API Gateway
- API Gateway VPC Link
- IAM
- AWS Systems Manager
- Secrets Manager
- Amazon RDS
- CloudWatch
- EC2 security
- IMDSv2
- NGINX
- Node.js
- Express.js
- MySQL
- Database-backed authentication sessions
- Role-based authorization
- Application deployment
- Infrastructure troubleshooting
- Git and GitHub

---

## Project Limitations and Design Decisions

This project intentionally documents its limitations instead of presenting features that were not actually deployed.

### RDS Availability

Amazon RDS is deployed as Single-AZ because of the AWS Free Plan constraints used during the project.

The Web and Application tiers span multiple Availability Zones, but the project does not claim full high availability across every tier.

### CloudFront

The CloudFront architecture was designed and represented in Terraform, but the final CloudFront distribution could not be created because of an AWS account verification restriction.

The final working public HTTPS architecture therefore uses:

```text
API Gateway HTTP API
        |
        v
VPC Link
        |
        v
Private Web ALB
```

### Portfolio Accuracy

The repository only claims infrastructure and application functionality that was actually implemented or tested.

---

## Final Status

Core infrastructure, application workflows, authentication, database integration, monitoring, Infrastructure as Code, private load balancing, API Gateway ingress, Systems Manager administration, and Secrets Manager integration have been implemented and tested during development.

The final tested request path is:

```text
Internet / User
       |
       | HTTPS
       v
Amazon API Gateway HTTP API
       |
       | VPC Link
       v
Private Web ALB
       |
       v
Web Auto Scaling Group
       |
       v
Internal App ALB
       |
       v
Application Auto Scaling Group
       |
       v
Amazon RDS MySQL
```

The Web and Application target groups were verified healthy, database connectivity was confirmed, the TeamOps v4 health endpoint was validated, and login through the public HTTPS endpoint was successfully tested.

The repository is maintained as a reproducible portfolio implementation, with AWS resources scaled down or removed when not actively required to control cloud cost.