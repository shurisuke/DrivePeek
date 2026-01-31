# frozen_string_literal: true

# レート制限設定
# AI提案APIへの過剰リクエストを防止
class Rack::Attack
  # キャッシュストアの設定（Rails.cacheを使用）
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # AI提案エンドポイントのレート制限
  # 認証済みユーザーごとに1分間10リクエストまで
  throttle("ai_area/user", limit: 10, period: 1.minute) do |req|
    if req.path.start_with?("/api/ai_area") && req.post?
      # Warden経由でユーザーIDを取得
      req.env["warden"]&.user&.id
    end
  end

  # IP単位のレート制限（未認証リクエスト対策）
  throttle("ai_area/ip", limit: 20, period: 1.minute) do |req|
    if req.path.start_with?("/api/ai_area") && req.post?
      req.ip
    end
  end

  # レート制限時のレスポンス
  self.throttled_responder = lambda do |req|
    [
      429,
      { "Content-Type" => "application/json" },
      [ { error: "リクエストが多すぎます。しばらく待ってからお試しください。" }.to_json ]
    ]
  end
end
