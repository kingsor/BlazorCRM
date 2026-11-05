-- Quartz.NET 4.7.0 schema for PostgreSQL (default table prefix 'qrtz_').
-- Extracted from the Quartz package (Quartz.Impl.AdoJobStore.Schema.create_postgres.sql).
-- Idempotent: creates only what is missing. Databases created with Quartz 3.x need the
-- official migration scripts (database/migrations/4.0+) from the Quartz.NET repository instead.

--
-- Quartz.NET schema -- PostgreSQL
--
-- GENERATED FILE. Describe the schema in build/Build.DatabaseSchema.cs and run
-- 'dotnet fallout GenerateSchema'; edits made here are overwritten.
--
-- This is what AdoJobStore runs for itself when SchemaProvisioning.CreateIfMissing is
-- configured. It is not the script to run by hand -- use
-- database/tables/tables_postgres.sql for that, which is written for a person with a
-- database client and drops an existing schema before it recreates one.
--
-- Every statement creates only what is missing, and nothing here ever drops anything.
-- So it is safe to run against a schema that already exists, and safe to run twice.
--
-- 'qrtz_' is the configured table prefix and 'qrtz_' is the same prefix with any schema
-- qualifier removed, for the identifiers that cannot carry one -- index, constraint and
-- catalog-lookup names. They are substituted at runtime, so a schema provisioned under a
-- prefix of its own collides with nothing.
--
-- Statements are separated by a line reading exactly '--;;'. The job store splits on
-- it and sends each piece to the provider as one command, which is why no dialect's batch
-- separator appears: no GO, no lone '/', no SET TERM.
--
--;;
-- qrtz_JOB_DETAILS
CREATE TABLE IF NOT EXISTS qrtz_job_details (
  sched_name text not null,
  job_name text not null,
  job_group text not null,
  description text null,
  job_class_name text not null,
  is_durable bool not null,
  is_nonconcurrent bool not null,
  is_update_data bool not null,
  requests_recovery bool not null,
  job_data bytea null,
  primary key (sched_name,job_name,job_group)
);
--;;
-- qrtz_TRIGGERS
CREATE TABLE IF NOT EXISTS qrtz_triggers (
  sched_name text not null,
  trigger_name text not null,
  trigger_group text not null,
  job_name text not null,
  job_group text not null,
  description text null,
  next_fire_time bigint null,
  prev_fire_time bigint null,
  priority integer null,
  trigger_state text not null,
  trigger_type text not null,
  start_time bigint not null,
  end_time bigint null,
  calendar_name text null,
  misfire_instr smallint null,
  misfire_orig_fire_time bigint null,
  execution_group varchar(200) null,
  preferred_node varchar(200) null,
  preferred_node_auto bool not null default false,
  retry_policy varchar(250) null,
  retry_attempt integer null,
  continues_trigger_name text null,
  continues_trigger_group text null,
  continuation_condition integer null,
  overlap_policy integer null,
  pause_reason varchar(250) null,
  paused_by varchar(200) null,
  paused_at bigint null,
  misfire_threshold bigint null,
  fixed_delay bool null,
  job_data bytea null,
  primary key (sched_name,trigger_name,trigger_group),
  foreign key (sched_name,job_name,job_group) references qrtz_job_details (sched_name,job_name,job_group)
);
--;;
-- qrtz_SIMPLE_TRIGGERS
CREATE TABLE IF NOT EXISTS qrtz_simple_triggers (
  sched_name text not null,
  trigger_name text not null,
  trigger_group text not null,
  repeat_count bigint not null,
  repeat_interval bigint not null,
  times_triggered bigint not null,
  primary key (sched_name,trigger_name,trigger_group),
  foreign key (sched_name,trigger_name,trigger_group) references qrtz_triggers (sched_name,trigger_name,trigger_group) on delete cascade
);
--;;
-- qrtz_CRON_TRIGGERS
CREATE TABLE IF NOT EXISTS qrtz_cron_triggers (
  sched_name text not null,
  trigger_name text not null,
  trigger_group text not null,
  cron_expression text not null,
  time_zone_id text,
  primary key (sched_name,trigger_name,trigger_group),
  foreign key (sched_name,trigger_name,trigger_group) references qrtz_triggers (sched_name,trigger_name,trigger_group) on delete cascade
);
--;;
-- qrtz_SIMPROP_TRIGGERS
CREATE TABLE IF NOT EXISTS qrtz_simprop_triggers (
  sched_name text not null,
  trigger_name text not null,
  trigger_group text not null,
  str_prop_1 text null,
  str_prop_2 text null,
  str_prop_3 text null,
  int_prop_1 integer null,
  int_prop_2 integer null,
  long_prop_1 bigint null,
  long_prop_2 bigint null,
  dec_prop_1 numeric null,
  dec_prop_2 numeric null,
  bool_prop_1 bool null,
  bool_prop_2 bool null,
  time_zone_id text null,
  primary key (sched_name,trigger_name,trigger_group),
  foreign key (sched_name,trigger_name,trigger_group) references qrtz_triggers (sched_name,trigger_name,trigger_group) on delete cascade
);
--;;
-- qrtz_BLOB_TRIGGERS
CREATE TABLE IF NOT EXISTS qrtz_blob_triggers (
  sched_name text not null,
  trigger_name text not null,
  trigger_group text not null,
  blob_data bytea null,
  primary key (sched_name,trigger_name,trigger_group),
  foreign key (sched_name,trigger_name,trigger_group) references qrtz_triggers (sched_name,trigger_name,trigger_group) on delete cascade
);
--;;
-- qrtz_CALENDARS
CREATE TABLE IF NOT EXISTS qrtz_calendars (
  sched_name text not null,
  calendar_name text not null,
  calendar bytea not null,
  primary key (sched_name,calendar_name)
);
--;;
-- qrtz_PAUSED_TRIGGER_GRPS
CREATE TABLE IF NOT EXISTS qrtz_paused_trigger_grps (
  sched_name text not null,
  trigger_group text not null,
  pause_reason varchar(250) null,
  paused_by varchar(200) null,
  paused_at bigint null,
  primary key (sched_name,trigger_group)
);
--;;
-- qrtz_PAUSED_JOB_GRPS
CREATE TABLE IF NOT EXISTS qrtz_paused_job_grps (
  sched_name text not null,
  job_group text not null,
  pause_reason varchar(250) null,
  paused_by varchar(200) null,
  paused_at bigint null,
  primary key (sched_name,job_group)
);
--;;
-- qrtz_FIRED_TRIGGERS
CREATE TABLE IF NOT EXISTS qrtz_fired_triggers (
  sched_name text not null,
  entry_id text not null,
  trigger_name text not null,
  trigger_group text not null,
  instance_name text not null,
  fired_time bigint not null,
  sched_time bigint not null,
  priority integer not null,
  state text not null,
  job_name text null,
  job_group text null,
  is_nonconcurrent bool not null,
  requests_recovery bool null,
  execution_group varchar(200) null,
  progress integer null,
  progress_message varchar(250) null,
  interrupt_requested_time bigint null,
  primary key (sched_name,entry_id)
);
--;;
-- qrtz_SCHEDULER_STATE
CREATE TABLE IF NOT EXISTS qrtz_scheduler_state (
  sched_name text not null,
  instance_name text not null,
  last_checkin_time bigint not null,
  checkin_interval bigint not null,
  quartz_version varchar(20) null,
  primary key (sched_name,instance_name)
);
--;;
-- qrtz_LOCKS
CREATE TABLE IF NOT EXISTS qrtz_locks (
  sched_name text not null,
  lock_name text not null,
  primary key (sched_name,lock_name)
);
--;;
-- qrtz_EXECUTION_HISTORY
CREATE TABLE IF NOT EXISTS qrtz_execution_history (
  sched_name text not null,
  entry_id text not null,
  instance_name text not null,
  job_name text not null,
  job_group text not null,
  trigger_name text not null,
  trigger_group text not null,
  fired_time bigint not null,
  run_time bigint not null,
  succeeded bool not null,
  error_message text null,
  retry_attempt integer not null default 0,
  retry_scheduled bool not null default false,
  execution_log text null,
  result integer null,
  summary text null,
  metrics text null,
  manual bool null,
  fire_instance_id text null,
  job_input text null,
  job_input_too_large bool null,
  primary key (sched_name,entry_id)
);
--;;
-- qrtz_MISFIRE_HISTORY
CREATE TABLE IF NOT EXISTS qrtz_misfire_history (
  sched_name text not null,
  entry_id text not null,
  instance_name text not null,
  trigger_name text not null,
  trigger_group text not null,
  job_name text null,
  job_group text null,
  misfire_time bigint not null,
  sched_time bigint null,
  reason integer null,
  primary key (sched_name,entry_id)
);
--;;
-- qrtz_JOB_STATUS
CREATE TABLE IF NOT EXISTS qrtz_job_status (
  sched_name text not null,
  job_group text not null,
  job_name text not null,
  first_fired_time bigint not null,
  last_fired_time bigint not null,
  last_result integer not null,
  last_run_time bigint not null,
  last_instance_name text not null,
  last_entry_id text null,
  last_summary text null,
  last_success_time bigint null,
  last_failure_time bigint null,
  last_failure_message text null,
  consecutive_failures integer not null default 0,
  run_count bigint not null default 0,
  failure_count bigint not null default 0,
  primary key (sched_name,job_group,job_name)
);
--;;
-- IDX_qrtz_J_G_N
CREATE INDEX IF NOT EXISTS idx_qrtz_j_g_n ON qrtz_job_details (sched_name, job_group, job_name);
--;;
-- IDX_qrtz_T_J
CREATE INDEX IF NOT EXISTS idx_qrtz_t_j ON qrtz_triggers (sched_name, job_name, job_group);
--;;
-- IDX_qrtz_T_G_N
CREATE INDEX IF NOT EXISTS idx_qrtz_t_g_n ON qrtz_triggers (sched_name, trigger_group, trigger_name);
--;;
-- IDX_qrtz_T_C
CREATE INDEX IF NOT EXISTS idx_qrtz_t_c ON qrtz_triggers (sched_name, calendar_name);
--;;
-- IDX_qrtz_T_NFT_ST
CREATE INDEX IF NOT EXISTS idx_qrtz_t_nft_st ON qrtz_triggers (sched_name, trigger_state, next_fire_time asc, priority desc, misfire_instr);
--;;
-- IDX_qrtz_FT_INST_JOB_REQ_RCVRY
CREATE INDEX IF NOT EXISTS idx_qrtz_ft_inst_job_req_rcvry ON qrtz_fired_triggers (sched_name, instance_name, requests_recovery);
--;;
-- IDX_qrtz_FT_J_G
CREATE INDEX IF NOT EXISTS idx_qrtz_ft_j_g ON qrtz_fired_triggers (sched_name, job_name, job_group);
--;;
-- IDX_qrtz_FT_T_G
CREATE INDEX IF NOT EXISTS idx_qrtz_ft_t_g ON qrtz_fired_triggers (sched_name, trigger_name, trigger_group);
--;;
-- IDX_qrtz_EH_FIRED_TIME
CREATE INDEX IF NOT EXISTS idx_qrtz_eh_fired_time ON qrtz_execution_history (sched_name, fired_time);
--;;
-- IDX_qrtz_EH_INST
CREATE INDEX IF NOT EXISTS idx_qrtz_eh_inst ON qrtz_execution_history (sched_name, instance_name);
--;;
-- IDX_qrtz_MH_MISFIRE_TIME
CREATE INDEX IF NOT EXISTS idx_qrtz_mh_misfire_time ON qrtz_misfire_history (sched_name, misfire_time);
--;;
-- IDX_qrtz_MH_INST
CREATE INDEX IF NOT EXISTS idx_qrtz_mh_inst ON qrtz_misfire_history (sched_name, instance_name);
--;;
-- IDX_qrtz_EH_JOB_TIME
CREATE INDEX IF NOT EXISTS idx_qrtz_eh_job_time ON qrtz_execution_history (sched_name, job_group, job_name, fired_time);
--;;
-- IDX_qrtz_EH_FIRE_INST
CREATE INDEX IF NOT EXISTS idx_qrtz_eh_fire_inst ON qrtz_execution_history (sched_name, fire_instance_id);
--;;
-- IDX_qrtz_EH_TRIG_TIME
CREATE INDEX IF NOT EXISTS idx_qrtz_eh_trig_time ON qrtz_execution_history (sched_name, trigger_group, trigger_name, fired_time);
