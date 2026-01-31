class ChangeAiChatMessagesContentDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :ai_chat_messages, :content, from: "{}", to: nil
  end
end
