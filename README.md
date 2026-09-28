# Production-Grade 3-Tier AWS Infrastructure with TeamOps

A portfolio project demonstrating a secure 3-tier AWS architecture provisioned with Terraform and Terragrunt, together with a full-stack Task and Incident Management application called **TeamOps**.

## Project Overview

This project was built to demonstrate practical Cloud, DevOps, Infrastructure as Code, networking, security, monitoring, and application deployment skills.

The infrastructure spans multiple AWS Availability Zones and separates the platform into Web, Application, and Database tiers.

TeamOps provides role-based task and incident management for a technical operations team.

## Architecture

```text
Internet / User
       |
       v
CloudFront
       |
       v
Web Load Balancer
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

The architecture includes:

- Custom VPC
- Multiple Availability Zones
- Public and private subnets
- Internet Gateway
- NAT Gateway design
- Web Auto Scaling Group
- Application Auto Scaling Group
- Application Load Balancers
- Amazon RDS MySQL
- AWS Systems Manager Session Manager
- IAM instance roles
- AWS Secrets Manager integration
- CloudWatch metrics, dashboards and alarms
- Terraform modules
- Terragrunt environment configuration

## Security Design

The platform follows a layered security-group model.

```text
Web ALB
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

- No SSH access to EC2 instances
- AWS Systems Manager for administrative access
- Private Web and Application compute tiers
- Private database tier
- RDS accepts MySQL traffic only from the Application tier
- Application instances retrieve database credentials from AWS Secrets Manager
- Least-privilege IAM access for database secrets
- IMDSv2 enabled on EC2 instances

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

## TeamOps Application

TeamOps is an internal technical-operations work management application.

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

### Task Workflow

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

### Incident Workflow

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

## Application Stack

### Frontend

- HTML
- CSS
- JavaScript

### Backend

- Node.js
- Express.js
- MySQL2
- bcryptjs

### Database

- MySQL / MariaDB locally
- Amazon RDS MySQL for AWS deployment

Authentication sessions are stored in the database so multiple application instances can share session state.

## Infrastructure as Code

Infrastructure is separated into reusable Terraform modules.

```text
modules/
├── alb
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

## AWS Systems Manager

EC2 administration uses AWS Systems Manager Session Manager instead of SSH.

This removes the need for:

- SSH key pairs
- Port 22 exposure
- Public administrative access to EC2 instances

## RDS Design

The project uses Amazon RDS MySQL with:

- Private database subnets
- Encrypted storage
- Managed master credentials
- Secrets Manager integration
- Restricted security-group access

The deployed database instance is Single-AZ because the AWS Free Plan used for this project did not allow an RDS Multi-AZ deployment.

The wider Web and Application infrastructure spans multiple Availability Zones.

## CloudFront

CloudFront integration was designed for private origin access to the Web tier.

During development, AWS account verification restricted creation of the final CloudFront distribution.

The repository therefore keeps CloudFront infrastructure isolated as a separate module rather than claiming an unverified deployment.

## Cost Management

The project was built using AWS Free Plan credits with active cost controls.

During development, expensive infrastructure components were removed or scaled down when not required while Terraform/Terragrunt configuration was retained for reproducible deployment.

## Security Notes

This repository intentionally excludes:

- `.env` files
- AWS credentials
- Terraform state
- Private keys
- Account-specific identifiers
- Sensitive database credentials

Environment-specific state configuration is supplied outside the repository.

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

## Skills Demonstrated

- AWS architecture
- Terraform
- Terragrunt
- Infrastructure as Code
- VPC design
- Multi-AZ networking
- Auto Scaling
- Load balancing
- IAM
- AWS Systems Manager
- Secrets Manager
- Amazon RDS
- CloudWatch
- Node.js
- Express.js
- MySQL
- Role-based authorization
- Git and GitHub

## Status

Core infrastructure, application workflows, authentication, database integration, monitoring, and Infrastructure as Code have been implemented and tested during development.

The repository is maintained as a reproducible portfolio implementation, with AWS resources scaled down or removed when not actively required to control cloud cost.