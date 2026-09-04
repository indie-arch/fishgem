# Fishgem Agent Instructions

## Project

Fishgem is a small single-player 2D fishing/social game inspired by the steam game "WEBFISHING".

The goal is a cozy, slightly silly game with fishing, exploration, collecting, and purchasing upgrades. The player should feel like they are in a small, charming world with a lot of personality.

Keep the scope small. This is a small solo project, not an MMO and not a live-service game.

## Engine

- Godot 4
- GDScript
- 2D
- Forward+ renderer
- Desktop Linux is the primary development platform

## Development Philosophy

Prefer simple, understandable implementations over elaborate architecture.

Do not introduce:
- dependency injection frameworks
- complicated event buses
- unnecessary abstraction layers
- premature optimisation
- large inheritance hierarchies

If something can reasonably be implemented in ~30 lines of straightforward
GDScript, don't turn it into five classes.

Reusable systems are good, but only abstract things after there is an actual
reason to reuse them.

## Code Style

- Use descriptive names.
- Keep functions fairly small.
- Prefer composition over deep inheritance.
- Use Godot signals for communication between loosely coupled nodes.
- Avoid huge autoload/singleton classes.
- Comment WHY something exists, not what obvious code does.
- for complex code, please explain it with a comment if it isnt obvious.
- prioritise readability over cleverness.
- use snake_case for variables and functions and PascalCase for classes or functions.

## Game Feel

Game feel matters more than architectural purity.

Interactions should feel:
- responsive
- cozy
- playful
- slightly goofy
- simple

Prefer small animations, sound cues, particles, squash/stretch, and other
feedback where appropriate rather than purely functional interactions.

Do not make the UI look like generic software or a mobile app.

## Art / UX Taste

Keep things charming and handmade rather than sleek/corporate.

Avoid:
- excessive gradients
- glassmorphism
- generic rounded SaaS-style panels
- overly polished futuristic UI

Prefer:
- simple shapes
- chunky readable UI
- expressive animation
- slightly imperfect / playful presentation

## Scope

Before adding a substantial new system, consider whether it actually helps the
core loop:

    explore -> fish -> fishing minigame -> sell/use -> upgrade -> repeat

Prefer finishing a small version of a feature before expanding it.

Do not add multiplayer unless explicitly requested.

## Working With Me

Treat development as a collaboration rather than independently deciding every
detail.

### Notion Context Check

Before planning, changing, or implementing any game system, use the Notion MCP
to search my Notion workspace for information about that system. Search using
the system name and relevant Fishgem terms, then fetch and read any relevant
pages before continuing. Treat that material as project context alongside the
repository and these instructions.

If the search finds no relevant information, continue using the repository and
these instructions. If the Notion MCP is unavailable, disconnected, or returns
an authentication or access error, tell me before working on the system so I
can restore access or decide how to proceed. Do not create or modify Notion
content unless I explicitly ask you to.

Ask me questions when:
- a gameplay decision could reasonably go several ways
- the visual or UX direction is subjective
- a task would significantly affect project structure
- requirements are unclear or underspecified
- you are unsure what behaviour I would prefer
- there is a meaningful tradeoff between multiple approaches

Do not guess at important design decisions just to keep moving.

For small implementation details with an obvious answer, use your judgement and
continue without interrupting me unnecessarily.

When useful, present me with 2-3 concrete options and briefly explain the
tradeoffs instead of asking an overly broad question.

If a task is large, work with me to break it into sensible pieces and confirm
the direction as the feature takes shape.

I want to stay involved in the creative and technical direction of Fishgem.
The agent should help me build the game, not disappear into the project and
return with a bunch of decisions I never made.

When implementing something:

1. Inspect the existing project first.
2. Understand the relevant scenes, scripts, and existing conventions.
3. Ask questions before making important subjective or architectural decisions.
4. Follow existing conventions where reasonable.
5. Make the smallest coherent change that solves the problem.
6. Run/test the project when possible.
7. Fix errors you introduce.
8. Tell me about meaningful design decisions, but don't over-explain routine code.

If there are several reasonable approaches, prefer the simplest one unless
there is a strong reason not to. If the choice affects how the game feels or
how future systems will be built, ask me first.
