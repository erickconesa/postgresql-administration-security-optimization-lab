# PostgreSQL Infrastructure Architecture & Security Design

**PostgreSQL 17 | Ubuntu Server | Docker | Database Security | Performance Tuning**

## 1. Overview

This document describes the architecture, security controls and administration decisions implemented in a PostgreSQL 17 laboratory running on Ubuntu Server.

The project focuses on database isolation, secure connections, role separation, persistent storage and resource optimization.

It was developed during my second-year practical training in Network Computer Systems Administration (ASIR).

## 2. Infrastructure Architecture

The following diagram represents the general architecture. It intentionally excludes real infrastructure addresses, domains, credentials and internal application details.

```text
              Authorized Client
                     |
                     v
          +---------------------+
          | Application Layer   |
          | Restricted SQL Role |
          +---------------------+
                     |
                     | Private Docker Network
                     | SCRAM-SHA-256 Authentication
                     v
          +---------------------+
          | PostgreSQL 17       |
          | Docker Container    |
          |---------------------|
          | pg_hba.conf ACL     |
          | Role Permissions    |
          | Memory Tuning       |
          +---------------------+
                     |
                     v
          +---------------------+
          | Persistent Docker   |
          | Volume              |
          +---------------------+
```

The application layer communicates with PostgreSQL through an internal Docker network.

The database does not publish its TCP port to the host. Access restrictions are also enforced through PostgreSQL authentication and connection policies.

## 3. Docker Isolation

The database runs in a dedicated PostgreSQL container.

The following controls were implemented and verified:

- PostgreSQL 17.11 using the Alpine-based Docker image.
- Internal Docker backend network.
- No database port published to the host.
- Persistent Docker volume.
- Container memory limit of 512 MiB.
- CPU limit of 0.5 CPU.
- Health checks and availability verification.

### Persistence

The database container was recreated while preserving its Docker volume.

Data persistence was verified by checking the PostgreSQL system identifier and reference record counts before and after recreation.

A logical backup was also created with `pg_dump` in custom format and its contents inspected using `pg_restore -l`.

A complete restoration from that backup was not performed during this control.

## 4. Connection Security

PostgreSQL access is controlled using `pg_hba.conf`.

The laboratory moved from broadly permissive connection rules to a restricted policy using:

- SCRAM-SHA-256 authentication.
- Explicit authorization of the internal backend network.
- Authenticated local connections.
- Explicit rejection of other IPv4 and IPv6 origins.

### Validation

A temporary Docker test network was created to verify the rejection policy.

A client connected from an unauthorized network and received a PostgreSQL rejection:

```text
FATAL: pg_hba.conf rejects connection
```

This demonstrated that the database's own access-control policy was enforced.

The temporary network was removed after the test.

**Security distinction:** SCRAM-SHA-256 protects password authentication; it does not, by itself, encrypt the entire connection. TLS encryption was not validated as part of this laboratory control.

## 5. Role-Based Security

Database permissions were separated according to the principle of least privilege.

| Role type | Responsibilities |
|---|---|
| Administrative | Database administration and recovery |
| DDL owner | Ownership of schema objects and structural changes |
| Service account | SELECT, INSERT, UPDATE and DELETE operations |

The service account was configured without superuser privileges or the ability to create databases or roles.

### Permission Validation

The restricted account successfully performed authorized DML operations.

Attempts to execute `ALTER TABLE` and `DROP TABLE` were rejected.

Test transactions were rolled back to avoid retaining test modifications.

The project also separated application data access from structural database changes.

## 6. Resource Optimization

The PostgreSQL container was limited to 512 MiB of memory and 0.5 CPU.

The configuration was adjusted to match the size of the laboratory.

| Parameter | Initial | Optimized |
|---|---:|---:|
| max_connections | 100 | 30 |
| shared_buffers | 128 MB | 64 MB |
| work_mem | 4 MB | 2 MB |

These values were supplied through PostgreSQL startup arguments in Docker Compose.

The effective settings were verified using `pg_settings`, confirming that no restart remained pending.

A functional concurrency test completed 60 SQL queries using two concurrent connections without errors.

This test did not establish the maximum supported workload.

## 7. SQL Performance Analysis

Three queries were investigated using `EXPLAIN (ANALYZE, BUFFERS)`.

| Query | Observed result | Technical interpretation |
|---|---|---|
| Q1 | 63.6% faster | Composite index selected |
| Q2 | 19.9% faster | Bitmap Index Scan selected |
| Q3 | 13.0% slower | Partial index not selected |

The third result was retained as an unsuccessful optimization attempt.

This demonstrated why query tuning should be based on actual execution plans rather than assumptions.

Further details are available in [Query Performance Analysis](query-performance.md).

## 8. Operational Validation

The final laboratory checks included:

- Database service health.
- Private Docker network isolation.
- PostgreSQL authentication policies.
- Restricted user privileges.
- Effective database tuning parameters.
- Functional database connectivity.
- Review of query execution plans.
- Persistence after controlled container recreation.

The final checks also observed zero temporary files, zero temporary bytes and zero deadlocks in the database statistics at the time of inspection.

These observations do not guarantee that such events could never occur under different workloads.

## 9. Security and Operational Limitations

This is an educational laboratory, not a production-certified architecture.

- No high-availability cluster was implemented.
- A complete database restore was not demonstrated.
- Database TLS encryption was not validated.
- Concurrency testing was limited.
- Performance measurements were taken from specific executions, not sustained load tests.
- The published configurations use placeholders rather than operational network details.

## 10. Skills Demonstrated

- Linux infrastructure administration.
- PostgreSQL deployment and configuration.
- Docker networking and persistence.
- Database authentication and access control.
- Role-based privilege management.
- Memory and concurrency tuning.
- SQL execution plan analysis.
- Backup verification.
- Technical troubleshooting and validation.

---

**Author:** Erick Conesa Pérez  
**Training:** Higher Vocational Training in Network Computer Systems Administration (ASIR)
