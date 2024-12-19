-- Create okapi_modules_staging database
CREATE DATABASE okapi_modules_staging OWNER folio_admin;
GRANT ALL PRIVILEGES ON DATABASE okapi_modules_staging TO folio_admin;

-- Create extensions

-- on okapi_modules
create extension if not exists pg_trgm version '1.4';
comment on extension pg_trgm is 'text similarity measurement and index searching based on trigrams';

create extension if not exists  unaccent version '1.1';
comment on extension unaccent is 'text search dictionary that removes accents';

create extension if not exists pgcrypto version '1.3';
comment on extension pgcrypto is 'cryptographic functions';

create extension if not exists "uuid-ossp" version '1.1';
comment on extension "uuid-ossp" is 'generate universally unique identifiers (UUIDs)';

create extension if not exists btree_gin version '1.3';
comment on extension btree_gin is 'support for indexing common datatypes in GIN';

-- on okapi_modules_staging
\connect okapi_modules_staging;

create extension if not exists pg_trgm version '1.4';
comment on extension pg_trgm is 'text similarity measurement and index searching based on trigrams';

create extension if not exists  unaccent version '1.1';
comment on extension unaccent is 'text search dictionary that removes accents';

create extension if not exists pgcrypto version '1.3';
comment on extension pgcrypto is 'cryptographic functions';

create extension if not exists "uuid-ossp" version '1.1';
comment on extension "uuid-ossp" is 'generate universally unique identifiers (UUIDs)';

create extension if not exists btree_gin version '1.3';
comment on extension btree_gin is 'support for indexing common datatypes in GIN';
