# EchoVault — Your Personal Agentic AI Assistant

## Overview

**EchoVault is an agentic AI assistant designed to connect conversational intelligence, persistent memory, research, and real-world task execution into a unified system.**

Unlike traditional chatbots that primarily respond to individual prompts, EchoVault aims to understand context, retain useful information, retrieve relevant knowledge, plan actions, select tools, and execute multi-step workflows.

The long-term vision is to build a personal AI companion that can assist users across conversations, applications, tasks, and eventually wearable devices.

## Core Capabilities

- **Agentic AI Engine:** Coordinates task planning, tool selection, and action execution.
- **Multi-Step Action Execution:** Supports workflows involving multiple commands and actions through a structured agent architecture.
- **Conversational Context:** Maintains conversation context across multiple turns.
- **Persistent Memory:** Uses a memory-oriented architecture to support storing and retrieving useful information.
- **Research and Knowledge Retrieval:** Provides a foundation for gathering external information to support reasoning.
- **Task and Reminder Management:** Integrates assistant workflows with reminders and task-related operations.
- **Calendar Integration:** Connects with Google Calendar to support calendar-related functionality.
- **Automation:** Aims to reduce repetitive manual work by connecting reasoning with executable actions.
- **Wearable AI:** Extends the EchoVault vision toward voice-first interactions through the Boyy wearable project.

These capabilities represent the project's development direction; individual features may have different implementation and verification statuses.

## Agentic AI Architecture

EchoVault is built around an `AgentEngine` architecture that coordinates actions rather than relying exclusively on simple text generation.

The conceptual execution flow is:

1. Receive a user request.
2. Process the relevant conversational context.
3. Determine the actions needed to fulfill the request.
4. Select appropriate tools.
5. Execute actions and process their results.
6. Continue with additional actions when required.
7. Return the final response.

Structured action models and state-machine-based execution help organize complex workflows and make execution easier to understand and debug.

## Technology Stack

The documented technology ecosystem includes:

- **Backend:** Python, FastAPI
- **AI and Language Models:** Gemini integrations
- **Data and Retrieval:** SQLAlchemy and FAISS
- **Application Interfaces:** Next.js, React, TypeScript, and Electron components where applicable
- **Wearable Hardware:** Seeed Studio XIAO ESP32S3 Sense
- **Communication:** Bluetooth Low Energy (BLE)
- **Integrations:** Google Calendar API and research-related tools

The exact technologies used by each subsystem depend on its current implementation.

## EchoVault Wearable — Boyy

EchoVault's wearable direction builds on the existing Boyy project, which uses the XIAO ESP32S3 Sense development board.

The intended architecture connects:

**Microphone → Audio Capture → Speech Segmentation → BLE → Phone/Client → EchoVault Backend → AI Processing → Memory and Actions**

The wearable aims to support natural voice interaction without requiring users to interact with a conventional screen for every request.

Key engineering priorities include reliable audio capture, low-latency speech segmentation, BLE communication, efficient buffering, battery optimization, and privacy-conscious audio handling.

Continuous listening and autonomous speech segmentation are important development goals, and their implementation status must not be assumed.

## Project Vision

EchoVault aims to evolve from a conversational assistant into a context-aware personal AI system that can connect what users say, what the system remembers, what it learns through research, and what it can accomplish through tools.

The long-term goal is to make AI assistance more continuous, useful, and action-oriented.

## Development Philosophy

- Build on existing, verified components wherever practical.
- Keep planning, tool execution, memory, and integrations logically organized.
- Prefer structured action representations over fragile command parsing.
- Treat security, privacy, reliability, and observability as essential engineering concerns.
- Distinguish implemented features from planned capabilities.
- Develop the wearable incrementally, prioritizing reliable audio capture and communication.

## Status

EchoVault is an evolving project spanning agentic AI, memory, automation, application integration, and wearable computing. Its capabilities continue to develop as individual components are integrated and validated.
