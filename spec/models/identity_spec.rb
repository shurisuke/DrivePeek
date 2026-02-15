# frozen_string_literal: true

require "rails_helper"

RSpec.describe Identity, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    let(:user) { create(:user) }

    it { should validate_presence_of(:provider) }
    it { should validate_presence_of(:uid) }

    it "同じproviderとuidの組み合わせは一意" do
      create(:identity, user: user, provider: "twitter2", uid: "12345")
      duplicate = build(:identity, user: user, provider: "twitter2", uid: "12345")
      expect(duplicate).not_to be_valid
    end

    it "異なるproviderなら同じuidでも可" do
      create(:identity, user: user, provider: "twitter2", uid: "12345")
      other = build(:identity, user: user, provider: "line", uid: "12345")
      expect(other).to be_valid
    end
  end

  describe ".provider_name_for" do
    it "twitter2はXを返す" do
      expect(Identity.provider_name_for("twitter2")).to eq("X")
    end

    it "lineはLINEを返す" do
      expect(Identity.provider_name_for("line")).to eq("LINE")
    end

    it "その他はtitleizeで返す" do
      expect(Identity.provider_name_for("google")).to eq("Google")
    end
  end

  describe "#provider_name" do
    it "プロバイダの表示名を返す" do
      identity = build(:identity, provider: "twitter2")
      expect(identity.provider_name).to eq("X")
    end
  end
end
