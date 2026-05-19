# Practice PT

A web platform for Portuguese language teachers to create interactive exercises and for students to practice and receive instant feedback.

Built as a first Rails project after a Le Wagon bootcamp.

---

## Features

**For teachers:**
- Create activities with multiple question types (multiple choice, fill in the blank)
- Add supporting content to each activity: written statement, explanatory text, image or YouTube video
- Edit or delete questions inline, without leaving the page
- Invite students by email — they receive a link to set their own password
- View which students have completed each activity

**For students:**
- Browse available activities assigned by their teacher
- Submit answers and receive an instant score with per-question feedback
- Track completed activities in their dashboard

---

## Tech stack

| Layer | Technology |
|-------|-----------|
| Backend | Ruby 3.3.5, Rails 7.1 |
| Database | PostgreSQL |
| Frontend | Hotwire (Turbo + Stimulus), Bootstrap 5 |
| Auth | Devise + Devise Invitable |
| Forms | Simple Form |
| Tests | RSpec, FactoryBot |

---

## Running locally

**Prerequisites:** Ruby 3.3.5, PostgreSQL, Bundler, Yarn

```bash
# Clone the repo
git clone <repo-url>
cd exercise_app

# Install dependencies
bundle install
yarn install

# Set up the database
bin/rails db:create db:migrate db:seed

# Start the server
bin/rails server
```

Open `http://localhost:3000` in your browser.

**Environment variables** — create a `.env` file at the project root:

```
DB_USERNAME=your_postgres_username
DB_PASSWORD=your_postgres_password
```

---

## Exercise types

| Type | How it works |
|------|-------------|
| Multiple choice | Student selects one option from a list. The correct answer is highlighted on submission. |
| Fill in the blank | Question content contains `_____` as a placeholder. Student types the answer directly. |

---

## Inviting students

1. Sign in as a teacher
2. Go to your dashboard and click **Convidar aluno**
3. Enter the student's email address
4. The student receives an email with a link to set their password and access the platform

Students are scoped to the teacher who invited them and can only see that teacher's activities.

---

## Running tests

```bash
bundle exec rspec
```
