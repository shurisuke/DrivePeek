class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # X (Twitter) OAuth 2.0 コールバック
  def twitter2
    handle_oauth("X")
  end

  # LINE Login コールバック
  def line
    handle_oauth("LINE")
  end

  # OAuth失敗時
  def failure
    redirect_to new_user_session_path, alert: "認証に失敗しました。もう一度お試しください。"
  end

  private

  def handle_oauth(provider_name)
    auth = request.env["omniauth.auth"]

    # ログイン済みユーザーからのSNS連携（設定画面から）
    if user_signed_in?
      current_user.link_omniauth(auth)
      redirect_to edit_user_registration_path(section: :sns), notice: "#{provider_name}と連携しました"
      return
    end

    # SNS連携済みユーザーを検索
    @user = User.from_omniauth(auth)

    if @user
      # 既存ユーザー：通常ログイン
      flash[:notice] = "#{provider_name}でログインしました"
      sign_in_and_redirect @user, event: :authentication
    else
      # 新規ユーザー：直接登録
      @user = User.create_from_omniauth(auth)
      if @user.persisted?
        flash[:notice] = "#{provider_name}で登録しました"
        sign_in @user, event: :authentication
        # 新規登録後はプロフィール設定ページへ
        redirect_to users_profile_setup_path(from: "signup")
      else
        # エラー詳細を表示
        error_message = @user.errors.full_messages.join(", ")
        Rails.logger.error "OAuth registration failed: #{error_message}"
        redirect_to new_user_registration_path, alert: "登録に失敗しました。#{error_message}"
      end
    end
  end
end
