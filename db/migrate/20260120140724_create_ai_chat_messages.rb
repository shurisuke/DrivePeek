class CreateAiChatMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_chat_messages do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false

      t.timestamps
    end

    add_index :ai_chat_messages, [ :plan_id, :created_at ]
  end
end
