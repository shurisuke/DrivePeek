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

  describe "#password_required?" do
    it "通常ユーザーはパスワード必須" do
      user = build(:user)
      expect(user.password_required?).to be true
    end

    it "SNSユーザーはパスワード不要" do
      user = build(:user, :sns_only)
      expect(user.password_required?).to be false
    end
  end

  describe "#email_required?" do
    it "通常ユーザーはメール必須" do
      user = build(:user)
      expect(user.email_required?).to be true
    end

    it "SNSユーザーはメール不要" do
      user = build(:user, :sns_only)
      expect(user.email_required?).to be false
    end
  end

  describe "#confirmation_required?" do
    it "常にfalseを返す" do
      user = build(:user)
      expect(user.confirmation_required?).to be false
    end
  end

  describe "#age_group_display" do
    it "年代が設定されていない場合はnilを返す" do
      user = build(:user, age_group: nil)
      expect(user.age_group_display).to be_nil
    end

    it "年代が設定されている場合は表示名を返す" do
      user = build(:user, age_group: :twenties)
      expect(user.age_group_display).to be_present
    end
  end

  describe "#gender_display" do
    it "性別が未設定の場合はnilを返す" do
      user = build(:user, gender: nil)
      expect(user.gender_display).to be_nil
    end

    it "not_specifiedの場合はnilを返す" do
      user = build(:user, gender: :not_specified)
      expect(user.gender_display).to be_nil
    end

    it "性別が設定されている場合は表示名を返す" do
      user = build(:user, gender: :male)
      expect(user.gender_display).to be_present
    end
  end

  describe "#comment_profile" do
    it "居住地と年代・性別を連結して返す" do
      user = build(:user, residence: "東京都", age_group: :twenties, gender: :male)
      result = user.comment_profile
      expect(result).to include("東京都")
    end

    it "空の場合は空文字を返す" do
      user = build(:user, residence: nil, age_group: nil, gender: nil)
      expect(user.comment_profile).to eq("")
    end
  end

  describe "#confirmation_pending?" do
    let(:user) { create(:user) }

    it "確認メール送信後30分以内はtrueを返す" do
      user.update!(confirmation_sent_at: 10.minutes.ago)
      expect(user.confirmation_pending?).to be true
    end

    it "確認メール送信後30分以上はfalseを返す" do
      user.update!(confirmation_sent_at: 1.hour.ago)
      expect(user.confirmation_pending?).to be false
    end

    it "未送信の場合はfalseを返す" do
      user.update!(confirmation_sent_at: nil)
      expect(user.confirmation_pending?).to be false
    end
  end

  describe "#linked_with?" do
    let(:user) { create(:user) }

    it "連携済みプロバイダに対してtrueを返す" do
      user.identities.create!(provider: "twitter2", uid: "12345")
      expect(user.linked_with?("twitter2")).to be true
    end

    it "未連携プロバイダに対してfalseを返す" do
      expect(user.linked_with?("twitter2")).to be false
    end
  end

  describe ".from_omniauth" do
    let(:user) { create(:user) }
    let(:auth) { OmniAuth::AuthHash.new(provider: "twitter2", uid: "12345") }

    before do
      user.identities.create!(provider: "twitter2", uid: "12345")
    end

    it "既存のユーザーを返す" do
      expect(User.from_omniauth(auth)).to eq(user)
    end

    it "存在しない場合はnilを返す" do
      other_auth = OmniAuth::AuthHash.new(provider: "line", uid: "99999")
      expect(User.from_omniauth(other_auth)).to be_nil
    end
  end

  describe ".create_from_omniauth" do
    let(:auth) { OmniAuth::AuthHash.new(provider: "twitter2", uid: "12345") }

    it "新しいユーザーを作成する" do
      expect { User.create_from_omniauth(auth) }.to change(User, :count).by(1)
    end

    it "Identityを関連付ける" do
      user = User.create_from_omniauth(auth)
      expect(user.identities.first.provider).to eq("twitter2")
    end
  end

  describe "#link_omniauth" do
    let(:user) { create(:user) }
    let(:auth) { OmniAuth::AuthHash.new(provider: "line", uid: "67890") }

    it "新しいIdentityを作成する" do
      expect { user.link_omniauth(auth) }.to change(user.identities, :count).by(1)
    end

    it "同じプロバイダは重複作成しない" do
      user.link_omniauth(auth)
      expect { user.link_omniauth(auth) }.not_to change(user.identities, :count)
    end
  end
end
