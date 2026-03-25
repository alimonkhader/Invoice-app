# Tech Stack

## Backend
- Ruby on Rails 8.0.4
- Ruby 3.4.5

## Database
- PostgreSQL

## Background Jobs (if needed)
- delayed_job
- Redis (only if required by jobs)

## Authentication
- Devise

## Authorization
- Pundit

## Frontend
- Hotwire (Turbo + Stimulus)

## File Storage (if needed)
- Active Storage

## API (if needed)
- Jbuilder

## Testing
- RSpec
- FactoryBot

## Code Quality
- RuboCop
- Brakeman

## Deployment
- Render / Railway / Heroku

---

# Rules

## General
- Do NOT introduce new gems without approval
- Prefer built-in Rails features over external libraries
- Follow Rails conventions (RESTful structure)

## Background Jobs
- Use delayed_job only (do NOT use Sidekiq or other job systems)
- Jobs should be used only when necessary

## Architecture
- Keep business logic out of controllers
- Use service objects for complex logic
- Avoid fat models and fat controllers

## Database
- Use PostgreSQL-specific features only if necessary
- Always add indexes for performance-critical queries

## APIs
- Use Jbuilder consistently
- Do not mix multiple API serializers

## Testing
- Write tests using RSpec only
- Use FactoryBot for test data