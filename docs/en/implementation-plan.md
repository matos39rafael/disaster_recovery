# Implementation Plan

> 🌐 Languages: English | [Português (Brasil)](../pt-BR/implementation-plan.md)

## 1. Objective

Implement and validate a Disaster Recovery strategy between an on-premises
environment and AWS for a containerized application using a SQLite database.

The solution should enable:

- continuous database replication to Amazon S3;
- on-demand provisioning of the DR environment;
- application restoration in AWS after an outage;
- controlled failover;
- temporary operation in the DR environment;
- return of operations to the on-premises environment through failback;
- integrity and availability validation before traffic changes;
- RTO measurement and RPO assessment;
- reproducible infrastructure using Infrastructure as Code.

---

## 2. Implementation Approach

The project was developed incrementally, with functional validation of the
main components throughout the implementation.

Although it was not conducted as a formal Scrum project, concepts compatible
with Agile practices were adopted, including:

- decomposition of work into increments;
- technical backlog;
- acceptance criteria;
- continuous validation;
- Definition of Done;
- iterative evolution of the solution;
- risk and decision documentation;
- evidence collection.

The final solution code is versioned in the Git repository.

---

## 3. Scope

### In Scope

- containerized Flask application;
- SQLite database;
- Docker and Docker Compose;
- Litestream;
- replication to Amazon S3;
- AWS infrastructure with Terraform;
- Amazon EC2;
- Amazon VPC;
- Security Groups;
- IAM Role and Instance Profile;
- AWS Systems Manager Session Manager;
- Cloudflare Tunnel;
- DNS management with Terraform;
- Bash automation;
- failover from on-premises → AWS;
- temporary operation in the DR environment;
- failback from AWS → on-premises;
- database validation;
- healthchecks;
- RTO measurement;
- RPO analysis;
- documentation and evidence.

### Out of Scope

- Multi-AZ architecture;
- High Availability;
- managed database;
- active-active replication;
- fully automated recovery;
- complete CI/CD;
- failover without human intervention;
- real production environment.

---

## 4. Assumptions and Constraints

### Assumptions

- the on-premises environment is operational under normal conditions;
- only one environment serves production traffic at a time;
- Amazon S3 is used as the intermediate recovery point;
- Terraform represents the desired state of AWS infrastructure and DNS;
- the DR environment is provisioned on demand;
- the administrative workstation has access to the required environments.

### Constraints

- low-cost focus;
- single EC2 instance in the DR environment;
- SQLite database;
- dependency on Cloudflare for application publishing;
- dependency on an administrative workstation to run Terraform and scripts;
- no fully autonomous orchestration.

---

## 5. Prerequisites

### Administrative Workstation

- Terraform
- AWS CLI
- Git
- Bash
- SSH client

### AWS

- AWS account;
- valid authentication;
- required permissions;
- configured region;
- access to the AWS services used in the lab.

### Cloudflare

- managed domain;
- Cloudflare Tunnel;
- API Token;
- Cloudflare provider configured in Terraform.

### On-Premises

- Linux;
- Docker;
- Docker Compose;
- Flask;
- SQLite;
- Litestream;
- Traefik;
- SSH key-based access.

---

# 6. High-Level Backlog

The work was conceptually organized into the following epics.

## Epic 1 — Data Protection

Objective:

Ensure that application state can be recovered after loss of the primary
environment.

Main items:

- Litestream configuration;
- SQLite → S3 replication;
- database restore;
- integrity validation.

**Status:** Completed

---

## Epic 2 — AWS Disaster Recovery Infrastructure

Objective:

Create reproducible infrastructure capable of running the application in AWS.

Main items:

- VPC;
- subnet;
- routing;
- Security Group;
- EC2;
- IAM;
- Systems Manager;
- Terraform.

**Status:** Completed

---

## Epic 3 — Application Recovery

Objective:

Automatically restore the application and its data in the DR environment.

Main items:

- EC2 bootstrap;
- Docker;
- SQLite restore;
- application startup;
- healthcheck.

**Status:** Completed

---

## Epic 4 — Traffic Management

Objective:

Control which environment receives application traffic.

Main items:

- on-premises Cloudflare Tunnel;
- DR Cloudflare Tunnel;
- DNS managed through Terraform;
- DNS failover;
- DNS failback.

**Status:** Completed

---

## Epic 5 — Disaster Recovery Operations

Objective:

Validate the complete recovery cycle.

Main items:

- failover;
- DR operation;
- persistence during DR;
- failback;
- cleanup.

**Status:** Completed

---

## Epic 6 — Documentation and Evidence

Objective:

Document the architecture, decisions, and lab results.

**Status:** In progress

---

# 7. Implementation Phases

## Phase 1 — Structure and Foundation

### Objective

Prepare the project and its core components.

### Main Deliverables

- repository structure;
- Terraform;
- Docker files;
- scripts;
- documentation organization.

### Acceptance Criteria

- Terraform initializes correctly;
- reproducible structure;
- sensitive files are not versioned;
- required code is available in the repository.

### Status

**Completed**

---

## Phase 2 — Database Replication

### Objective

Ensure a recoverable external copy of SQLite.

### Deliverables

- Litestream configuration;
- Amazon S3;
- continuous replication;
- restore test.

### Acceptance Criteria

- database replicated to S3;
- recent backup available;
- restore completed successfully;
- `PRAGMA integrity_check` returns `ok`;
- expected data is present after restore.

### Status

**Completed**

---

## Phase 3 — AWS Infrastructure

### Objective

Create the infrastructure required to run the DR environment.

### Deliverables

- VPC;
- subnet;
- routing;
- Internet Gateway;
- Security Group;
- EC2;
- IAM Role;
- Instance Profile;
- Systems Manager.

### Acceptance Criteria

- infrastructure created by Terraform;
- EC2 initialized correctly;
- SSM access operational;
- no public SSH port required;
- outbound connectivity available.

### Status

**Completed**

---

## Phase 4 — Bootstrap and Application Recovery

### Objective

Automatically initialize the DR environment.

### Deliverables

- `user_data.sh`;
- Docker installation/preparation;
- application configuration;
- Litestream;
- database restore;
- healthcheck.

### Acceptance Criteria

- bootstrap completed;
- containers started;
- database restored;
- database integrity confirmed;
- application healthy.

### Status

**Completed**

---

## Phase 5 — Failover

### Objective

Validate application recovery after primary environment unavailability.

### Validated Flow

```text
On-Premises failure
        ↓
Terraform plan
        ↓
Terraform apply
        ↓
AWS DR provisioning
        ↓
SQLite restore
        ↓
Database validation
        ↓
Application healthcheck
        ↓
DNS cutover
        ↓
AWS DR active
```

### Acceptance Criteria

- primary environment unavailable;
- DR provisioned;
- database restored;
- database integrity confirmed;
- application healthy;
- DNS pointing to DR;
- external access validated;
- evidence collected.

### Status

**Completed**

---

## Phase 6 — Operation in the DR Environment

### Objective

Demonstrate that the DR environment can temporarily take over operations.

### Acceptance Criteria

- application operational in AWS;
- new data can be written;
- Litestream continues replicating;
- data produced during DR is sent to S3.

### Status

**Completed**

---

## Phase 7 — Failback

### Objective

Return the application and updated data to the on-premises environment.

### Validated Flow

```text
AWS DR active
      ↓
Stop / control writes
      ↓
Final replication to S3
      ↓
Restore on-premises
      ↓
Database integrity validation
      ↓
Application healthcheck
      ↓
DNS failback
      ↓
On-Premises active
      ↓
AWS DR cleanup
```

### Acceptance Criteria

- final replication completed;
- database restored on-premises;
- `PRAGMA integrity_check` returns `ok`;
- record created during DR is present;
- on-premises application is healthy;
- DNS returns to the primary environment;
- external access is validated;
- DR environment can be deprovisioned.

### Status

**Completed**

---

## Phase 8 — Documentation and Closure

### Objective

Consolidate the lab results and evidence.

### Deliverables

- README;
- architecture;
- implementation plan;
- security documentation;
- monitoring;
- cost analysis;
- troubleshooting;
- lessons learned;
- evidence;
- RTO;
- RPO.

### Acceptance Criteria

- documentation updated;
- evidence available;
- no secrets published;
- internal links validated;
- PT-BR version completed;
- English version created.

### Status

**In progress**

---

## 8. Definition of Done

A project deliverable is considered complete when, where applicable:

- the required implementation is present in the repository;
- configuration has been validated;
- expected behavior has been tested;
- functional validation has been completed;
- no secret has been versioned;
- relevant known failures have been documented;
- evidence has been collected;
- related documentation has been updated.

For Terraform changes:

```text
terraform fmt
      ↓
terraform validate
      ↓
terraform plan
      ↓
review
      ↓
terraform apply
      ↓
functional validation
```

The final implementation required to reproduce the lab must be versioned in the
repository.

---

## 9. Success Metrics

### RTO

Measured time between completion of the application stack shutdown in the
on-premises environment and the first confirmation that the application was
available through the DR environment.

**Result: 3 min 43 s**

### RPO

Difference between the last confirmed state in the primary environment and the
state recovered in the DR environment.

**Result: Not measured in a controlled manner**

> RPO was not measured in a controlled manner during this execution. The solution
> uses continuous and asynchronous SQLite replication to Amazon S3 through
> Litestream, so the expected RPO is low, but it was not empirically validated in
> this test.

### Integrity

The restored database must return:

`PRAGMA integrity_check → ok`

### Data Continuity

Data written during DR operation must be recovered in the on-premises environment
during failback.

### Reproducibility

The DR infrastructure must be reproducible using only:

- versioned code;
- environment/configuration variables;
- valid credentials;
- data persisted in S3.

---

## 10. Current Project Status

| Deliverable | Status |
|---|---|
| On-premises application | Completed |
| SQLite → S3 replication | Completed |
| AWS Terraform infrastructure | Completed |
| EC2 bootstrap | Completed |
| DR restore | Completed |
| SSM | Completed |
| DR Cloudflare Tunnel | Completed |
| Failover | Completed |
| DNS transition to AWS | Completed |
| DR operation | Completed |
| Failback | Completed |
| DNS failback | Completed |
| Final cleanup | Completed |
| Final evidence | Completed |
| Documentation | In progress |

---

## 11. Project Completion Criteria

The lab will be considered complete when:

- infrastructure is versioned and reproducible;
- on-premises → S3 replication has been validated;
- the DR environment can be provisioned on demand;
- restore in AWS has been validated;
- complete failover has been executed;
- the application has operated in the DR environment;
- data produced in DR has been replicated;
- failback has been successfully executed;
- data created during DR has been recovered on-premises;
- the on-premises application is healthy after failback;
- DNS has returned to the primary environment;
- temporary resources have been removed;
- RTO has been measured and recorded;
- RPO has been assessed and its limitation documented;
- evidence has been collected;
- documentation has been completed.
