# frozen_string_literal: true

class CreateInitialSchema < ActiveRecord::Migration[8.1]
  def change
    # ==========================================
    # Users
    # ==========================================
    create_table :users do |t|
      t.integer :age_group
      t.datetime :confirmation_sent_at
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.string :email, default: ""
      t.string :encrypted_password, default: "", null: false
      t.integer :gender, default: 0
      t.datetime :remember_created_at
      t.datetime :reset_password_sent_at
      t.string :reset_password_token
      t.string :residence
      t.integer :status, default: 0, null: false
      t.string :unconfirmed_email
      t.timestamps
    end
    add_index :users, :confirmation_token, unique: true
    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :status

    # ==========================================
    # Identities (OAuth)
    # ==========================================
    create_table :identities do |t|
      t.string :provider, null: false
      t.string :uid, null: false
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :identities, [ :provider, :uid ], unique: true

    # ==========================================
    # Genres
    # ==========================================
    create_table :genres do |t|
      t.string :category
      t.string :emoji, default: "✨"
      t.string :name, null: false
      t.bigint :parent_id
      t.integer :position, default: 0, null: false
      t.string :slug, null: false
      t.boolean :visible, default: true, null: false
      t.timestamps
    end
    add_index :genres, :parent_id
    add_index :genres, :position
    add_index :genres, :slug, unique: true
    add_foreign_key :genres, :genres, column: :parent_id

    # ==========================================
    # Spots
    # ==========================================
    create_table :spots do |t|
      t.string :address, null: false
      t.string :city
      t.float :lat, null: false
      t.float :lng, null: false
      t.string :name, null: false
      t.string :place_id, null: false
      t.string :prefecture
      t.string :town
      t.timestamps
    end
    add_index :spots, :city
    add_index :spots, :place_id, unique: true
    add_index :spots, :prefecture

    # ==========================================
    # Spot Genres (多対多)
    # ==========================================
    create_table :spot_genres do |t|
      t.references :genre, null: false, foreign_key: true
      t.references :spot, null: false, foreign_key: true
      t.timestamps
    end
    add_index :spot_genres, [ :spot_id, :genre_id ], unique: true

    # ==========================================
    # Spot Comments
    # ==========================================
    create_table :spot_comments do |t|
      t.text :body
      t.references :spot, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    # ==========================================
    # Favorite Spots
    # ==========================================
    create_table :favorite_spots do |t|
      t.references :spot, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :favorite_spots, [ :user_id, :spot_id ], unique: true

    # ==========================================
    # Plans
    # ==========================================
    create_table :plans do |t|
      t.string :title
      t.float :total_distance, default: 0.0, null: false
      t.integer :total_time, default: 0, null: false
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :plans, :title
    add_index :plans, :updated_at

    # ==========================================
    # Start Points
    # ==========================================
    create_table :start_points do |t|
      t.string :address
      t.string :city
      t.time :departure_time
      t.float :lat
      t.float :lng
      t.float :move_distance
      t.integer :move_time
      t.references :plan, null: false, foreign_key: true
      t.text :polyline
      t.string :prefecture
      t.boolean :toll_used, default: false, null: false
      t.string :town
      t.timestamps
    end
    add_index :start_points, :city
    add_index :start_points, :prefecture

    # ==========================================
    # Goal Points
    # ==========================================
    create_table :goal_points do |t|
      t.string :address
      t.time :arrival_time
      t.float :lat
      t.float :lng
      t.references :plan, null: false, foreign_key: true
      t.timestamps
    end

    # ==========================================
    # Plan Spots (中間テーブル)
    # ==========================================
    create_table :plan_spots do |t|
      t.time :arrival_time
      t.time :departure_time
      t.text :memo
      t.float :move_distance, default: 0.0, null: false
      t.integer :move_time, default: 0, null: false
      t.references :plan, null: false, foreign_key: true
      t.text :polyline
      t.integer :position, null: false
      t.references :spot, null: false, foreign_key: true
      t.integer :stay_duration
      t.boolean :toll_used, default: false, null: false
      t.timestamps
    end
    add_index :plan_spots, [ :plan_id, :position ]
    add_index :plan_spots, [ :plan_id, :spot_id ], unique: true

    # ==========================================
    # Favorite Plans
    # ==========================================
    create_table :favorite_plans do |t|
      t.references :plan, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :favorite_plans, [ :user_id, :plan_id ], unique: true

    # ==========================================
    # Suggestions
    # ==========================================
    create_table :suggestions do |t|
      t.text :content, null: false
      t.references :plan, null: false, foreign_key: true
      t.string :role, null: false
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :suggestions, [ :plan_id, :created_at ]
  end
end
