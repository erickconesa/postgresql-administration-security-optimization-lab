
-- PostgreSQL 17 - Role-Based Access Control (RBAC)
-- ASIR Database Administration & Security Lab
--
-- Sanitized educational example based on the CT-03 lab.
-- Uses generic roles and tables, not operational credentials.
--
-- IMPORTANT:
-- Execute only on a disposable test database with a
-- prepared public.demo_messages table and sequence.
-- Requires an authorized administrative session.

-- ===================================================
-- 1. CREATE SEPARATE DDL AND DML ROLES
-- ===================================================

CREATE ROLE lab_ddl
    NOLOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOREPLICATION;

CREATE ROLE lab_service
    NOLOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOREPLICATION;

-- ===================================================
-- 2. GRANT ONLY THE REQUIRED PERMISSIONS
-- ===================================================

BEGIN;

-- DDL role: manages schema objects
GRANT USAGE, CREATE
    ON SCHEMA public TO lab_ddl;

-- Service role: can access objects but not create them
GRANT USAGE
    ON SCHEMA public TO lab_service;

-- Transfer ownership to the DDL role
ALTER TABLE public.demo_messages
    OWNER TO lab_ddl;

ALTER SEQUENCE public.demo_messages_id_seq
    OWNER TO lab_ddl;

-- Allow DML operations on existing tables
GRANT SELECT, INSERT, UPDATE, DELETE
    ON ALL TABLES IN SCHEMA public TO lab_service;

-- Allow the service role to use sequences
GRANT USAGE, SELECT
    ON ALL SEQUENCES IN SCHEMA public TO lab_service;

-- Permissions for future objects created by lab_ddl
ALTER DEFAULT PRIVILEGES FOR ROLE lab_ddl
    IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE
    ON TABLES TO lab_service;

ALTER DEFAULT PRIVILEGES FOR ROLE lab_ddl
    IN SCHEMA public
    GRANT USAGE, SELECT
    ON SEQUENCES TO lab_service;

COMMIT;

-- ===================================================
-- 3. VERIFY LEAST-PRIVILEGE PERMISSIONS
-- ===================================================

SELECT
    has_schema_privilege(
        'lab_service', 'public', 'USAGE'
    ) AS schema_usage,
    has_schema_privilege(
        'lab_service', 'public', 'CREATE'
    ) AS schema_create,
    has_table_privilege(
        'lab_service',
        'public.demo_messages',
        'SELECT'
    ) AS can_select,
    has_table_privilege(
        'lab_service',
        'public.demo_messages',
        'INSERT'
    ) AS can_insert,
    has_sequence_privilege(
        'lab_service',
        'public.demo_messages_id_seq',
        'USAGE'
    ) AS can_use_sequence;

-- Expected:
-- schema_usage       = true
-- schema_create      = false
-- can_select         = true
-- can_insert         = true
-- can_use_sequence   = true

-- ===================================================
-- 4. SERVICE LOGIN (SEPARATE ADMINISTRATIVE STEP)
-- ===================================================

-- In the original lab, the restricted service role
-- was subsequently enabled for LOGIN and assigned
-- a secret through psql's interactive \password.
--
-- Example administrative SQL:
-- ALTER ROLE lab_service LOGIN;
--
-- Set its password securely in an interactive
-- administrative session; do not store it in Git.
--
-- Never grant SUPERUSER, CREATEDB or CREATEROLE
-- to a standard application service account.

-- ===================================================
-- 5. PERMISSION TESTING
-- ===================================================

-- The original laboratory verified:
--
-- ALLOWED:
--   SELECT
--   INSERT
--   UPDATE
--   DELETE
--
-- DENIED:
--   ALTER TABLE
--   DROP TABLE
--
-- Tests were performed as the restricted service
-- account in transactions followed by ROLLBACK.
--
-- These examples document the access-control model;
-- they do not execute destructive permission tests.
