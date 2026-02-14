# frozen_string_literal: true

require "rails_helper"

RSpec.describe "My Plans", type: :system do
  describe "作ったプラン一覧" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトする" do
        visit plans_path

        expect(page).to have_current_path(new_user_session_path)
      end
    end
  end
end
