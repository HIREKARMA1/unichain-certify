CREATE DATABASE inji_certify
  ENCODING = 'UTF8'
  LC_COLLATE = 'en_US.UTF-8'
  LC_CTYPE = 'en_US.UTF-8'
  TABLESPACE = pg_default
  OWNER = postgres
  TEMPLATE  = template0;

COMMENT ON DATABASE inji_certify IS 'certify related data is stored in this database';

\c inji_certify postgres

DROP SCHEMA IF EXISTS certify CASCADE;
CREATE SCHEMA certify;
ALTER SCHEMA certify OWNER TO postgres;
ALTER DATABASE inji_certify SET search_path TO certify,pg_catalog,public;

--- keymanager specific DB changes ---
CREATE TABLE certify.key_alias(
    id character varying(36) NOT NULL,
    app_id character varying(36) NOT NULL,
    ref_id character varying(128),
    key_gen_dtimes timestamp,
    key_expire_dtimes timestamp,
    status_code character varying(36),
    lang_code character varying(3),
    cr_by character varying(256) NOT NULL,
    cr_dtimes timestamp NOT NULL,
    upd_by character varying(256),
    upd_dtimes timestamp,
    is_deleted boolean DEFAULT FALSE,
    del_dtimes timestamp,
    cert_thumbprint character varying(100),
    uni_ident character varying(50),
    CONSTRAINT pk_keymals_id PRIMARY KEY (id),
    CONSTRAINT uni_ident_const UNIQUE (uni_ident)
);

CREATE TABLE certify.key_policy_def(
    app_id character varying(36) NOT NULL,
    key_validity_duration smallint,
    is_active boolean NOT NULL,
    pre_expire_days smallint,
    access_allowed character varying(1024),
    cr_by character varying(256) NOT NULL,
    cr_dtimes timestamp NOT NULL,
    upd_by character varying(256),
    upd_dtimes timestamp,
    is_deleted boolean DEFAULT FALSE,
    del_dtimes timestamp,
    CONSTRAINT pk_keypdef_id PRIMARY KEY (app_id)
);

CREATE TABLE certify.key_store(
    id character varying(36) NOT NULL,
    master_key character varying(36) NOT NULL,
    private_key character varying(2500) NOT NULL,
    certificate_data character varying NOT NULL,
    cr_by character varying(256) NOT NULL,
    cr_dtimes timestamp NOT NULL,
    upd_by character varying(256),
    upd_dtimes timestamp,
    is_deleted boolean DEFAULT FALSE,
    del_dtimes timestamp,
    CONSTRAINT pk_keystr_id PRIMARY KEY (id)
);

CREATE TABLE certify.ca_cert_store(
    cert_id character varying(36) NOT NULL,
    cert_subject character varying(500) NOT NULL,
    cert_issuer character varying(500) NOT NULL,
    issuer_id character varying(36) NOT NULL,
    cert_not_before timestamp,
    cert_not_after timestamp,
    crl_uri character varying(120),
    cert_data character varying,
    cert_thumbprint character varying(100),
    cert_serial_no character varying(50),
    partner_domain character varying(36),
    cr_by character varying(256),
    cr_dtimes timestamp,
    upd_by character varying(256),
    upd_dtimes timestamp,
    is_deleted boolean DEFAULT FALSE,
    del_dtimes timestamp,
    ca_cert_type character varying(25),
    CONSTRAINT pk_cacs_id PRIMARY KEY (cert_id),
    CONSTRAINT cert_thumbprint_unique UNIQUE (cert_thumbprint,partner_domain)
);

CREATE TABLE certify.rendering_template (
    id varchar(128) NOT NULL,
    template VARCHAR NOT NULL,
    cr_dtimes timestamp NOT NULL,
    upd_dtimes timestamp,
    CONSTRAINT pk_svgtmp_id PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS certify.credential_config (
    credential_config_key_id VARCHAR(2048) NOT NULL UNIQUE,
    config_id VARCHAR(255) NOT NULL,
    status VARCHAR(255),
    vc_template VARCHAR,
    doctype VARCHAR,
    sd_jwt_vct VARCHAR,
    context VARCHAR,
    credential_type VARCHAR,
    credential_format VARCHAR(255) NOT NULL,
    did_url VARCHAR,
    key_manager_app_id VARCHAR(36),
    key_manager_ref_id VARCHAR(128),
    signature_algo VARCHAR(36),
    signature_crypto_suite VARCHAR(128),
    sd_claim VARCHAR,
    display JSONB NOT NULL,
    display_order TEXT[] NOT NULL,
    scope VARCHAR(255) NOT NULL,
    cryptographic_binding_methods_supported TEXT[] NOT NULL,
    credential_signing_alg_values_supported TEXT[] NOT NULL,
    proof_types_supported JSONB NOT NULL,
    credential_subject JSONB,
    sd_jwt_claims JSONB,
    mso_mdoc_claims JSONB,
    plugin_configurations JSONB,
    credential_status_purpose TEXT[],
    cr_dtimes TIMESTAMP NOT NULL,
    upd_dtimes TIMESTAMP,
    CONSTRAINT pk_config_id PRIMARY KEY (config_id)
);

CREATE UNIQUE INDEX idx_credential_config_type_context_unique
    ON certify.credential_config(credential_type, context, credential_format)
    WHERE credential_type IS NOT NULL AND credential_type <> ''
      AND context IS NOT NULL AND context <> '';

CREATE UNIQUE INDEX idx_credential_config_sd_jwt_vct_unique
    ON certify.credential_config(sd_jwt_vct, credential_format)
    WHERE sd_jwt_vct IS NOT NULL and sd_jwt_vct <> '';

CREATE UNIQUE INDEX idx_credential_config_doctype_unique
    ON certify.credential_config(doctype, credential_format)
    WHERE doctype IS NOT NULL and doctype <> '';

INSERT INTO certify.credential_config (
    credential_config_key_id,
    config_id,
    status,
    vc_template,
    doctype,
    sd_jwt_vct,
    context,
    credential_type,
    credential_format,
    did_url,
    key_manager_app_id,
    key_manager_ref_id,
    signature_algo,
    signature_crypto_suite,
    sd_claim,
    display,
    display_order,
    scope,
    cryptographic_binding_methods_supported,
    credential_signing_alg_values_supported,
    proof_types_supported,
    credential_subject,
    mso_mdoc_claims,
    plugin_configurations,
    credential_status_purpose,
    cr_dtimes,
    upd_dtimes
)
VALUES (
    'SchoolCredential',
    gen_random_uuid()::VARCHAR(255),
    'active',
    'ewogICAgICAgICAgIkBjb250ZXh0IjogWwogICAgICAgICAgICAgICJodHRwczovL3d3dy53My5vcmcvMjAxOC9jcmVkZW50aWFscy92MSIsCiAgICAgICAgICAgICAgImh0dHBzOi8vaGlyZWthcm1hMS5naXRodWIuaW8vdGVtcGZpbGVzL2RpcmVjdG9yeS9TY2hvb2xfZ2l0X3BhZ2UuanNvbiIsCiAgICAgICAgICAgICAgImh0dHBzOi8vdzNpZC5vcmcvc2VjdXJpdHkvc3VpdGVzL2VkMjU1MTktMjAyMC92MSIKICAgICAgICAgIF0sCiAgICAgICAgICAiaXNzdWVyIjogIiR7X2lzc3Vlcn0iLAogICAgICAgICAgInR5cGUiOiBbCiAgICAgICAgICAgICAgIlZlcmlmaWFibGVDcmVkZW50aWFsIiwKICAgICAgICAgICAgICAiU2Nob29sQ3JlZGVudGlhbCIKICAgICAgICAgIF0sCiAgICAgICAgICAiaXNzdWFuY2VEYXRlIjogIiR7dmFsaWRGcm9tfSIsCiAgICAgICAgICAiZXhwaXJhdGlvbkRhdGUiOiAiJHt2YWxpZFVudGlsfSIsCiAgICAgICAgICAiY3JlZGVudGlhbFN1YmplY3QiOiB7CiAgICAgICAgICAgICAgImlkIjogIiR7X2hvbGRlcklkfSIsCQkJCiAgICAgICAgICAgICAic3R1ZGVudF9pZCI6ICIke3N0dWRlbnRfaWR9IiwKICAgICAgICAgICAgICJzdHVkZW50X25hbWUiOiAiJHtzdHVkZW50X25hbWV9IiwKICAgICAgICAgICAgICJkb2IiOiAiJHtkb2J9IiwKICAgICAgICAgICAgICJnZW5kZXIiOiAiJHtnZW5kZXJ9IiwKICAgICAgICAgICAgICJwYXJlbnRfb3JfZ3VhcmRpYW4iOiAiJHtwYXJlbnRfb3JfZ3VhcmRpYW59IiwKICAgICAgICAgICAgICJjb250YWN0IjogIiR7Y29udGFjdH0iCiAgICAgICAgICB9CiAgICAgfQ==',
    NULL,
    NULL,
    'https://www.w3.org/2018/credentials/v1',
    'SchoolCredential,VerifiableCredential',
    'ldp_vc',
    'did:web:hirekarma1.github.io:tempfiles:directory',
    'CERTIFY_VC_SIGN_ED25519',
    'ED25519_SIGN',
    'EdDSA',
    'Ed25519Signature2020',
    NULL,
    '[{"name": "School Verifiable Credential", "locale": "en", "logo": {"url": "https://mosip.github.io/inji-config/logos/agro-vertias-logo.png", "alt_text": "Farmer Credential Logo"}, "background_color": "#12107c", "text_color": "#FFFFFF", "background_image": { "uri": "https://mosip.github.io/inji-config/logos/agro-vertias-logo.png" }}]'::JSONB,
    ARRAY['student_id','student_name','dob','gender','parent_or_guardian'],
    'mosip_identity_vc_ldp',
    ARRAY['did:jwk'],
    ARRAY['Ed25519Signature2020'],
    '{"jwt": {"proof_signing_alg_values_supported": ["RS256", "ES256"]}}'::JSONB,
    '{"student_id": {"display": [{"name": "Full Name", "locale": "en"}]}, "contact": {"display": [{"name": "Phone Number", "locale": "en"}]}, "dob": {"display": [{"name": "Date of Birth", "locale": "en"}]}, "gender": {"display": [{"name": "Gender", "locale": "en"}]}}'::JSONB,
    NULL,
    '[{"mosip.certify.mock.data-provider.csv.identifier-column": "id", "mosip.certify.mock.data-provider.csv.data-columns": "id,fullName,mobileNumber,dob,gender,state,district,villageOrTown,postalCode,landArea,landOwnershipType,primaryCropType,secondaryCropType,face,farmerID", "mosip.certify.mock.data-provider.csv-registry-uri": "/home/mosip/config/farmer_identity_data.csv"}]'::JSONB,
    ARRAY['revocation'],
    NOW(),
    NULL
);

CREATE TABLE certify.school_data (
    student_id VARCHAR(36) NOT NULL,
    student_name VARCHAR(255),
    dob DATE,
    gender VARCHAR(50),
    parent_or_guardian VARCHAR(255),
    contact VARCHAR(20),
    CONSTRAINT pk_stud_id_code PRIMARY KEY (student_id)
);

INSERT INTO certify.school_data VALUES
    ('2154189532','John Doe','2010-05-15','Male','Jane Doe','1234567890'),
    ('8038618701','Emma Smith','2012-08-22','Female','Mark Smith','9876543210'),
    ('123456','Liam Brown','2009-12-30','Male','Sarah Brown','4567891230');

INSERT INTO certify.key_policy_def(APP_ID,KEY_VALIDITY_DURATION,PRE_EXPIRE_DAYS,ACCESS_ALLOWED,IS_ACTIVE,CR_BY,CR_DTIMES) VALUES
('ROOT',2920,1125,'NA',true,'mosipadmin',now()),
('CERTIFY_SERVICE',1095,60,'NA',true,'mosipadmin',now()),
('CERTIFY_PARTNER',1095,60,'NA',true,'mosipadmin',now()),
('CERTIFY_VC_SIGN_RSA',1095,60,'NA',true,'mosipadmin',now()),
('CERTIFY_VC_SIGN_ED25519',1095,60,'NA',true,'mosipadmin',now()),
('BASE',1095,60,'NA',true,'mosipadmin',now()),
('CERTIFY_VC_SIGN_EC_K1',1095,60,'NA',true,'mosipadmin',now()),
('CERTIFY_VC_SIGN_EC_R1',1095,60,'NA',true,'mosipadmin',now());

CREATE TYPE credential_status_enum AS ENUM ('AVAILABLE', 'FULL');

CREATE TABLE certify.status_list_credential (
    id VARCHAR(255) PRIMARY KEY,
    vc_document VARCHAR NOT NULL,
    credential_type VARCHAR(100) NOT NULL,
    status_purpose VARCHAR(100),
    capacity BIGINT,
    credential_status credential_status_enum,
    cr_dtimes timestamp NOT NULL default now(),
    upd_dtimes timestamp
);

CREATE INDEX IF NOT EXISTS idx_slc_status_purpose ON certify.status_list_credential(status_purpose);
CREATE INDEX IF NOT EXISTS idx_slc_credential_type ON certify.status_list_credential(credential_type);
CREATE INDEX IF NOT EXISTS idx_slc_credential_status ON certify.status_list_credential(credential_status);
CREATE INDEX IF NOT EXISTS idx_slc_cr_dtimes ON certify.status_list_credential(cr_dtimes);

CREATE TABLE certify.ledger (
    id SERIAL PRIMARY KEY,
    credential_id VARCHAR(255) NOT NULL,
    issuer_id VARCHAR(255) NOT NULL,
    issue_date TIMESTAMPTZ NOT NULL,
    expiration_date TIMESTAMPTZ,
    credential_type VARCHAR(100) NOT NULL,
    indexed_attributes JSONB,
    credential_status_details JSONB NOT NULL DEFAULT '[]'::jsonb,
    cr_dtimes TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_ledger_tracked_credential_id UNIQUE (credential_id),
    CONSTRAINT ensure_credential_status_details_is_array CHECK (jsonb_typeof(credential_status_details) = 'array')
);

CREATE INDEX IF NOT EXISTS idx_ledger_credential_id ON certify.ledger(credential_id);
CREATE INDEX IF NOT EXISTS idx_ledger_issuer_id ON certify.ledger(issuer_id);
CREATE INDEX IF NOT EXISTS idx_ledger_credential_type ON certify.ledger(credential_type);
CREATE INDEX IF NOT EXISTS idx_ledger_issue_date ON certify.ledger(issue_date);
CREATE INDEX IF NOT EXISTS idx_ledger_expiration_date ON certify.ledger(expiration_date);
CREATE INDEX IF NOT EXISTS idx_ledger_cr_dtimes ON certify.ledger(cr_dtimes);
CREATE INDEX IF NOT EXISTS idx_gin_ledger_indexed_attrs ON certify.ledger USING GIN (indexed_attributes);
CREATE INDEX IF NOT EXISTS idx_gin_ledger_status_details ON certify.ledger USING GIN (credential_status_details);

CREATE TABLE IF NOT EXISTS certify.credential_status_transaction (
    transaction_log_id SERIAL PRIMARY KEY,
    credential_id VARCHAR(255) NOT NULL,
    status_purpose VARCHAR(100),
    status_value boolean,
    status_list_credential_id VARCHAR(255),
    status_list_index BIGINT,
    cr_dtimes TIMESTAMP NOT NULL DEFAULT NOW(),
    upd_dtimes TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_cst_credential_id ON certify.credential_status_transaction(credential_id);
CREATE INDEX IF NOT EXISTS idx_cst_status_purpose ON certify.credential_status_transaction(status_purpose);
CREATE INDEX IF NOT EXISTS idx_cst_status_list_credential_id ON certify.credential_status_transaction(status_list_credential_id);
CREATE INDEX IF NOT EXISTS idx_cst_status_list_index ON certify.credential_status_transaction(status_list_index);
CREATE INDEX IF NOT EXISTS idx_cst_cr_dtimes ON certify.credential_status_transaction(cr_dtimes);
CREATE INDEX IF NOT EXISTS idx_cst_status_value ON certify.credential_status_transaction(status_value);

CREATE TABLE IF NOT EXISTS certify.status_list_available_indices (
    id SERIAL PRIMARY KEY,
    status_list_credential_id VARCHAR(255) NOT NULL,
    list_index BIGINT NOT NULL,
    is_assigned BOOLEAN NOT NULL DEFAULT FALSE,
    cr_dtimes TIMESTAMP NOT NULL DEFAULT NOW(),
    upd_dtimes TIMESTAMP,
    CONSTRAINT fk_status_list_credential FOREIGN KEY(status_list_credential_id)
        REFERENCES certify.status_list_credential(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT uq_list_id_and_index UNIQUE (status_list_credential_id, list_index)
);

CREATE INDEX IF NOT EXISTS idx_sla_available_indices
    ON certify.status_list_available_indices (status_list_credential_id, is_assigned, list_index)
    WHERE is_assigned = FALSE;

CREATE INDEX IF NOT EXISTS idx_sla_status_list_credential_id ON certify.status_list_available_indices(status_list_credential_id);
CREATE INDEX IF NOT EXISTS idx_sla_is_assigned ON certify.status_list_available_indices(is_assigned);
CREATE INDEX IF NOT EXISTS idx_sla_list_index ON certify.status_list_available_indices(list_index);
CREATE INDEX IF NOT EXISTS idx_sla_cr_dtimes ON certify.status_list_available_indices(cr_dtimes);

CREATE TABLE IF NOT EXISTS certify.shedlock (
    name VARCHAR(64),
    lock_until TIMESTAMPTZ(3) NOT NULL,
    locked_at TIMESTAMPTZ(3) NOT NULL,
    locked_by VARCHAR(255) NOT NULL,
    PRIMARY KEY (name)
);

-- FIXED COMMENT SECTION
COMMENT ON TABLE certify.shedlock IS 'Table for managing distributed locks using ShedLock library.';
COMMENT ON COLUMN certify.shedlock.name IS 'Unique name of the lock.';
COMMENT ON COLUMN certify.shedlock.lock_until IS 'Timestamp until which the lock is held. NULL if not locked.';
COMMENT ON COLUMN certify.shedlock.locked_at IS 'Timestamp when the lock was acquired. NULL if not locked.';
COMMENT ON COLUMN certify.shedlock.locked_by IS 'Identifier of the node/process that holds the lock. NULL if not locked.';
