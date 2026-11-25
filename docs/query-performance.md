# PostgreSQL Query Performance Analysis

**PostgreSQL 17 | EXPLAIN ANALYZE | Index Optimization | SQL Performance**

## 1. Objective

This document presents a practical analysis of three SQL queries executed in a PostgreSQL 17 laboratory.

The objective was to evaluate execution plans, identify potential optimization opportunities and measure the effect of indexes on execution time and buffer usage.

The tests were performed as part of my second-year ASIR practical training.

## 2. Test Environment

The laboratory used PostgreSQL 17 running inside a Docker container with limited resources.

| Component | Configuration |
|---|---|
| Database engine | PostgreSQL 17.11 |
| Container memory limit | 512 MiB |
| Container CPU limit | 0.5 CPU |
| max_connections | 30 |
| shared_buffers | 64 MB |
| work_mem | 2 MB |
| Analysis tool | EXPLAIN (ANALYZE, BUFFERS) |

The SQL optimization tests used a demonstration dataset containing 4,012 incident records, 6 clients, 5 categories and 4 technicians.

No real customer information is included in this repository.

## 3. Methodology

Each query was examined using:

```sql
EXPLAIN (ANALYZE, BUFFERS)
```

The analysis focused on:

- Execution time.
- Sequential Scan and Index Scan operations.
- Bitmap Index Scan and Bitmap Heap Scan.
- Shared buffer usage.
- Joins, aggregation and sorting operations.
- Whether PostgreSQL selected the proposed indexes.

The before-and-after values represent individual laboratory executions, not averaged benchmark results.

## 4. Query 1 — Filtered Incident Search

### Objective

Retrieve a limited number of open, high-priority incidents, joining incident information with the corresponding client and category.

### Optimization

A composite index was evaluated on the filtering and ordering columns.

PostgreSQL changed the observed execution strategy from a sequential scan to an index scan.

### Results

| Metric | Before | After |
|---|---:|---:|
| Execution time | 2.871 ms | 1.046 ms |
| Shared buffers | 105 | 26 |
| Main scan method | Sequential Scan | Index Scan |

**Observed execution-time reduction: approximately 63.6%.**

The index reduced the amount of data accessed in the recorded execution.

## 5. Query 2 — Temporal Aggregation

### Objective

Aggregate incidents created during the previous 90 days, grouping them by category and status.

### Optimization

An index involving the creation date and category was evaluated.

The resulting execution plan included:

- Bitmap Index Scan.
- Bitmap Heap Scan.
- Hash Join.
- HashAggregate.
- Sort.

### Results

| Metric | Before | After |
|---|---:|---:|
| Execution time | 3.006 ms | 2.408 ms |
| Shared buffers | 93 | 80 |
| Index usage | Not selected in baseline | Bitmap Index Scan |

**Observed execution-time reduction: approximately 19.9%.**

The query continued to require aggregation and sorting operations.

In the captured plan, the sort and hash operations used memory without an observed disk spill.

## 6. Query 3 — Multi-Table Aggregation

### Objective

Analyze pending incidents using joins across several tables, grouped by technician, specialization and category.

The query also calculated the number of affected clients and the number of high-priority incidents.

### Optimization Attempt

A partial index was evaluated to determine whether PostgreSQL could improve access to pending incidents.

However, a large proportion of the dataset matched the query conditions.

The planner continued using a Sequential Scan.

### Results

| Metric | Before | After |
|---|---:|---:|
| Execution time | 7.909 ms | 8.938 ms |
| Shared buffers | 98 | 98 |
| Main scan method | Sequential Scan | Sequential Scan |
| Partial index selected | No | No |

**Observed execution-time increase: approximately 13.0%.**

The tested index did not produce a measurable improvement in the recorded comparison.

This result was retained as a negative finding rather than presented as a successful optimization.

## 7. Performance Comparison

| Query | Before | After | Observed change |
|---|---:|---:|---:|
| Q1 — Filtered search | 2.871 ms | 1.046 ms | −63.6% |
| Q2 — Temporal aggregation | 3.006 ms | 2.408 ms | −19.9% |
| Q3 — Multi-table aggregation | 7.909 ms | 8.938 ms | +13.0% |

A negative change indicates a lower measured execution time. A positive change indicates a higher measured execution time.

These results come from specific measurements under laboratory conditions. Other executions may produce different results because of caching, database statistics, planner decisions and system load.

## 8. Technical Findings

### Indexes must be evaluated, not assumed

An index is useful only when PostgreSQL determines that it offers an appropriate access path for the query.

### Selectivity matters

Queries that retrieve a relatively small proportion of records may benefit from indexed access.

Queries that process a large part of a table may perform better with sequential scans.

### Execution time is not the only metric

Buffer usage, scan types, joins and sorting operations help explain why a query performs as observed.

### Negative results are valuable

The third query demonstrated that an attempted optimization can produce no benefit or even a slower observed execution.

This is why changes should be evaluated with actual execution plans before being accepted.

## 9. Limitations

- Tests were executed on a small educational dataset.
- Values represent individual measurements, not statistical averages.
- No production workload or sustained concurrency benchmark was performed.
- Index maintenance costs were not evaluated.
- The captured plans did not show temporary disk spills, but this does not guarantee the same result under other workloads.
- The complete operational database schema and internal application code are not published.

## 10. Skills Demonstrated

- PostgreSQL performance analysis.
- SQL query execution plan interpretation.
- Index selection and evaluation.
- Understanding of sequential and indexed scans.
- Memory and buffer analysis.
- SQL aggregation and joins.
- Evidence-based technical decision-making.
- Technical documentation of both successful and unsuccessful optimization attempts.

---

**Author:** Erick Conesa Pérez  
**Training:** Higher Vocational Training in Network Computer Systems Administration (ASIR)
