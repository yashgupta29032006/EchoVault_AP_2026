-- ============================================================================
-- ECHOVAULT DATABASE SCHEMA
-- File: dbms/03_schema.sql
-- Target: PostgreSQL 16+
-- Purpose: Proposed normalized relational schema for EchoVault.
--
-- IMPORTANT:
-- This is the 15-table proposed PostgreSQL schema documented in
-- dbms/01_normalization.md. It is NOT a direct copy of the current
-- 7-table SQLite prototype. Review application compatibility before
-- pointing the running application at this schema.
--
-- Storage boundaries:
--   * Relational data: stored here.
--   * Embeddings: stored in FAISS.
--   * Audio chunks: stored as filesystem WAV files.
--   * OAuth credentials: stored outside this relational database.
-- ============================================================================

BEGIN;

-- Required for uuid_generate_v4() in users.user_id.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- ============================================================================
-- 1. USERS & PROFILES
-- Root tenant / owner of EchoVault data.
-- ============================================================================

CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================================
-- 2. LISTENING SESSIONS
-- A continuous microphone or hardware audio-capture session.
-- ============================================================================

CREATE TABLE listening_sessions (
    session_id VARCHAR(64) PRIMARY KEY,
    user_id UUID NOT NULL
        REFERENCES users(user_id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'listening'
        CHECK (status IN ('listening', 'paused', 'stopped')),
    started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMPTZ,
    duration_seconds DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    CONSTRAINT chk_session_times
        CHECK (ended_at IS NULL OR ended_at >= started_at)
);

CREATE INDEX idx_listening_sessions_user
    ON listening_sessions(user_id);

CREATE INDEX idx_listening_sessions_status
    ON listening_sessions(status);


-- ============================================================================
-- 3. SESSION PAUSE INTERVALS
-- Stores each pause/resume interval separately.
-- ============================================================================

CREATE TABLE session_pause_intervals (
    interval_id BIGSERIAL PRIMARY KEY,
    session_id VARCHAR(64) NOT NULL
        REFERENCES listening_sessions(session_id) ON DELETE CASCADE,
    paused_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resumed_at TIMESTAMPTZ,
    pause_duration_seconds DOUBLE PRECISION,
    CONSTRAINT chk_pause_interval
        CHECK (resumed_at IS NULL OR resumed_at >= paused_at)
);

CREATE INDEX idx_pause_intervals_session
    ON session_pause_intervals(session_id);


-- ============================================================================
-- 4. TRANSCRIPT CHUNKS
-- Atomic, timestamped speech segments produced by transcription.
-- Audio files themselves remain on the filesystem.
-- ============================================================================

CREATE TABLE transcript_chunks (
    chunk_id VARCHAR(64) PRIMARY KEY,
    session_id VARCHAR(64) NOT NULL
        REFERENCES listening_sessions(session_id) ON DELETE CASCADE,
    sequence_number INTEGER NOT NULL DEFAULT 0,
    "timestamp" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    text TEXT NOT NULL,
    original_text TEXT NOT NULL,
    raw_confidence REAL NOT NULL,

    -- Mirrors the documented Python confidence conversion:
    -- int((1.0 + max(-1.0, min(0.0, logprob))) * 100)
    confidence INTEGER GENERATED ALWAYS AS (
        TRUNC(
            (1.0 + GREATEST(-1.0, LEAST(0.0, raw_confidence))) * 100
        )::INTEGER
    ) STORED,

    speaker VARCHAR(64),
    start_time REAL NOT NULL DEFAULT 0.0,
    end_time REAL NOT NULL DEFAULT 0.0,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    is_reviewed BOOLEAN NOT NULL DEFAULT FALSE,
    is_important BOOLEAN NOT NULL DEFAULT FALSE,
    category VARCHAR(50) NOT NULL DEFAULT 'Other',
    last_edited_at TIMESTAMPTZ,
    is_final BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_session_chunk_seq
        UNIQUE (session_id, sequence_number),
    CONSTRAINT chk_audio_window
        CHECK (end_time >= start_time)
);

CREATE INDEX idx_transcript_chunks_session
    ON transcript_chunks(session_id);

CREATE INDEX idx_transcript_chunks_timestamp
    ON transcript_chunks("timestamp" DESC);


-- ============================================================================
-- 5. REFINED MEMORIES
-- Consolidated semantic memories extracted from transcript content.
-- ============================================================================

CREATE TABLE refined_memories (
    refined_id VARCHAR(64) PRIMARY KEY,
    user_id UUID NOT NULL
        REFERENCES users(user_id) ON DELETE CASCADE,
    summary TEXT NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'Other',
    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'updated', 'cancelled', 'archived')),
    importance_score REAL NOT NULL DEFAULT 0.0
        CHECK (importance_score BETWEEN 0.0 AND 1.0),
    last_updated TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_refined_memories_user_cat
    ON refined_memories(user_id, category);


-- ============================================================================
-- 6. MEMORY CHUNK SOURCES
-- Junction table: a memory can reference many transcript chunks, and a
-- transcript chunk can contribute to many refined memories.
-- ============================================================================

CREATE TABLE memory_chunk_sources (
    refined_id VARCHAR(64) NOT NULL
        REFERENCES refined_memories(refined_id) ON DELETE CASCADE,
    chunk_id VARCHAR(64) NOT NULL
        REFERENCES transcript_chunks(chunk_id) ON DELETE CASCADE,
    association_score REAL NOT NULL DEFAULT 1.0,
    PRIMARY KEY (refined_id, chunk_id)
);


-- ============================================================================
-- 7. MEMORY ENTITIES
-- Named entities (people, projects, dates, topics) extracted from memories.
-- ============================================================================

CREATE TABLE memory_entities (
    entity_id BIGSERIAL PRIMARY KEY,
    refined_id VARCHAR(64) NOT NULL
        REFERENCES refined_memories(refined_id) ON DELETE CASCADE,
    entity_type VARCHAR(50) NOT NULL,
    entity_value VARCHAR(255) NOT NULL,
    CONSTRAINT uq_memory_entity
        UNIQUE (refined_id, entity_type, entity_value)
);

CREATE INDEX idx_memory_entities_type_val
    ON memory_entities(entity_type, entity_value);


-- ============================================================================
-- 8. AUTOMATION EXECUTIONS
-- Top-level workflow triggered by voice or chat.
-- session_id is nullable because an execution may originate from chat.
-- ============================================================================

CREATE TABLE automation_executions (
    execution_id VARCHAR(64) PRIMARY KEY,
    session_id VARCHAR(64)
        REFERENCES listening_sessions(session_id) ON DELETE SET NULL,
    user_id UUID NOT NULL
        REFERENCES users(user_id) ON DELETE CASCADE,
    command_text TEXT NOT NULL,
    detected_intent VARCHAR(50) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING_CONFIRMATION'
        CHECK (
            status IN (
                'PENDING_CONFIRMATION',
                'CONFIRMED',
                'EXECUTING',
                'SUCCESS',
                'FAILED',
                'REJECTED'
            )
        ),
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_executions_user_status
    ON automation_executions(user_id, status);


-- ============================================================================
-- 9. PLANNED ACTIONS
-- Individual tool calls planned as nodes in an automation execution DAG.
-- JSONB is intentionally used for tool-specific parameters and results.
-- ============================================================================

CREATE TABLE planned_actions (
    action_id VARCHAR(64) PRIMARY KEY,
    execution_id VARCHAR(64) NOT NULL
        REFERENCES automation_executions(execution_id) ON DELETE CASCADE,
    tool_name VARCHAR(50) NOT NULL,
    action_verb VARCHAR(50) NOT NULL,
    parameters_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'ready',
                'running',
                'success',
                'failed',
                'blocked',
                'skipped'
            )
        ),
    result_payload JSONB,
    error_message TEXT,
    sequence_order INTEGER NOT NULL DEFAULT 1,
    executed_at TIMESTAMPTZ,

    CONSTRAINT uq_exec_action_seq
        UNIQUE (execution_id, sequence_order),
    CONSTRAINT uq_exec_action
        UNIQUE (execution_id, action_id)
);

CREATE INDEX idx_actions_execution
    ON planned_actions(execution_id);


-- ============================================================================
-- 10. ACTION DEPENDENCIES
-- Directed edges between planned actions. Both actions must belong to the
-- same automation execution. General multi-node cycle detection is handled
-- by the application planner, as documented in 01_normalization.md.
-- ============================================================================

CREATE TABLE action_dependencies (
    execution_id VARCHAR(64) NOT NULL,
    action_id VARCHAR(64) NOT NULL,
    depends_on_action_id VARCHAR(64) NOT NULL,

    PRIMARY KEY (action_id, depends_on_action_id),

    CONSTRAINT fk_action_dep_target
        FOREIGN KEY (execution_id, action_id)
        REFERENCES planned_actions(execution_id, action_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_action_dep_prereq
        FOREIGN KEY (execution_id, depends_on_action_id)
        REFERENCES planned_actions(execution_id, action_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_no_self_dependency
        CHECK (action_id <> depends_on_action_id)
);


-- ============================================================================
-- 11. CALENDAR EVENT SYNCHRONIZATION
-- Stores EchoVault's local sync metadata and external Google Calendar ID.
-- action_id and chunk_id are independently optional references.
-- ============================================================================

CREATE TABLE calendar_event_sync (
    sync_id VARCHAR(64) PRIMARY KEY,
    action_id VARCHAR(64)
        REFERENCES planned_actions(action_id) ON DELETE SET NULL,
    chunk_id VARCHAR(64)
        REFERENCES transcript_chunks(chunk_id) ON DELETE SET NULL,
    external_event_id VARCHAR(128) NOT NULL UNIQUE,
    event_summary VARCHAR(255) NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    sync_status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (sync_status IN ('PENDING', 'SUCCESS', 'FAILED')),
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_event_times
        CHECK (end_time >= start_time)
);

CREATE INDEX idx_calendar_sync_chunk
    ON calendar_event_sync(chunk_id);

CREATE INDEX idx_calendar_sync_action
    ON calendar_event_sync(action_id);


-- ============================================================================
-- 12. TASK REMINDERS
-- Local tasks, scheduled reminders, and proactive follow-ups.
-- ============================================================================

CREATE TABLE task_reminders (
    reminder_id VARCHAR(64) PRIMARY KEY,
    user_id UUID NOT NULL
        REFERENCES users(user_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    scheduled_for TIMESTAMPTZ,
    due_date TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'COMPLETED', 'CANCELLED')),
    category VARCHAR(50) NOT NULL DEFAULT 'General',
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM'
        CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH')),
    source VARCHAR(50) NOT NULL DEFAULT 'agent',
    external_reference VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reminders_user_sched
    ON task_reminders(user_id, scheduled_for);


-- ============================================================================
-- 13. PENDING CONTACTS
-- Holds phone numbers captured before the person's identity is verified.
-- A reminder link is optional and unique when present.
-- ============================================================================

CREATE TABLE pending_contacts (
    pending_id VARCHAR(64) PRIMARY KEY,
    user_id UUID NOT NULL
        REFERENCES users(user_id) ON DELETE CASCADE,
    phone VARCHAR(32) NOT NULL,
    name VARCHAR(150),
    status VARCHAR(30) NOT NULL DEFAULT 'pending_name'
        CHECK (status IN ('pending_name', 'resolved', 'dismissed')),
    confidence VARCHAR(10) NOT NULL DEFAULT 'LOW'
        CHECK (confidence IN ('LOW', 'MEDIUM', 'HIGH')),
    context TEXT,
    source VARCHAR(50) NOT NULL DEFAULT 'explicit_statement',
    reminder_id VARCHAR(64) UNIQUE
        REFERENCES task_reminders(reminder_id) ON DELETE SET NULL,
    google_resource_name VARCHAR(128),
    captured_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Only one active pending contact per phone number per user.
CREATE UNIQUE INDEX uq_user_phone_active_pending
    ON pending_contacts(user_id, phone)
    WHERE status = 'pending_name';


-- ============================================================================
-- 14. CONVERSATION SESSIONS
-- Persistent chat threads for multi-turn agent context.
-- ============================================================================

CREATE TABLE conversation_sessions (
    conversation_id VARCHAR(64) PRIMARY KEY,
    user_id UUID NOT NULL
        REFERENCES users(user_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL DEFAULT 'New Conversation',
    started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_message_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_conversations_user
    ON conversation_sessions(user_id);


-- ============================================================================
-- 15. CONVERSATION MESSAGES
-- Individual user, assistant, or system messages within a conversation.
-- ============================================================================

CREATE TABLE conversation_messages (
    message_id VARCHAR(64) PRIMARY KEY,
    conversation_id VARCHAR(64) NOT NULL
        REFERENCES conversation_sessions(conversation_id) ON DELETE CASCADE,
    sender_role VARCHAR(20) NOT NULL
        CHECK (sender_role IN ('user', 'assistant', 'system')),
    message_content TEXT NOT NULL,
    message_seq INTEGER NOT NULL DEFAULT 1,
    "timestamp" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_conv_message_seq
        UNIQUE (conversation_id, message_seq)
);

CREATE INDEX idx_messages_conv_seq
    ON conversation_messages(conversation_id, message_seq);


COMMIT;

-- ============================================================================
-- END OF ECHOVAULT SCHEMA
-- ============================================================================
