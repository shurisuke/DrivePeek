# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Plan Creation", type: :system do
  describe "新規プラン作成" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトする" do
        visit new_plan_path

        expect(page).to have_current_path(new_user_session_path)
      end
    end
  end
end
