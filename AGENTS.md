# Codex Development Guidelines

## Context
This is a Ruby on Rails application.

All development MUST follow the definitions in `stack.md`.

---

## Mandatory Rules

- ALWAYS read and follow `stack.md` before making changes
- Do NOT introduce new gems outside of `stack.md`
- Do NOT change the tech stack without explicit instruction
- Prefer built-in Rails features over external libraries

---

## Architecture Rules

- Follow RESTful Rails conventions
- Keep controllers thin
- Do NOT place business logic inside controllers or views
- Use service objects for complex business logic
- Avoid fat models and fat controllers

---

## Background Jobs

- Use delayed_job only
- Do NOT use Sidekiq or other background job systems
- Only introduce jobs when necessary

---

## Code Consistency

- Follow existing patterns in the codebase
- Reuse existing structures before creating new ones
- Do NOT introduce multiple patterns for the same problem

---

## APIs

- Use Jbuilder only
- Do NOT introduce other serializers

---

## Testing

- Use RSpec for tests
- Use FactoryBot for test data

---

## Behavior Instructions

Before writing code:
1. Read `stack.md`
2. Check existing implementation patterns
3. Follow consistency with the project

If a request conflicts with `stack.md`:
→ Ask for clarification instead of implementing

If unsure:
→ Choose the simplest solution that follows Rails conventions

## CI Rules

- All code MUST pass:
  - RuboCop
  - Brakeman
  - bundler-audit
  - RSpec

- If any check fails:
  → Fix the issue instead of bypassing it