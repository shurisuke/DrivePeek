# frozen_string_literal: true

require "rails_helper"

RSpec.describe FavoritePlan, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:plan) }
  end

  describe "validations" do
    let(:user) { create(:user) }
    let(:plan) { create(:plan) }

    before { create(:favorite_plan, user: user, plan: plan) }

    it { should validate_uniqueness_of(:user_id).scoped_to(:plan_id) }
  end

  describe "counter_cache" do
    let(:user) { create(:user) }
    let(:plan) { create(:plan) }

    it "作成時にfavorite_plans_countが増加する" do
      expect {
        create(:favorite_plan, user: user, plan: plan)
      }.to change { plan.reload.favorite_plans_count }.by(1)
    end

    it "削除時にfavorite_plans_countが減少する" do
      favorite = create(:favorite_plan, user: user, plan: plan)

      expect {
        favorite.destroy
      }.to change { plan.reload.favorite_plans_count }.by(-1)
    end
  end
end
