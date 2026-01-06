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

ActiveRecord::Schema[8.1].define(version: 2026_01_06_073155) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "genres", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
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

  create_table "like_plans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "plan_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["plan_id"], name: "index_like_plans_on_plan_id"
    t.index ["user_id", "plan_id"], name: "index_like_plans_on_user_id_and_plan_id", unique: true
    t.index ["user_id"], name: "index_like_plans_on_user_id"
  end

  create_table "like_spots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "spot_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["spot_id"], name: "index_like_spots_on_spot_id"
    t.index ["user_id", "spot_id"], name: "index_like_spots_on_user_id_and_spot_id", unique: true
    t.index ["user_id"], name: "index_like_spots_on_user_id"
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
    t.index ["user_id"], name: "index_plans_on_user_id"
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
    t.string "photo_reference"
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

  create_table "user_spots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "spot_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["spot_id"], name: "index_user_spots_on_spot_id"
    t.index ["user_id", "spot_id"], name: "index_user_spots_on_user_id_and_spot_id", unique: true
    t.index ["user_id"], name: "index_user_spots_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "status", default: 0, null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "goal_points", "plans"
  add_foreign_key "like_plans", "plans"
  add_foreign_key "like_plans", "users"
  add_foreign_key "like_spots", "spots"
  add_foreign_key "like_spots", "users"
  add_foreign_key "plan_spots", "plans"
  add_foreign_key "plan_spots", "spots"
  add_foreign_key "plans", "users"
  add_foreign_key "spot_genres", "genres"
  add_foreign_key "spot_genres", "spots"
  add_foreign_key "start_points", "plans"
  add_foreign_key "user_spots", "spots"
  add_foreign_key "user_spots", "users"
end
