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

ActiveRecord::Schema[8.1].define(version: 2026_02_01_100159) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ai_chat_messages", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "plan_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["plan_id", "created_at"], name: "index_ai_chat_messages_on_plan_id_and_created_at"
    t.index ["plan_id"], name: "index_ai_chat_messages_on_plan_id"
    t.index ["user_id"], name: "index_ai_chat_messages_on_user_id"
  end

  create_table "favorite_plans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "plan_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["plan_id"], name: "index_favorite_plans_on_plan_id"
    t.index ["user_id", "plan_id"], name: "index_favorite_plans_on_user_id_and_plan_id", unique: true
    t.index ["user_id"], name: "index_favorite_plans_on_user_id"
  end

  create_table "favorite_spots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "spot_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["spot_id"], name: "index_favorite_spots_on_spot_id"
    t.index ["user_id", "spot_id"], name: "index_favorite_spots_on_user_id_and_spot_id", unique: true
    t.index ["user_id"], name: "index_favorite_spots_on_user_id"
  end

  create_table "genres", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "parent_id"
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.index ["parent_id"], name: "index_genres_on_parent_id"
    t.index ["position"], name: "index_genres_on_position"
    t.index ["slug"], name: "index_genres_on_slug", unique: true
  end

  create_table "goal_points", force: :cascade do |t|
    t.string "address"
    t.time "arrival_time"
    t.datetime "created_at", null: false
    t.float "lat"
    t.float "lng"
    t.bigint "plan_id", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id"], name: "index_goal_points_on_plan_id"
  end

  create_table "identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "plan_spots", force: :cascade do |t|
    t.time "arrival_time"
    t.datetime "created_at", null: false
    t.time "departure_time"
    t.text "memo"
    t.integer "move_cost", default: 0, null: false
    t.float "move_distance", default: 0.0, null: false
    t.integer "move_time", default: 0, null: false
    t.bigint "plan_id", null: false
    t.text "polyline"
    t.integer "position", null: false
    t.bigint "spot_id", null: false
    t.integer "stay_duration"
    t.boolean "toll_used", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id", "position"], name: "index_plan_spots_on_plan_id_and_position"
    t.index ["plan_id", "spot_id"], name: "index_plan_spots_on_plan_id_and_spot_id", unique: true
    t.index ["plan_id"], name: "index_plan_spots_on_plan_id"
    t.index ["spot_id"], name: "index_plan_spots_on_spot_id"
  end

  create_table "plans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title"
    t.integer "total_cost", default: 0, null: false
    t.float "total_distance", default: 0.0, null: false
    t.integer "total_time", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["title"], name: "index_plans_on_title"
    t.index ["updated_at"], name: "index_plans_on_updated_at"
    t.index ["user_id"], name: "index_plans_on_user_id"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "spot_comments", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "spot_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["spot_id"], name: "index_spot_comments_on_spot_id"
    t.index ["user_id"], name: "index_spot_comments_on_user_id"
  end

  create_table "spot_genres", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "genre_id", null: false
    t.bigint "spot_id", null: false
    t.datetime "updated_at", null: false
    t.index ["genre_id"], name: "index_spot_genres_on_genre_id"
    t.index ["spot_id", "genre_id"], name: "index_spot_genres_on_spot_id_and_genre_id", unique: true
    t.index ["spot_id"], name: "index_spot_genres_on_spot_id"
  end

  create_table "spots", force: :cascade do |t|
    t.string "address", null: false
    t.string "city"
    t.datetime "created_at", null: false
    t.float "lat", null: false
    t.float "lng", null: false
    t.string "name", null: false
    t.string "place_id", null: false
    t.string "prefecture"
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_spots_on_city"
    t.index ["place_id"], name: "index_spots_on_place_id", unique: true
    t.index ["prefecture"], name: "index_spots_on_prefecture"
  end

  create_table "start_points", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.datetime "created_at", null: false
    t.time "departure_time"
    t.float "lat"
    t.float "lng"
    t.integer "move_cost"
    t.float "move_distance"
    t.integer "move_time"
    t.bigint "plan_id", null: false
    t.text "polyline"
    t.string "prefecture"
    t.boolean "toll_used", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_start_points_on_city"
    t.index ["plan_id"], name: "index_start_points_on_plan_id"
    t.index ["prefecture"], name: "index_start_points_on_prefecture"
  end

  create_table "users", force: :cascade do |t|
    t.integer "age_group"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: ""
    t.string "encrypted_password", default: "", null: false
    t.integer "gender", default: 0
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "residence"
    t.integer "status", default: 0, null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["status"], name: "index_users_on_status"
  end

  add_foreign_key "ai_chat_messages", "plans"
  add_foreign_key "ai_chat_messages", "users"
  add_foreign_key "favorite_plans", "plans"
  add_foreign_key "favorite_plans", "users"
  add_foreign_key "favorite_spots", "spots"
  add_foreign_key "favorite_spots", "users"
  add_foreign_key "genres", "genres", column: "parent_id"
  add_foreign_key "goal_points", "plans"
  add_foreign_key "identities", "users"
  add_foreign_key "plan_spots", "plans"
  add_foreign_key "plan_spots", "spots"
  add_foreign_key "plans", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "spot_comments", "spots"
  add_foreign_key "spot_comments", "users"
  add_foreign_key "spot_genres", "genres"
  add_foreign_key "spot_genres", "spots"
  add_foreign_key "start_points", "plans"
end
