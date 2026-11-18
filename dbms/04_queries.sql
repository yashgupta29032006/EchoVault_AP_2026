-- ============================================================================
-- ECHOVAULT DATABASE WORKLOAD QUERIES
-- File: dbms/04_queries.sql
-- Checkpoint: CP3 Deliverable
-- Target DBMS: PostgreSQL 16+
-- Schema: 15-Table Normalized Architecture (dbms/03_schema.sql)
--
-- WORKLOAD SPECIFICATION:
--   Total Queries : 28
--   Read Queries  : 20 (R01 - R20)
--   Write Queries : 8  (W01 - W08)
--
-- REPEATABLE BENCHMARKING (CP4 READY):
--   - Wrapped entirely within a transaction block (BEGIN ... ROLLBACK).
--   - Executing this file performs complete syntax, constraint, and relation
--     validation without persisting persistent side effects.
--   - Seed data is instantiated at the start of the transaction so that
--     every read query operates on populated relational data.
--   - Tagged with standardized query markers (-- @R01, -- @W01) and
--     explicit operation types (-- READ / -- WRITE) for automated parsers.
--
-- PARAMETER DOCUMENTATION:
--   - 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' : Primary test user UUID (users.user_id)
--   - 'sess_live_audio_20261119_001'          : Active audio capture session ID
--   - 'chunk_audio_20261119_001'             : Transcribed speech utterance ID
--   - 'mem_refined_20261119_001'             : Synthesized semantic memory ID
--   - 'exec_auto_plan_20261119_001'          : Agent automation workflow ID
--   - 'conv_chat_20261119_001'               : Multi-turn chat session ID
-- ============================================================================

BEGIN;

-- ============================================================================
-- SECTION 1: BENCHMARK SEED DATA (ISOLATED WITHIN TRANSACTION)
-- Provides valid referential integrity targets for both READ and WRITE workloads.
-- ============================================================================

INSERT INTO users (user_id, email, full_name, created_at)
VALUES (
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'yash.gupta@echovault.local',
    'Yash Gupta',
    CURRENT_TIMESTAMP - INTERVAL '30 days'
)
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO listening_sessions (session_id, user_id, status, started_at, ended_at, duration_seconds)
VALUES
(
    'sess_live_audio_20261119_001',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'listening',
    CURRENT_TIMESTAMP - INTERVAL '45 minutes',
    NULL,
    2700.0
),
(
    'sess_live_audio_20261118_099',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'stopped',
    CURRENT_TIMESTAMP - INTERVAL '1 day 2 hours',
    CURRENT_TIMESTAMP - INTERVAL '1 day 1 hour',
    3600.0
)
ON CONFLICT (session_id) DO NOTHING;

INSERT INTO session_pause_intervals (session_id, paused_at, resumed_at, pause_duration_seconds)
VALUES
(
    'sess_live_audio_20261119_001',
    CURRENT_TIMESTAMP - INTERVAL '30 minutes',
    CURRENT_TIMESTAMP - INTERVAL '27 minutes',
    180.0
),
(
    'sess_live_audio_20261119_001',
    CURRENT_TIMESTAMP - INTERVAL '10 minutes',
    CURRENT_TIMESTAMP - INTERVAL '8 minutes',
    120.0
),
(
    'sess_live_audio_20261119_001',
    CURRENT_TIMESTAMP - INTERVAL '2 minutes',
    NULL,
    NULL
);

INSERT INTO transcript_chunks (
    chunk_id, session_id, sequence_number, "timestamp", text, original_text,
    raw_confidence, speaker, start_time, end_time, is_deleted, is_reviewed,
    is_important, category, last_edited_at, is_final
)
VALUES
(
    'chunk_audio_20261119_001',
    'sess_live_audio_20261119_001',
    1,
    CURRENT_TIMESTAMP - INTERVAL '40 minutes',
    'Let us finalize the architecture review for Checkpoint 3 today.',
    'Let us finalize the architecture review for Checkpoint 3 today.',
    -0.12,
    'Yash',
    0.0,
    4.5,
    FALSE,
    FALSE,
    TRUE,
    'Meeting',
    NULL,
    TRUE
),
(
    'chunk_audio_20261119_002',
    'sess_live_audio_20261119_001',
    2,
    CURRENT_TIMESTAMP - INTERVAL '39 minutes 50 seconds',
    'I will also call Rahul at +919876543210 regarding the database schema.',
    'I will also call Rahul at +919876543210 regarding the database schema.',
    -0.08,
    'Yash',
    5.0,
    10.2,
    FALSE,
    FALSE,
    FALSE,
    'Action Item',
    NULL,
    TRUE
),
(
    'chunk_audio_20261119_003',
    'sess_live_audio_20261119_001',
    3,
    CURRENT_TIMESTAMP - INTERVAL '39 minutes 35 seconds',
    'Unclear whisper segment in noisy room background.',
    'Unclear whisper segment in noisy room background.',
    -0.85,
    'Unknown',
    11.0,
    14.0,
    FALSE,
    FALSE,
    FALSE,
    'Other',
    NULL,
    TRUE
)
ON CONFLICT (chunk_id) DO NOTHING;

INSERT INTO refined_memories (
    refined_id, user_id, summary, category, status, importance_score, last_updated, is_deleted
)
VALUES
(
    'mem_refined_20261119_001',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Finalized DBMS Checkpoint 3 query architecture and discussed schema alignment with Rahul.',
    'Project',
    'active',
    0.92,
    CURRENT_TIMESTAMP - INTERVAL '35 minutes',
    FALSE
),
(
    'mem_refined_20261119_002',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Planned Boyy hardware testing session with wearable audio segmentation.',
    'Wearable',
    'active',
    0.85,
    CURRENT_TIMESTAMP - INTERVAL '2 hours',
    FALSE
)
ON CONFLICT (refined_id) DO NOTHING;

INSERT INTO memory_chunk_sources (refined_id, chunk_id, association_score)
VALUES
(
    'mem_refined_20261119_001',
    'chunk_audio_20261119_001',
    0.95
),
(
    'mem_refined_20261119_001',
    'chunk_audio_20261119_002',
    0.88
)
ON CONFLICT (refined_id, chunk_id) DO NOTHING;

INSERT INTO memory_entities (refined_id, entity_type, entity_value)
VALUES
(
    'mem_refined_20261119_001',
    'Project',
    'EchoVault Checkpoint 3'
),
(
    'mem_refined_20261119_001',
    'Person',
    'Rahul'
),
(
    'mem_refined_20261119_001',
    'Topic',
    'DBMS Normalization & Queries'
),
(
    'mem_refined_20261119_002',
    'Project',
    'Boyy Hardware'
)
ON CONFLICT (refined_id, entity_type, entity_value) DO NOTHING;

INSERT INTO automation_executions (
    execution_id, session_id, user_id, command_text, detected_intent, status, error_message, created_at, updated_at
)
VALUES (
    'exec_auto_plan_20261119_001',
    'sess_live_audio_20261119_001',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Schedule sync meeting with Rahul and set a reminder to review schema',
    'SCHEDULE_AND_REMIND',
    'CONFIRMED',
    NULL,
    CURRENT_TIMESTAMP - INTERVAL '25 minutes',
    CURRENT_TIMESTAMP - INTERVAL '24 minutes'
)
ON CONFLICT (execution_id) DO NOTHING;

INSERT INTO planned_actions (
    action_id, execution_id, tool_name, action_verb, parameters_payload, status, result_payload, error_message, sequence_order, executed_at
)
VALUES
(
    'act_plan_20261119_001',
    'exec_auto_plan_20261119_001',
    'CalendarTool',
    'create_event',
    '{"title": "Sync with Rahul on DBMS Schema", "duration_minutes": 30, "attendees": ["rahul@echovault.local"]}'::jsonb,
    'success',
    '{"event_id": "google_cal_ev_84920482", "status": "confirmed", "execution_time_ms": 340}'::jsonb,
    NULL,
    1,
    CURRENT_TIMESTAMP - INTERVAL '24 minutes'
),
(
    'act_plan_20261119_002',
    'exec_auto_plan_20261119_001',
    'ReminderTool',
    'create_reminder',
    '{"title": "Prepare query plans before meeting", "priority": "HIGH", "due_in_hours": 2}'::jsonb,
    'pending',
    NULL,
    NULL,
    2,
    NULL
)
ON CONFLICT (action_id) DO NOTHING;

INSERT INTO action_dependencies (execution_id, action_id, depends_on_action_id)
VALUES (
    'exec_auto_plan_20261119_001',
    'act_plan_20261119_002',
    'act_plan_20261119_001'
)
ON CONFLICT (action_id, depends_on_action_id) DO NOTHING;

INSERT INTO calendar_event_sync (
    sync_id, action_id, chunk_id, external_event_id, event_summary,
    start_time, end_time, sync_status, error_message, created_at, updated_at
)
VALUES (
    'sync_cal_20261119_001',
    'act_plan_20261119_001',
    'chunk_audio_20261119_001',
    'google_cal_ev_84920482',
    'Sync with Rahul on DBMS Schema',
    CURRENT_TIMESTAMP + INTERVAL '1 day',
    CURRENT_TIMESTAMP + INTERVAL '1 day 30 minutes',
    'SUCCESS',
    NULL,
    CURRENT_TIMESTAMP - INTERVAL '24 minutes',
    CURRENT_TIMESTAMP - INTERVAL '24 minutes'
)
ON CONFLICT (sync_id) DO NOTHING;

INSERT INTO task_reminders (
    reminder_id, user_id, title, description, scheduled_for, due_date,
    status, category, priority, source, external_reference, created_at, updated_at
)
VALUES
(
    'rem_task_20261119_001',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Confirm identity and save contact for Rahul (+919876543210)',
    'Spoken in audio session regarding DBMS schema alignment.',
    CURRENT_TIMESTAMP + INTERVAL '4 hours',
    CURRENT_TIMESTAMP + INTERVAL '24 hours',
    'PENDING',
    'Contact Verification',
    'HIGH',
    'agent',
    NULL,
    CURRENT_TIMESTAMP - INTERVAL '20 minutes',
    CURRENT_TIMESTAMP - INTERVAL '20 minutes'
),
(
    'rem_task_20261119_002',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Submit DBMS Checkpoint 3 queries on portal',
    'Upload 04_queries.sql to GitHub repository.',
    CURRENT_TIMESTAMP - INTERVAL '1 hour',
    CURRENT_TIMESTAMP - INTERVAL '30 minutes',
    'PENDING',
    'Academics',
    'HIGH',
    'user',
    NULL,
    CURRENT_TIMESTAMP - INTERVAL '2 days',
    CURRENT_TIMESTAMP - INTERVAL '2 days'
)
ON CONFLICT (reminder_id) DO NOTHING;

INSERT INTO pending_contacts (
    pending_id, user_id, phone, name, status, confidence, context,
    source, reminder_id, google_resource_name, captured_at, resolved_at, updated_at
)
VALUES (
    'pend_contact_20261119_001',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    '+919876543210',
    'Rahul',
    'pending_name',
    'MEDIUM',
    'Spoken during listening session: "I will also call Rahul at +919876543210 regarding the database schema."',
    'explicit_statement',
    'rem_task_20261119_001',
    NULL,
    CURRENT_TIMESTAMP - INTERVAL '20 minutes',
    NULL,
    CURRENT_TIMESTAMP - INTERVAL '20 minutes'
)
ON CONFLICT (pending_id) DO NOTHING;

INSERT INTO conversation_sessions (conversation_id, user_id, title, started_at, last_message_at, is_archived)
VALUES (
    'conv_chat_20261119_001',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Architecture Review & Tasks',
    CURRENT_TIMESTAMP - INTERVAL '1 hour',
    CURRENT_TIMESTAMP - INTERVAL '10 minutes',
    FALSE
)
ON CONFLICT (conversation_id) DO NOTHING;

INSERT INTO conversation_messages (message_id, conversation_id, sender_role, message_content, message_seq, "timestamp")
VALUES
(
    'msg_turn_20261119_001',
    'conv_chat_20261119_001',
    'user',
    'What meetings and tasks do I have pending for today?',
    1,
    CURRENT_TIMESTAMP - INTERVAL '15 minutes'
),
(
    'msg_turn_20261119_002',
    'conv_chat_20261119_001',
    'assistant',
    'You have a pending schema sync meeting scheduled with Rahul and an urgent task to verify his contact info.',
    2,
    CURRENT_TIMESTAMP - INTERVAL '14 minutes'
)
ON CONFLICT (message_id) DO NOTHING;


-- ============================================================================
-- SECTION 2: READ QUERIES (R01 - R20)
-- ============================================================================

-- @R01
-- READ
-- Purpose: User profile and operational activity summary without row multiplication.
-- Real-world use case: Executed upon application launch / dashboard load. Aggregates counts of
-- active sessions, active memories, pending tasks, and unverified contacts independently per user.
-- Tables: users, listening_sessions, refined_memories, task_reminders, pending_contacts
WITH session_stats AS (
    SELECT
        user_id,
        COUNT(*) AS total_sessions,
        COUNT(*) FILTER (WHERE status = 'listening') AS active_sessions
    FROM listening_sessions
    WHERE user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    GROUP BY user_id
),
memory_stats AS (
    SELECT
        user_id,
        COUNT(*) AS total_memories,
        COUNT(*) FILTER (WHERE status = 'active' AND is_deleted = FALSE) AS active_memories
    FROM refined_memories
    WHERE user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    GROUP BY user_id
),
reminder_stats AS (
    SELECT
        user_id,
        COUNT(*) AS total_reminders,
        COUNT(*) FILTER (WHERE status = 'PENDING') AS pending_reminders
    FROM task_reminders
    WHERE user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    GROUP BY user_id
),
contact_stats AS (
    SELECT
        user_id,
        COUNT(*) AS total_pending_contacts,
        COUNT(*) FILTER (WHERE status = 'pending_name') AS unresolved_contacts
    FROM pending_contacts
    WHERE user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
    GROUP BY user_id
)
SELECT
    u.user_id,
    u.email,
    u.full_name,
    u.created_at,
    COALESCE(ss.total_sessions, 0) AS total_sessions,
    COALESCE(ss.active_sessions, 0) AS active_sessions,
    COALESCE(ms.total_memories, 0) AS total_memories,
    COALESCE(ms.active_memories, 0) AS active_memories,
    COALESCE(rs.total_reminders, 0) AS total_reminders,
    COALESCE(rs.pending_reminders, 0) AS pending_reminders,
    COALESCE(cs.total_pending_contacts, 0) AS total_pending_contacts,
    COALESCE(cs.unresolved_contacts, 0) AS unresolved_contacts
FROM users u
LEFT JOIN session_stats ss ON u.user_id = ss.user_id
LEFT JOIN memory_stats ms ON u.user_id = ms.user_id
LEFT JOIN reminder_stats rs ON u.user_id = rs.user_id
LEFT JOIN contact_stats cs ON u.user_id = cs.user_id
WHERE u.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';


-- @R02
-- READ
-- Purpose: Active and recent listening sessions with cumulative pause statistics.
-- Real-world use case: Real-time audio ingestion monitoring screen. Calculates total recorded
-- duration, total pause intervals, and cumulative paused duration, correctly handling unfinished pauses.
-- Tables: listening_sessions, session_pause_intervals
SELECT
    ls.session_id,
    ls.user_id,
    ls.status,
    ls.started_at,
    ls.ended_at,
    ls.duration_seconds AS recorded_duration_seconds,
    COUNT(spi.interval_id) AS total_pause_intervals,
    COUNT(spi.interval_id) FILTER (WHERE spi.resumed_at IS NULL) AS ongoing_pause_count,
    ROUND(
        COALESCE(
            SUM(
                COALESCE(
                    spi.pause_duration_seconds,
                    EXTRACT(EPOCH FROM (COALESCE(spi.resumed_at, CURRENT_TIMESTAMP) - spi.paused_at))
                )
            ), 0.0
        )::NUMERIC, 2
    ) AS total_paused_duration_seconds
FROM listening_sessions ls
LEFT JOIN session_pause_intervals spi ON ls.session_id = spi.session_id
WHERE ls.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
GROUP BY ls.session_id, ls.user_id, ls.status, ls.started_at, ls.ended_at, ls.duration_seconds
ORDER BY ls.started_at DESC
LIMIT 20;


-- @R03
-- READ
-- Purpose: Chronological pause interval timeline for a session with running cumulative duration.
-- Real-world use case: Hardware diagnostic audit for Boyy wearable audio streaming stability.
-- Examines pause events in order, flagging ongoing pauses and calculating running total pause time.
-- Tables: session_pause_intervals
SELECT
    spi.interval_id,
    spi.session_id,
    spi.paused_at,
    spi.resumed_at,
    CASE
        WHEN spi.resumed_at IS NULL THEN TRUE
        ELSE FALSE
    END AS is_ongoing,
    ROUND(
        COALESCE(
            spi.pause_duration_seconds,
            EXTRACT(EPOCH FROM (COALESCE(spi.resumed_at, CURRENT_TIMESTAMP) - spi.paused_at))
        )::NUMERIC, 2
    ) AS effective_pause_duration_seconds,
    ROUND(
        SUM(
            COALESCE(
                spi.pause_duration_seconds,
                EXTRACT(EPOCH FROM (COALESCE(spi.resumed_at, CURRENT_TIMESTAMP) - spi.paused_at))
            )
        ) OVER (
            PARTITION BY spi.session_id
            ORDER BY spi.paused_at
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )::NUMERIC, 2
    ) AS running_cumulative_pause_seconds
FROM session_pause_intervals spi
WHERE spi.session_id = 'sess_live_audio_20261119_001'
ORDER BY spi.paused_at ASC;


-- @R04
-- READ
-- Purpose: Chronological audio transcript stream with inter-chunk speech latency.
-- Real-world use case: UI live transcript viewer. Employs window function LAG() to calculate
-- silence gap latency between consecutive speech utterances in an active listening session.
-- Tables: transcript_chunks
SELECT
    tc.chunk_id,
    tc.session_id,
    tc.sequence_number,
    tc."timestamp",
    tc.speaker,
    tc.text,
    tc.confidence,
    tc.start_time,
    tc.end_time,
    ROUND((tc.end_time - tc.start_time)::NUMERIC, 2) AS utterance_duration_seconds,
    ROUND(
        (tc.start_time - LAG(tc.end_time, 1) OVER (
            PARTITION BY tc.session_id
            ORDER BY tc.sequence_number ASC
        ))::NUMERIC, 2
    ) AS silence_gap_before_utterance_seconds
FROM transcript_chunks tc
WHERE tc.session_id = 'sess_live_audio_20261119_001'
  AND tc.is_deleted = FALSE
ORDER BY tc.sequence_number ASC;


-- @R05
-- READ
-- Purpose: Low-confidence speech segments triage queue for human-in-the-loop review.
-- Real-world use case: Quality assurance queue. Discovers audio segments where speech
-- transcription confidence fell below 70%, allowing users to correct or flag transcription errors.
-- Tables: transcript_chunks, listening_sessions
SELECT
    tc.chunk_id,
    tc.session_id,
    tc.sequence_number,
    tc."timestamp",
    tc.speaker,
    tc.text,
    tc.raw_confidence,
    tc.confidence,
    tc.category,
    tc.is_reviewed,
    ls.user_id
FROM transcript_chunks tc
JOIN listening_sessions ls ON tc.session_id = ls.session_id
WHERE ls.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
  AND tc.is_deleted = FALSE
  AND tc.is_reviewed = FALSE
  AND tc.confidence < 70
ORDER BY tc.confidence ASC, tc."timestamp" DESC
LIMIT 50;


-- @R06
-- READ
-- Purpose: Speaker speaking duration, acoustic confidence, and estimated word count (excluding deleted chunks).
-- Real-world use case: Meeting analytics and speaker diarization breakdown. Calculates aggregate talk
-- time (end_time - start_time), utterance counts, confidence range, and word frequency per speaker.
-- Tables: transcript_chunks, listening_sessions
SELECT
    COALESCE(tc.speaker, 'Unknown') AS speaker_name,
    COUNT(tc.chunk_id) AS total_chunks,
    ROUND(SUM((tc.end_time - tc.start_time))::NUMERIC, 2) AS total_speaking_seconds,
    ROUND(AVG(tc.confidence)::NUMERIC, 2) AS avg_confidence,
    ROUND(MIN(tc.confidence)::NUMERIC, 2) AS min_confidence,
    ROUND(MAX(tc.confidence)::NUMERIC, 2) AS max_confidence,
    SUM(
        CASE
            WHEN trim(tc.text) = '' THEN 0
            ELSE array_length(string_to_array(trim(tc.text), ' '), 1)
        END
    ) AS estimated_word_count
FROM transcript_chunks tc
JOIN listening_sessions ls ON tc.session_id = ls.session_id
WHERE ls.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
  AND tc.is_deleted = FALSE
GROUP BY COALESCE(tc.speaker, 'Unknown')
HAVING COUNT(tc.chunk_id) > 0
ORDER BY total_speaking_seconds DESC;


-- @R07
-- READ
-- Purpose: Active semantic memories joined with contributing transcript chunks and association weights.
-- Real-world use case: RAG citation assembler. Reconstructs provenance chains by linking consolidated
-- memories back to the exact speech chunks that formed them via the associative junction table.
-- Tables: refined_memories, memory_chunk_sources, transcript_chunks
SELECT
    rm.refined_id,
    rm.summary AS memory_summary,
    rm.category AS memory_category,
    rm.importance_score,
    rm.last_updated,
    mcs.association_score,
    tc.chunk_id AS source_chunk_id,
    tc.speaker AS source_speaker,
    tc.text AS source_transcript_text,
    tc.confidence AS speech_confidence,
    tc."timestamp" AS utterance_time
FROM refined_memories rm
JOIN memory_chunk_sources mcs ON rm.refined_id = mcs.refined_id
JOIN transcript_chunks tc ON mcs.chunk_id = tc.chunk_id
WHERE rm.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
  AND rm.status = 'active'
  AND rm.is_deleted = FALSE
  AND tc.is_deleted = FALSE
ORDER BY rm.importance_score DESC, mcs.association_score DESC;


-- @R08
-- READ
-- Purpose: Search refined memories by entity type/value and aggregate all associated named entities.
-- Real-world use case: Knowledge Vault entity search ("What did I discuss regarding Yash or EchoVault?").
-- Aggregates extracted entities as a delimited string per matching memory.
-- Tables: refined_memories, memory_entities
SELECT
    rm.refined_id,
    rm.summary,
    rm.category,
    rm.importance_score,
    rm.last_updated,
    STRING_AGG(DISTINCT me.entity_type || ': ' || me.entity_value, '; ' ORDER BY me.entity_type || ': ' || me.entity_value) AS extracted_entities
FROM refined_memories rm
JOIN memory_entities me ON rm.refined_id = me.refined_id
WHERE rm.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
  AND rm.is_deleted = FALSE
  AND rm.refined_id IN (
      SELECT inner_me.refined_id
      FROM memory_entities inner_me
      WHERE inner_me.entity_value ILIKE '%EchoVault%'
         OR inner_me.entity_value ILIKE '%Yash%'
  )
GROUP BY rm.refined_id, rm.summary, rm.category, rm.importance_score, rm.last_updated
ORDER BY rm.importance_score DESC, rm.last_updated DESC;


-- @R09
-- READ
-- Purpose: Rank named entities by occurrence frequency within each entity category.
-- Real-world use case: Entity analytics dashboard. Identifies top mentioned people, projects,
-- and topics across the user's intelligence layer using DENSE_RANK() window partitioning.
-- Tables: memory_entities, refined_memories
WITH entity_frequencies AS (
    SELECT
        me.entity_type,
        me.entity_value,
        COUNT(me.entity_id) AS mention_count,
        COUNT(DISTINCT rm.refined_id) AS distinct_memory_count
    FROM memory_entities me
    JOIN refined_memories rm ON me.refined_id = rm.refined_id
    WHERE rm.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
      AND rm.is_deleted = FALSE
    GROUP BY me.entity_type, me.entity_value
)
SELECT
    ef.entity_type,
    ef.entity_value,
    ef.mention_count,
    ef.distinct_memory_count,
    DENSE_RANK() OVER (
        PARTITION BY ef.entity_type
        ORDER BY ef.mention_count DESC, ef.distinct_memory_count DESC
    ) AS rank_within_category
FROM entity_frequencies ef
ORDER BY ef.entity_type ASC, rank_within_category ASC
LIMIT 50;


-- @R10
-- READ
-- Purpose: Trace memories synthesized from an audio chunk, aggregating memories into JSON objects.
-- Real-world use case: Provenance footprint auditing. When a transcript chunk is edited or retracted,
-- determines all downstream refined memories and rolls them up into a structured JSON array.
-- Tables: transcript_chunks, memory_chunk_sources, refined_memories
SELECT
    tc.chunk_id,
    tc.session_id,
    tc.speaker,
    tc.text AS transcript_text,
    tc.confidence,
    COUNT(rm.refined_id) AS derived_memory_count,
    JSONB_AGG(
        JSONB_BUILD_OBJECT(
            'refined_id', rm.refined_id,
            'summary', rm.summary,
            'category', rm.category,
            'importance_score', rm.importance_score,
            'status', rm.status,
            'association_score', mcs.association_score
        ) ORDER BY mcs.association_score DESC
    ) AS synthesized_memories
FROM transcript_chunks tc
JOIN memory_chunk_sources mcs ON tc.chunk_id = mcs.chunk_id
JOIN refined_memories rm ON mcs.refined_id = rm.refined_id
WHERE tc.chunk_id = 'chunk_audio_20261119_001'
  AND rm.is_deleted = FALSE
GROUP BY tc.chunk_id, tc.session_id, tc.speaker, tc.text, tc.confidence;


-- @R11
-- READ
-- Purpose: Google Calendar sync audit with dual-path provenance resolution (action vs. chunk extraction).
-- Real-world use case: Calendar integration audit. Resolves whether each synced event was triggered
-- by an agent action DAG node, speech entity extraction, both, or an external push.
-- Tables: calendar_event_sync, planned_actions, transcript_chunks
SELECT
    ces.sync_id,
    ces.external_event_id,
    ces.event_summary,
    ces.start_time,
    ces.end_time,
    ces.sync_status,
    ces.error_message,
    CASE
        WHEN ces.action_id IS NOT NULL AND ces.chunk_id IS NOT NULL THEN 'DUAL_PROVENANCE'
        WHEN ces.action_id IS NOT NULL THEN 'ACTION_TRIGGERED'
        WHEN ces.chunk_id IS NOT NULL THEN 'CHUNK_EXTRACTED'
        ELSE 'EXTERNAL_SYNC'
    END AS provenance_type,
    ces.action_id,
    pa.tool_name AS originating_tool,
    pa.action_verb AS originating_action_verb,
    ces.chunk_id,
    tc.text AS originating_speech_text,
    tc.confidence AS speech_confidence
FROM calendar_event_sync ces
LEFT JOIN planned_actions pa ON ces.action_id = pa.action_id
LEFT JOIN transcript_chunks tc ON ces.chunk_id = tc.chunk_id
ORDER BY ces.created_at DESC
LIMIT 50;


-- @R12
-- READ
-- Purpose: Workflow status breakdown and lifecycle elapsed time rollup.
-- Real-world use case: Agent Engine observability dashboard. Audits multi-action workflows,
-- counting actions by status and approximating lifecycle duration between creation and final update.
-- Tables: automation_executions, planned_actions
SELECT
    ae.execution_id,
    ae.user_id,
    ae.command_text,
    ae.detected_intent,
    ae.status AS execution_status,
    ae.created_at,
    ae.updated_at,
    ROUND(EXTRACT(EPOCH FROM (ae.updated_at - ae.created_at))::NUMERIC, 2) AS lifecycle_elapsed_seconds,
    COUNT(pa.action_id) AS total_planned_actions,
    COUNT(pa.action_id) FILTER (WHERE pa.status = 'success') AS successful_actions,
    COUNT(pa.action_id) FILTER (WHERE pa.status = 'failed') AS failed_actions,
    COUNT(pa.action_id) FILTER (WHERE pa.status = 'running') AS running_actions,
    COUNT(pa.action_id) FILTER (WHERE pa.status = 'pending') AS pending_actions,
    COUNT(pa.action_id) FILTER (WHERE pa.status IN ('blocked', 'skipped')) AS blocked_or_skipped_actions
FROM automation_executions ae
LEFT JOIN planned_actions pa ON ae.execution_id = pa.execution_id
WHERE ae.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
GROUP BY ae.execution_id, ae.user_id, ae.command_text, ae.detected_intent, ae.status, ae.created_at, ae.updated_at
ORDER BY ae.created_at DESC;


-- @R13
-- READ
-- Purpose: Topological DAG scheduler resolving pending actions whose prerequisites have all succeeded (or have no dependencies).
-- Real-world use case: Core AgentEngine dispatch loop. Discovers ready actions eligible for immediate
-- execution because every required prerequisite action has status = 'success', or no prerequisites exist.
-- Tables: planned_actions, action_dependencies
SELECT
    pa.action_id,
    pa.execution_id,
    pa.tool_name,
    pa.action_verb,
    pa.sequence_order,
    pa.parameters_payload,
    pa.status,
    (
        SELECT COUNT(*)
        FROM action_dependencies ad
        WHERE ad.execution_id = pa.execution_id
          AND ad.action_id = pa.action_id
    ) AS prerequisite_count
FROM planned_actions pa
WHERE pa.execution_id = 'exec_auto_plan_20261119_001'
  AND pa.status = 'pending'
  AND NOT EXISTS (
      SELECT 1
      FROM action_dependencies ad
      JOIN planned_actions prereq
        ON ad.execution_id = prereq.execution_id
       AND ad.depends_on_action_id = prereq.action_id
      WHERE ad.execution_id = pa.execution_id
        AND ad.action_id = pa.action_id
        AND prereq.status <> 'success'
  )
ORDER BY pa.sequence_order ASC;


-- @R14
-- READ
-- Purpose: Reconstruct and audit action dependency edges for an automation execution plan.
-- Real-world use case: Visual DAG debugger. Performs a multi-aliased self-join on planned_actions
-- to display each action alongside its prerequisite action verb, tool name, and status.
-- Tables: action_dependencies, planned_actions (aliased curr and prereq), automation_executions
SELECT
    ad.execution_id,
    ae.command_text,
    curr.action_id AS child_action_id,
    curr.sequence_order AS child_seq,
    curr.tool_name AS child_tool,
    curr.action_verb AS child_verb,
    curr.status AS child_status,
    prereq.action_id AS prerequisite_action_id,
    prereq.sequence_order AS prerequisite_seq,
    prereq.tool_name AS prerequisite_tool,
    prereq.action_verb AS prerequisite_verb,
    prereq.status AS prerequisite_status
FROM action_dependencies ad
JOIN automation_executions ae ON ad.execution_id = ae.execution_id
JOIN planned_actions curr
  ON ad.execution_id = curr.execution_id
 AND ad.action_id = curr.action_id
JOIN planned_actions prereq
  ON ad.execution_id = prereq.execution_id
 AND ad.depends_on_action_id = prereq.action_id
WHERE ad.execution_id = 'exec_auto_plan_20261119_001'
ORDER BY curr.sequence_order ASC, prereq.sequence_order ASC;


-- @R15
-- READ
-- Purpose: External tool execution reliability, failure rate %, and JSONB error extraction.
-- Real-world use case: Agent tool reliability benchmarking. Inspects JSONB payloads to calculate
-- tool invocation count, failure rates, JSON error frequency, and average execution latency.
-- Tables: planned_actions
SELECT
    pa.tool_name,
    COUNT(*) AS total_invocations,
    COUNT(*) FILTER (WHERE pa.status = 'success') AS success_count,
    COUNT(*) FILTER (WHERE pa.status = 'failed') AS failure_count,
    ROUND(
        (COUNT(*) FILTER (WHERE pa.status = 'failed')::NUMERIC / NULLIF(COUNT(*), 0) * 100.0), 2
    ) AS failure_rate_percentage,
    COUNT(*) FILTER (WHERE pa.result_payload ? 'error') AS json_reported_errors,
    ROUND(
        AVG(
            CASE
                WHEN pa.result_payload ? 'execution_time_ms'
                THEN (pa.result_payload ->> 'execution_time_ms')::NUMERIC
                ELSE NULL
            END
        ), 2
    ) AS avg_reported_latency_ms
FROM planned_actions pa
GROUP BY pa.tool_name
ORDER BY total_invocations DESC;


-- @R16
-- READ
-- Purpose: Ambiguous phone numbers captured from speech awaiting verification with follow-up reminder details.
-- Real-world use case: Contact capture resolution interface. Surfaces unverified phone numbers
-- paired with their automatically generated follow-up task reminders via 1:1 foreign key.
-- Tables: pending_contacts, task_reminders
SELECT
    pc.pending_id,
    pc.user_id,
    pc.phone,
    pc.name AS tentative_name,
    pc.status AS contact_status,
    pc.confidence AS capture_confidence,
    pc.context AS spoken_context,
    pc.source AS extraction_source,
    pc.captured_at,
    tr.reminder_id,
    tr.title AS reminder_title,
    tr.scheduled_for AS reminder_scheduled_time,
    tr.due_date AS reminder_due_date,
    tr.priority AS reminder_priority,
    tr.status AS reminder_status
FROM pending_contacts pc
LEFT JOIN task_reminders tr ON pc.reminder_id = tr.reminder_id
WHERE pc.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
  AND pc.status = 'pending_name'
ORDER BY pc.captured_at DESC;


-- @R17
-- READ
-- Purpose: Pending task agenda ordered by priority (HIGH > MEDIUM > LOW) and overdue status (using schema enum values).
-- Real-world use case: Proactive morning agenda briefing. Fetches all active reminders in 'PENDING'
-- status, flagging overdue deadlines and sorting strictly by operational priority.
-- Tables: task_reminders
SELECT
    tr.reminder_id,
    tr.user_id,
    tr.title,
    tr.description,
    tr.scheduled_for,
    tr.due_date,
    tr.status,
    tr.category,
    tr.priority,
    tr.source,
    tr.external_reference,
    CASE
        WHEN tr.due_date IS NOT NULL AND tr.due_date < CURRENT_TIMESTAMP THEN TRUE
        ELSE FALSE
    END AS is_overdue,
    ROUND(
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - tr.due_date)) / 3600.0, 1
    ) AS hours_overdue
FROM task_reminders tr
WHERE tr.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
  AND tr.status = 'PENDING'
ORDER BY
    CASE tr.priority
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        WHEN 'LOW' THEN 3
        ELSE 4
    END ASC,
    tr.due_date ASC NULLS LAST;


-- @R18
-- READ
-- Purpose: Chronological multi-turn conversational message history for an active session.
-- Real-world use case: Chat interface rendering. Retrieves sequenced dialogue turns between user
-- and assistant for multi-turn context reconstruction, supporting pagination with LIMIT and OFFSET.
-- Tables: conversation_sessions, conversation_messages
SELECT
    cs.conversation_id,
    cs.user_id,
    cs.title AS conversation_title,
    cs.started_at AS thread_started_at,
    cs.last_message_at,
    cs.is_archived,
    cm.message_id,
    cm.sender_role,
    cm.message_content,
    cm.message_seq,
    cm."timestamp" AS message_sent_at
FROM conversation_sessions cs
JOIN conversation_messages cm ON cs.conversation_id = cm.conversation_id
WHERE cs.conversation_id = 'conv_chat_20261119_001'
ORDER BY cm.message_seq ASC
LIMIT 50 OFFSET 0;


-- @R19
-- READ
-- Purpose: Conversational engagement metrics, user vs. assistant message counts, and active thread duration.
-- Real-world use case: Assistant conversational analytics. Measures dialogue depth, total turns,
-- thread duration, and user-to-assistant turn ratios across threads.
-- Tables: conversation_sessions, conversation_messages
SELECT
    cs.conversation_id,
    cs.title,
    cs.started_at,
    cs.last_message_at,
    ROUND(EXTRACT(EPOCH FROM (cs.last_message_at - cs.started_at))::NUMERIC, 2) AS conversation_lifespan_seconds,
    COUNT(cm.message_id) AS total_turns,
    COUNT(cm.message_id) FILTER (WHERE cm.sender_role = 'user') AS user_turn_count,
    COUNT(cm.message_id) FILTER (WHERE cm.sender_role = 'assistant') AS assistant_turn_count,
    COUNT(cm.message_id) FILTER (WHERE cm.sender_role = 'system') AS system_turn_count,
    ROUND(
        COUNT(cm.message_id) FILTER (WHERE cm.sender_role = 'user')::NUMERIC /
        NULLIF(COUNT(cm.message_id) FILTER (WHERE cm.sender_role = 'assistant'), 0), 2
    ) AS user_to_assistant_ratio
FROM conversation_sessions cs
JOIN conversation_messages cm ON cs.conversation_id = cm.conversation_id
WHERE cs.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
GROUP BY cs.conversation_id, cs.title, cs.started_at, cs.last_message_at
HAVING COUNT(cm.message_id) > 0
ORDER BY cs.last_message_at DESC;


-- @R20
-- READ
-- Purpose: Multi-domain daily intelligence digest aggregating audio, memory, agent, and task metrics via isolated CTEs.
-- Real-world use case: EchoVault daily summary digest. Prepares an executive briefing combining audio
-- minutes recorded, memories synthesized, workflows triggered, and completed tasks without row multiplication.
-- Tables: listening_sessions, transcript_chunks, refined_memories, automation_executions, task_reminders
WITH target_day AS (
    SELECT
        date_trunc('day', CURRENT_TIMESTAMP) AS day_start,
        date_trunc('day', CURRENT_TIMESTAMP) + INTERVAL '1 day' AS day_end
),
audio_daily AS (
    SELECT
        COUNT(DISTINCT ls.session_id) AS total_sessions_today,
        COALESCE(SUM(ls.duration_seconds), 0.0) AS total_recorded_seconds_today,
        COUNT(tc.chunk_id) AS total_chunks_transcribed_today
    FROM target_day td
    LEFT JOIN listening_sessions ls
      ON ls.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
     AND ls.started_at >= td.day_start
     AND ls.started_at < td.day_end
    LEFT JOIN transcript_chunks tc
      ON tc.session_id = ls.session_id
     AND tc.is_deleted = FALSE
),
memory_daily AS (
    SELECT
        COUNT(*) AS memories_created_today,
        COALESCE(ROUND(AVG(rm.importance_score)::NUMERIC, 2), 0.00) AS avg_memory_importance_today
    FROM target_day td
    JOIN refined_memories rm
      ON rm.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
     AND rm.last_updated >= td.day_start
     AND rm.last_updated < td.day_end
     AND rm.is_deleted = FALSE
),
automation_daily AS (
    SELECT
        COUNT(*) AS automations_triggered_today,
        COUNT(*) FILTER (WHERE ae.status = 'SUCCESS') AS automations_successful_today,
        COUNT(*) FILTER (WHERE ae.status = 'FAILED') AS automations_failed_today
    FROM target_day td
    JOIN automation_executions ae
      ON ae.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
     AND ae.created_at >= td.day_start
     AND ae.created_at < td.day_end
),
task_daily AS (
    SELECT
        COUNT(*) FILTER (WHERE tr.created_at >= td.day_start AND tr.created_at < td.day_end) AS tasks_created_today,
        COUNT(*) FILTER (WHERE tr.status = 'COMPLETED' AND tr.updated_at >= td.day_start AND tr.updated_at < td.day_end) AS tasks_completed_today,
        COUNT(*) FILTER (WHERE tr.status = 'PENDING') AS tasks_currently_pending
    FROM target_day td
    JOIN task_reminders tr
      ON tr.user_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
)
SELECT
    CURRENT_DATE AS report_date,
    ad.total_sessions_today,
    ROUND((ad.total_recorded_seconds_today / 60.0)::NUMERIC, 2) AS recorded_minutes_today,
    ad.total_chunks_transcribed_today,
    COALESCE(md.memories_created_today, 0) AS memories_created_today,
    COALESCE(md.avg_memory_importance_today, 0.00) AS avg_memory_importance_today,
    COALESCE(aud.automations_triggered_today, 0) AS automations_triggered_today,
    COALESCE(aud.automations_successful_today, 0) AS automations_successful_today,
    COALESCE(aud.automations_failed_today, 0) AS automations_failed_today,
    COALESCE(td.tasks_created_today, 0) AS tasks_created_today,
    COALESCE(td.tasks_completed_today, 0) AS tasks_completed_today,
    COALESCE(td.tasks_currently_pending, 0) AS tasks_currently_pending
FROM audio_daily ad
CROSS JOIN memory_daily md
CROSS JOIN automation_daily aud
CROSS JOIN task_daily td;


-- ============================================================================
-- SECTION 3: WRITE QUERIES (W01 - W08)
-- ============================================================================

-- @W01
-- WRITE
-- Purpose: Onboard or synchronize user profile and initiate an active audio listening session.
-- Real-world use case: Wearable device connects via BLE or user launches desktop listening mode.
-- Inserts user (with ON CONFLICT email handling) and establishes an active listening session.
-- Tables: users, listening_sessions
INSERT INTO users (user_id, email, full_name, created_at)
VALUES (
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'yash.gupta@echovault.local',
    'Yash Gupta',
    CURRENT_TIMESTAMP
)
ON CONFLICT (email) DO UPDATE
SET full_name = EXCLUDED.full_name;

INSERT INTO listening_sessions (
    session_id,
    user_id,
    status,
    started_at,
    ended_at,
    duration_seconds
)
VALUES (
    'sess_live_audio_20261119_002',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'listening',
    CURRENT_TIMESTAMP,
    NULL,
    0.0
);


-- @W02
-- WRITE
-- Purpose: Record a completed pause interval and transition listening session to 'stopped' with final duration.
-- Real-world use case: User stops streaming on Boyy wearable. Ingests the final pause interval
-- and updates the listening session status to 'stopped', recording final duration.
-- Tables: session_pause_intervals, listening_sessions
INSERT INTO session_pause_intervals (
    session_id,
    paused_at,
    resumed_at,
    pause_duration_seconds
)
VALUES (
    'sess_live_audio_20261119_002',
    CURRENT_TIMESTAMP - INTERVAL '15 minutes',
    CURRENT_TIMESTAMP - INTERVAL '12 minutes',
    180.0
);

UPDATE listening_sessions
SET
    status = 'stopped',
    ended_at = CURRENT_TIMESTAMP,
    duration_seconds = ROUND(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - started_at))::NUMERIC, 2)
WHERE session_id = 'sess_live_audio_20261119_002'
  AND status <> 'stopped';


-- @W03
-- WRITE
-- Purpose: Batch insert atomic transcribed utterances (omitting generated stored 'confidence' column).
-- Real-world use case: WebRTC VAD and Whisper transcription worker writes speech chunks.
-- Ingests raw confidence and timing boundaries; PostgreSQL automatically computes confidence.
-- Tables: transcript_chunks
INSERT INTO transcript_chunks (
    chunk_id,
    session_id,
    sequence_number,
    "timestamp",
    text,
    original_text,
    raw_confidence,
    speaker,
    start_time,
    end_time,
    is_deleted,
    is_reviewed,
    is_important,
    category,
    last_edited_at,
    is_final
)
VALUES
(
    'chunk_audio_20261119_010',
    'sess_live_audio_20261119_002',
    1,
    CURRENT_TIMESTAMP - INTERVAL '5 minutes',
    'Let us finalize the architecture review for Checkpoint 3 today.',
    'Let us finalize the architecture review for Checkpoint 3 today.',
    -0.12,
    'Yash',
    0.0,
    4.5,
    FALSE,
    FALSE,
    TRUE,
    'Meeting',
    NULL,
    TRUE
),
(
    'chunk_audio_20261119_011',
    'sess_live_audio_20261119_002',
    2,
    CURRENT_TIMESTAMP - INTERVAL '4 minutes 55 seconds',
    'I will also call Rahul at +919876543210 regarding the database schema.',
    'I will also call Rahul at +919876543210 regarding the database schema.',
    -0.08,
    'Yash',
    4.5,
    9.2,
    FALSE,
    FALSE,
    FALSE,
    'Action Item',
    NULL,
    TRUE
);


-- @W04
-- WRITE
-- Purpose: Persist LLM-distilled memory, map source transcript chunk provenance, and store extracted entities.
-- Real-world use case: Periodic LLM memory consolidation pipeline. Synthesizes transcript chunks
-- into a permanent knowledge node, establishing M:N chunk links and typed named entity entries.
-- Tables: refined_memories, memory_chunk_sources, memory_entities
INSERT INTO refined_memories (
    refined_id,
    user_id,
    summary,
    category,
    status,
    importance_score,
    last_updated,
    is_deleted
)
VALUES (
    'mem_refined_20261119_010',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Finalized DBMS Checkpoint 3 query architecture and discussed schema alignment with Rahul.',
    'Project',
    'active',
    0.92,
    CURRENT_TIMESTAMP,
    FALSE
);

INSERT INTO memory_chunk_sources (refined_id, chunk_id, association_score)
VALUES
    ('mem_refined_20261119_010', 'chunk_audio_20261119_010', 0.95),
    ('mem_refined_20261119_010', 'chunk_audio_20261119_011', 0.88);

INSERT INTO memory_entities (refined_id, entity_type, entity_value)
VALUES
    ('mem_refined_20261119_010', 'Project', 'EchoVault Checkpoint 3'),
    ('mem_refined_20261119_010', 'Person', 'Rahul'),
    ('mem_refined_20261119_010', 'Topic', 'DBMS Normalization & Queries');


-- @W05
-- WRITE
-- Purpose: Instantiate an automation workflow with multiple planned action nodes and dependency edges.
-- Real-world use case: AgentEngine multi-action planner receives a composite user command.
-- Decomposes command into an execution DAG with JSONB payloads and inter-action dependencies.
-- Tables: automation_executions, planned_actions, action_dependencies
INSERT INTO automation_executions (
    execution_id,
    session_id,
    user_id,
    command_text,
    detected_intent,
    status,
    error_message,
    created_at,
    updated_at
)
VALUES (
    'exec_auto_plan_20261119_010',
    'sess_live_audio_20261119_002',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Schedule sync meeting with Rahul and set a reminder to review schema',
    'SCHEDULE_AND_REMIND',
    'CONFIRMED',
    NULL,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

INSERT INTO planned_actions (
    action_id,
    execution_id,
    tool_name,
    action_verb,
    parameters_payload,
    status,
    result_payload,
    error_message,
    sequence_order,
    executed_at
)
VALUES
(
    'act_plan_20261119_010',
    'exec_auto_plan_20261119_010',
    'CalendarTool',
    'create_event',
    '{"title": "Sync with Rahul on DBMS Schema", "duration_minutes": 30, "attendees": ["rahul@echovault.local"]}'::jsonb,
    'pending',
    NULL,
    NULL,
    1,
    NULL
),
(
    'act_plan_20261119_011',
    'exec_auto_plan_20261119_010',
    'ReminderTool',
    'create_reminder',
    '{"title": "Prepare query plans before meeting", "priority": "HIGH", "due_in_hours": 2}'::jsonb,
    'pending',
    NULL,
    NULL,
    2,
    NULL
);

INSERT INTO action_dependencies (
    execution_id,
    action_id,
    depends_on_action_id
)
VALUES (
    'exec_auto_plan_20261119_010',
    'act_plan_20261119_011',
    'act_plan_20261119_010'
);


-- @W06
-- WRITE
-- Purpose: Complete planned action execution with JSONB result and register external calendar synchronization.
-- Real-world use case: Tool execution worker completes Google Calendar event creation.
-- Updates action status to 'success' and records external calendar sync receipt.
-- Tables: planned_actions, calendar_event_sync
UPDATE planned_actions
SET
    status = 'success',
    result_payload = '{"event_id": "google_cal_ev_84920499", "status": "confirmed", "html_link": "https://calendar.google.com/event?id=84920499"}'::jsonb,
    executed_at = CURRENT_TIMESTAMP
WHERE execution_id = 'exec_auto_plan_20261119_010'
  AND action_id = 'act_plan_20261119_010';

INSERT INTO calendar_event_sync (
    sync_id,
    action_id,
    chunk_id,
    external_event_id,
    event_summary,
    start_time,
    end_time,
    sync_status,
    error_message,
    created_at,
    updated_at
)
VALUES (
    'sync_cal_20261119_010',
    'act_plan_20261119_010',
    'chunk_audio_20261119_010',
    'google_cal_ev_84920499',
    'Sync with Rahul on DBMS Schema',
    CURRENT_TIMESTAMP + INTERVAL '1 day',
    CURRENT_TIMESTAMP + INTERVAL '1 day 30 minutes',
    'SUCCESS',
    NULL,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);


-- @W07
-- WRITE
-- Purpose: Ingest spoken phone number candidate and create linked high-priority verification task reminder.
-- Real-world use case: Ambient speech mentions an unknown phone number. Ingests pending contact
-- candidate and immediately spawns a proactive reminder for user identity confirmation.
-- Tables: task_reminders, pending_contacts
INSERT INTO task_reminders (
    reminder_id,
    user_id,
    title,
    description,
    scheduled_for,
    due_date,
    status,
    category,
    priority,
    source,
    external_reference,
    created_at,
    updated_at
)
VALUES (
    'rem_task_20261119_010',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Confirm identity and save contact for Rahul (+919876543211)',
    'Spoken in audio session regarding DBMS schema alignment.',
    CURRENT_TIMESTAMP + INTERVAL '4 hours',
    CURRENT_TIMESTAMP + INTERVAL '24 hours',
    'PENDING',
    'Contact Verification',
    'HIGH',
    'agent',
    NULL,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

INSERT INTO pending_contacts (
    pending_id,
    user_id,
    phone,
    name,
    status,
    confidence,
    context,
    source,
    reminder_id,
    google_resource_name,
    captured_at,
    resolved_at,
    updated_at
)
VALUES (
    'pend_contact_20261119_010',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    '+919876543211',
    'Rahul',
    'pending_name',
    'MEDIUM',
    'Spoken during listening session: "I will also call Rahul at +919876543211 regarding the database schema."',
    'explicit_statement',
    'rem_task_20261119_010',
    NULL,
    CURRENT_TIMESTAMP,
    NULL,
    CURRENT_TIMESTAMP
);


-- @W08
-- WRITE
-- Purpose: Append conversation message with row-level transaction lock on session to prevent sequence collisions.
-- Real-world use case: User sends chat turn. Acquires FOR UPDATE lock on parent session row to prevent
-- race conditions, computes next sequence number monotonically, and updates thread last_message_at.
-- Tables: conversation_sessions, conversation_messages

-- Step 1: Ensure parent conversation session exists
INSERT INTO conversation_sessions (
    conversation_id,
    user_id,
    title,
    started_at,
    last_message_at,
    is_archived
)
VALUES (
    'conv_chat_20261119_002',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Interactive Schema Discussion',
    CURRENT_TIMESTAMP - INTERVAL '30 minutes',
    CURRENT_TIMESTAMP - INTERVAL '5 minutes',
    FALSE
)
ON CONFLICT (conversation_id) DO NOTHING;

-- Step 2: Lock parent conversation session to serialize concurrent message appends
SELECT conversation_id
FROM conversation_sessions
WHERE conversation_id = 'conv_chat_20261119_002'
FOR UPDATE;

-- Step 3: Insert next sequential message avoiding sequence collision
INSERT INTO conversation_messages (
    message_id,
    conversation_id,
    sender_role,
    message_content,
    message_seq,
    "timestamp"
)
SELECT
    'msg_turn_20261119_010',
    'conv_chat_20261119_002',
    'user',
    'Can you verify if all actions in the meeting plan have been scheduled?',
    COALESCE(MAX(cm.message_seq), 0) + 1,
    CURRENT_TIMESTAMP
FROM conversation_messages cm
WHERE cm.conversation_id = 'conv_chat_20261119_002';

-- Step 4: Touch parent session timestamp
UPDATE conversation_sessions
SET last_message_at = CURRENT_TIMESTAMP
WHERE conversation_id = 'conv_chat_20261119_002';


-- ============================================================================
-- TRANSACTION ROLLBACK
-- Guarantees clean, non-mutating execution during automated testing and benchmarking.
-- ============================================================================
ROLLBACK;
