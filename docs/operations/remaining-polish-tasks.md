# Remaining Polish & Feature Tasks

> **Status:** Pending Implementation
> **Last Updated:** 2026-02-25

This document tracks the remaining feature requests and polish items identified during the February 2026 sprint.

## Player App Features

- [x] **Strategy Guides in Game Screen:**
  - Incorporate role-specific strategy guides (Dos and Don'ts) into the "I'm playing as..." widget.
  - Display context-aware tips based on current game state (e.g., betrayal advice, deception tactics).

- [x] **Operatives Page Strategy Tab:**
  - Enhance the strategy dialog/tab with "What Ifs" and "How to Play" hints.
  - Integrate an **Alliance Graph** linking valuable roles (e.g., Ally Cat <-> Bouncer).

## UI Polish (Host & Player)

- [x] **Side Drawer Refactor:**
  - Update side drawers in both apps to a modern "Glassmorphism + Material 3" aesthetic.
  - Improve visual polish and consistency.

- [x] **Guide/Blackbook Screen Centering:**
  - Verify and polish the centering of full role cards sliding in from the side (ensure visual balance on mobile).

## Backend / AI

- [x] **Gemini Narrative Runtime Implementation:**
  - Connect the configured API key and `ScriptStep` fields to the actual generative logic.
  - Implement runtime script variation generation based on game state (sarcastic, ironic, dark humor modes).
  - Add "Clean" vs "R-Rated" narration toggle.
