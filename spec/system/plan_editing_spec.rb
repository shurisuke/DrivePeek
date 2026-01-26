# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Plan Editing", type: :system do
  let!(:user) { create(:user) }
  let!(:plan) { create(:plan, user: user) }

  describe "プラン編集" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトする" do
        visit edit_plan_path(plan)

        expect(page).to have_current_path(new_user_session_path)
      end
    end
  end
end
