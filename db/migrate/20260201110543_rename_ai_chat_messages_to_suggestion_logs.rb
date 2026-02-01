class RenameAiChatMessagesToSuggestionLogs < ActiveRecord::Migration[8.1]
  def change
    rename_table :ai_chat_messages, :suggestion_logs
  end
end
