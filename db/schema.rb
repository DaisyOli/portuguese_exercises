# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_07_07_111310) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "level"
    t.bigint "teacher_id"
    t.string "media_url"
    t.text "explanation_text"
    t.text "statement"
    t.string "slug"
    t.string "video_url"
    t.boolean "draft", default: false, null: false
    t.boolean "ai_generated"
    t.datetime "published_at"
    t.boolean "explanation_is_transcript"
    t.string "unsplash_cover_url"
    t.string "unsplash_cover_credit"
    t.index ["slug"], name: "index_activities_on_slug"
    t.index ["teacher_id"], name: "index_activities_on_teacher_id"
  end

  create_table "activity_ratings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "activity_id", null: false
    t.integer "stars", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_activity_ratings_on_activity_id"
    t.index ["user_id", "activity_id"], name: "index_activity_ratings_on_user_id_and_activity_id", unique: true
    t.index ["user_id"], name: "index_activity_ratings_on_user_id"
    t.check_constraint "stars >= 1 AND stars <= 5", name: "stars_range_check"
  end

  create_table "column_matchings", force: :cascade do |t|
    t.bigint "activity_id", null: false
    t.string "title"
    t.string "instruction"
    t.integer "display_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_column_matchings_on_activity_id"
  end

  create_table "matching_pairs", force: :cascade do |t|
    t.bigint "column_matching_id", null: false
    t.string "left_item"
    t.string "right_item"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["column_matching_id"], name: "index_matching_pairs_on_column_matching_id"
  end

  create_table "paragraph_orderings", force: :cascade do |t|
    t.bigint "activity_id", null: false
    t.string "title"
    t.text "instruction"
    t.integer "display_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "paragraph_sentences_count"
    t.index ["activity_id"], name: "index_paragraph_orderings_on_activity_id"
  end

  create_table "paragraph_sentences", force: :cascade do |t|
    t.bigint "paragraph_ordering_id", null: false
    t.text "sentence", null: false
    t.integer "correct_position", null: false
    t.integer "display_position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["paragraph_ordering_id", "correct_position"], name: "index_paragraph_sentences_on_ordering_and_position", unique: true
    t.index ["paragraph_ordering_id"], name: "index_paragraph_sentences_on_paragraph_ordering_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "endpoint", null: false
    t.string "p256dh_key", null: false
    t.string "auth_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "endpoint"], name: "index_push_subscriptions_on_user_id_and_endpoint", unique: true
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "questions", force: :cascade do |t|
    t.string "content"
    t.string "question_type"
    t.bigint "activity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "options"
    t.string "correct_answer"
    t.text "evaluation_prompt"
    t.integer "weight", default: 1, null: false
    t.jsonb "correct_answers", default: []
    t.index ["activity_id"], name: "index_questions_on_activity_id"
  end

  create_table "quiz_attempts", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "activity_id", null: false
    t.float "score"
    t.jsonb "results"
    t.datetime "submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "teacher_comments"
    t.datetime "started_at"
    t.index ["activity_id"], name: "index_quiz_attempts_on_activity_id"
    t.index ["user_id"], name: "index_quiz_attempts_on_user_id"
  end

  create_table "sentence_orderings", force: :cascade do |t|
    t.bigint "activity_id", null: false
    t.text "sentence"
    t.text "instruction"
    t.integer "display_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sentence_words_count"
    t.index ["activity_id"], name: "index_sentence_orderings_on_activity_id"
  end

  create_table "sentence_words", force: :cascade do |t|
    t.bigint "sentence_ordering_id", null: false
    t.string "word"
    t.integer "correct_position"
    t.integer "display_position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sentence_ordering_id"], name: "index_sentence_words_on_sentence_ordering_id"
  end

  create_table "suggestions", force: :cascade do |t|
    t.text "content"
    t.integer "position"
    t.bigint "activity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_suggestions_on_activity_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "trial"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "language", default: "en"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.boolean "admin"
    t.string "name"
    t.string "level"
    t.integer "trial_activities_used"
    t.datetime "trial_expires_at"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "subscription_status"
    t.datetime "subscription_current_period_end"
    t.string "professional_type"
    t.boolean "weekly_reminder_email"
    t.integer "daily_quiz_count", default: 0, null: false
    t.date "daily_quiz_date"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["language"], name: "index_users_on_language"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "video_suggestions", force: :cascade do |t|
    t.string "youtube_url"
    t.string "title"
    t.string "thumbnail_url"
    t.string "channel_name"
    t.string "topic"
    t.string "level_hint"
    t.string "status", default: "pending", null: false
    t.text "transcript"
    t.integer "activity_id"
    t.integer "teacher_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "search_query"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "users", column: "teacher_id"
  add_foreign_key "activity_ratings", "activities"
  add_foreign_key "activity_ratings", "users"
  add_foreign_key "column_matchings", "activities"
  add_foreign_key "matching_pairs", "column_matchings"
  add_foreign_key "paragraph_orderings", "activities"
  add_foreign_key "paragraph_sentences", "paragraph_orderings"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "questions", "activities"
  add_foreign_key "quiz_attempts", "activities"
  add_foreign_key "quiz_attempts", "users"
  add_foreign_key "sentence_orderings", "activities"
  add_foreign_key "sentence_words", "sentence_orderings"
  add_foreign_key "suggestions", "activities"
end
