# frozen_string_literal: true

require "rails_helper"

RSpec.describe FavoriteSpot, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:spot) }
  end

  describe "validations" do
    let(:user) { create(:user) }
    let(:spot) { create(:spot) }

    before { create(:favorite_spot, user: user, spot: spot) }

    it { should validate_uniqueness_of(:user_id).scoped_to(:spot_id) }
  end

  describe "counter_cache" do
    let(:user) { create(:user) }
    let(:spot) { create(:spot) }

    it "作成時にfavorite_spots_countが増加する" do
      expect {
        create(:favorite_spot, user: user, spot: spot)
      }.to change { spot.reload.favorite_spots_count }.by(1)
    end

    it "削除時にfavorite_spots_countが減少する" do
      favorite = create(:favorite_spot, user: user, spot: spot)

      expect {
        favorite.destroy
      }.to change { spot.reload.favorite_spots_count }.by(-1)
    end
  end
end
