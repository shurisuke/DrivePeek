# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { should have_many(:identities).dependent(:destroy) }
    it { should have_many(:plans).dependent(:destroy) }
    it { should have_many(:favorite_spots).dependent(:destroy) }
    it { should have_many(:favorite_plans).dependent(:destroy) }
    it { should have_many(:spot_comments).dependent(:destroy) }
  end

  describe "validations" do
    context "通常ユーザーの場合" do
      subject { build(:user) }

      it { should validate_presence_of(:email) }

      it "メールアドレスの一意性を検証する" do
        create(:user, email: "test@example.com")
        duplicate_user = build(:user, email: "test@example.com")
        expect(duplicate_user).not_to be_valid
        expect(duplicate_user.errors[:email]).to be_present
      end
    end

    context "SNSユーザーの場合" do
      subject { build(:user, :sns_only) }

      it "メールなしで有効" do
        expect(subject).to be_valid
      end
    end
  end

  describe "enums" do
    it { should define_enum_for(:status).with_values(active: 0, hidden: 1) }
    it { should define_enum_for(:gender).with_values(male: 0, female: 1, not_specified: 2) }
  end

  describe "factory" do
    it "有効なファクトリを持つ" do
      expect(build(:user)).to be_valid
    end

    it "SNSユーザーファクトリが有効" do
      expect(build(:user, :sns_only)).to be_valid
    end
  end

  describe "#sns_only_user?" do
    context "SNS登録中の場合" do
      let(:user) { build(:user, :sns_only) }

      it "trueを返す" do
        expect(user.sns_only_user?).to be true
      end
    end

    context "通常ユーザーの場合" do
      let(:user) { build(:user) }

      it "falseを返す" do
        expect(user.sns_only_user?).to be false
      end
    end
  end
end
