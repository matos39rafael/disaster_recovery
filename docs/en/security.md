# Security

> 🌐 Languages: English | [Português (Brasil)](../pt-BR/security.md)

## 1. Objective

This document describes the main security controls adopted in the Disaster Recovery lab.

The focus was to reduce the attack surface, avoid unnecessary service exposure,
and use native authentication and authorization mechanisms whenever possible.

---

## 2. Adopted Principles

The architecture was designed based on the following principles:

- least privilege;
- reduced exposed surface;
- no static credentials stored on EC2;
- remote administration without public SSH;
- application publishing without direct port exposure;
- separation between code and secrets;
- validation before traffic changes;
- reproducible infrastructure through code.

---

## 3. Administrative Access

### AWS Environment

The EC2 instance in the DR environment is administered through AWS Systems Manager
Session Manager.

Public exposure of TCP/22 is not used.

Flow:

```text
Admin Workstation
       ↓
AWS Systems Manager
       ↓
EC2
```

This model reduces the need for direct administrative access from the Internet.

### On-Premises Environment

The on-premises server is accessed through SSH using key-based authentication.

Administrative access is used by orchestration scripts during operations such
as restore and failback.

---

## 4. IAM

The EC2 instance uses an IAM Role associated through an Instance Profile.

The permissions allow the instance to access only the services required for the
DR environment, mainly:

- AWS Systems Manager;
- Amazon S3.

The goal is to avoid storing Access Key and Secret Access Key credentials inside
the EC2 instance.

Permissions should follow the principle of least privilege, limiting access to
the resources required by the lab.

---

## 5. Network Security

The EC2 instance runs inside an Amazon VPC and is protected by a Security Group.

The architecture does not require:

- public SSH;
- direct exposure of the application port;
- public ingress for administration.

Outbound traffic is used to communicate with required external services,
including AWS and Cloudflare.

Although the EC2 instance is placed in a public subnet, the application is not
published directly through a public IP address or inbound rule.

---

## 6. Application Publishing

External access to the application is provided through Cloudflare Tunnel.

Simplified flow:

```text
Internet
   ↓
Cloudflare
   ↓
Cloudflare Tunnel
   ↓
Application
```

This model avoids directly exposing the application port to the Internet.

The same approach is used in both the on-premises and DR environments.

---

## 7. Containers

The application runs in Docker containers.

Whenever applicable, containers use a non-root user to reduce the impact of a
potential application compromise.

Volumes required for persistence are mounted only where needed by the service.

---

## 8. Data Protection

The bucket used to store SQLite replicas has versioning enabled.

This makes it possible to recover previous object versions if the latest version
of the database or replica is corrupted or unsuitable for restoration.

This control adds an additional layer of protection against corruption,
overwrite, or recovery from an undesired state.

---

## 9. Secrets and Credentials

Credentials and tokens must not be stored in the Git repository.

AWS Systems Manager Parameter Store was used for secrets required by the DR environment.

Parameters were created and updated through the AWS CLI instead of Terraform to
prevent sensitive values from being persisted in the Terraform State.

Sensitive data used by the lab includes:

- AWS authentication credentials;
- Cloudflare API Token;
- credentials used by Litestream and the application;
- `.env` files;
- SSH keys.

These files and values must remain outside version control.

AWS authentication from the administrative workstation is performed through the
local AWS CLI configuration.

---

## 10. DNS Transition Security

DNS routing is managed by Terraform through the Cloudflare Provider.

Traffic changes should only occur after:

- restore completion;
- integrity validation;
- application startup;
- successful healthcheck.

This reduces the risk of routing users to an environment that is not yet functional.

---

## 11. Applied Controls

| Control | Implementation |
|---|---|
| EC2 administration | AWS Systems Manager Session Manager |
| Public SSH in AWS | Not used |
| Direct application exposure | Not used |
| External publishing | Cloudflare Tunnel |
| EC2 AWS authorization | IAM Role / Instance Profile |
| Static credentials on EC2 | Not used |
| Container application protection | Non-root user |
| DNS management | Terraform + Cloudflare Provider |
| Secret protection | Kept outside the repository |
| Pre-cutover validation | Database + healthcheck |

## 12. Security Limitations

Because this is a lab environment, some controls typically expected in production
were not implemented.

Main limitations include:

- no Multi-AZ architecture;
- no centralized secrets management;
- no dedicated WAF for the DR environment;
- no centralized security monitoring;
- no automated credential rotation;
- dependency on the administrative workstation;
- no automated pipeline for security validation of code and infrastructure.

These points represent opportunities for future improvement.

---

## 13. Future Improvements

Possible improvements include:

- more restrictive IAM policies;
- centralized security logs;
- security event alerts;
- automated Terraform code analysis;
- automated Docker image scanning;
- security validation in a CI/CD pipeline;
- additional WAF and rate-limiting rules at the Cloudflare layer;
- automated rotation of secrets stored in Parameter Store.
