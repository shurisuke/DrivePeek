# frozen_string_literal: true

# 認証が必要なエンドポイントのテスト
RSpec.shared_examples "要認証エンドポイント" do |method, path, params: {}, format: :json|
  context "未ログインの場合" do
    it "401エラーを返す" do
      send(method, instance_exec(&path), params: params, as: format)
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

# 認証が必要で、未ログイン時にリダイレクトするエンドポイント
RSpec.shared_examples "要認証エンドポイント（リダイレクト）" do |method, path, params: {}|
  context "未ログインの場合" do
    it "ログイン画面にリダイレクトする" do
      send(method, instance_exec(&path), params: params)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end

# 他人のリソースへのアクセス拒否テスト
RSpec.shared_examples "他人のリソースへのアクセス拒否" do |method, path, params: {}|
  context "他人のリソースの場合" do
    it "404エラーを返す" do
      send(method, instance_exec(&path), params: params, as: :json)
      expect(response).to have_http_status(:not_found)
    end
  end
end

# Turbo Stream形式のレスポンステスト
RSpec.shared_examples "Turbo Streamレスポンス" do |method, path, params: {}|
  it "Turbo Stream形式でレスポンスを返す" do
    send(method, instance_exec(&path),
         params: params,
         headers: { "Accept" => "text/vnd.turbo-stream.html" })

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include("text/vnd.turbo-stream.html")
  end
end
