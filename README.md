# Practice BR

[![CI](https://github.com/DaisyOli/portuguese_exercises/actions/workflows/ci.yml/badge.svg)](https://github.com/DaisyOli/portuguese_exercises/actions/workflows/ci.yml)

An AI-powered platform where Portuguese language teachers create interactive exercises and students practice with instant, personalized feedback.

Live in private beta at [app.practicebr.com](https://app.practicebr.com), with real teachers and students testing it. Built and shipped solo — from first commit to production on Heroku — as my first Rails project after the Le Wagon bootcamp, and evolved well beyond it since.

---

## What it does

**For teachers:**
- Create activities in minutes — or let AI do the heavy lifting:
  - **Generate a full activity from a text prompt** (statement, explanation and questions), powered by Claude
  - **Generate an activity from a YouTube video**: the transcript is fetched and turned into comprehension questions
- Six exercise types: multiple choice, fill-in-the-blank, open-ended, sentence ordering, paragraph ordering and column matching
- Review AI-generated drafts before publishing
- Invite students by email — each student is scoped to their teacher
- Dashboard with per-level (CEFR A1–C1) and per-competency breakdowns, pending corrections and student activity

**For students:**
- Practice activities filtered by level and competency — listening (CO), reading (CE) and writing (EE)
- Instant scoring with per-question feedback
- **Open-ended answers graded by AI**, with constructive feedback written in Portuguese
- **Answer by voice**: audio recordings are transcribed with Whisper
- Progress dashboard with competency tracking, search and activity ratings
- Installable as a PWA, with web push notifications for new activities

**Under the hood:**
- Trial-to-subscription onboarding with Stripe (checkout + webhooks)
- Weekly reminder emails (Resend + Heroku Scheduler) and daily YouTube video suggestions per teacher
- Interface localized in Portuguese, English and French

---

## Tech stack

| Layer | Technology |
|-------|-----------|
| Backend | Ruby 3.3.5, Rails 7.1 |
| Database | PostgreSQL |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS + DaisyUI |
| AI | Anthropic Claude (activity generation, grading), OpenAI Whisper (speech-to-text) |
| Auth | Devise + Devise Invitable |
| Payments | Stripe subscriptions + webhooks |
| Media & email | Cloudinary, Unsplash, YouTube Data API, Resend |
| Tests & CI | RSpec, FactoryBot, SimpleCov, GitHub Actions |
| Deploy | Heroku (with PWA + web push in production) |

---

## Architecture notes

- **Service objects** keep controllers thin: quiz submission and AI grading, activity generation (prompt- and video-based), transcription, push notifications and analytics each live in their own service under `app/services`.
- **Server-rendered UI with Hotwire** — no SPA, no API layer to maintain; Turbo handles interactivity.
- **Role-based access** (admin / teacher / student / trial) enforced at controller level, with students scoped to the teacher who invited them.
- **Graceful degradation**: AI, YouTube and Unsplash integrations are optional — the platform works without their API keys.

## Technical roadmap

Things I know need work, in priority order:

- [ ] Move AI grading calls out of the request cycle into background jobs
- [ ] Finish migrating the remaining Bootstrap views to Tailwind/DaisyUI and remove inline styles
- [ ] Raise request-spec coverage on the billing and quiz-submission flows
- [ ] Consolidate the repetitive `clear_*` controller actions into a single parameterized action

---

## Running locally

**Prerequisites:** Ruby 3.3.5, PostgreSQL, Bundler

```bash
git clone https://github.com/DaisyOli/portuguese_exercises.git
cd portuguese_exercises

bundle install

# Set up the database
bin/rails db:create db:migrate db:seed

# Start the server + Tailwind watcher
bin/dev
```

Open `http://localhost:3000` in your browser.

**Environment variables** — create a `.env` file at the project root:

```
DB_USERNAME=your_postgres_username
DB_PASSWORD=your_postgres_password
```

Optional keys unlock the integrations: `ANTHROPIC_API_KEY` (AI generation and grading), `OPENAI_API_KEY` (voice answers), `STRIPE_SECRET_KEY`, `YOUTUBE_API_KEY`, `UNSPLASH_ACCESS_KEY`.

## Running tests

```bash
bundle exec rspec
```

The suite also runs on every push via GitHub Actions.
