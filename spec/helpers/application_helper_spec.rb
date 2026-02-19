# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#remaining_minutes" do
    it "残り時間を分で返す" do
      sent_at = 10.minutes.ago
      expect(helper.remaining_minutes(sent_at)).to eq(20)
    end

    it "カスタム期間で計算できる" do
      sent_at = 5.minutes.ago
      expect(helper.remaining_minutes(sent_at, duration: 10.minutes)).to eq(5)
    end
  end

  describe "#avatar_color_for" do
    it "ユーザーIDから色を返す" do
      user = build_stubbed(:user, id: 1)
      expect(helper.avatar_color_for(user)).to match(/^#[A-F0-9]{6}$/i)
    end

    it "同じIDは同じ色を返す" do
      user1 = build_stubbed(:user, id: 42)
      user2 = build_stubbed(:user, id: 42)
      expect(helper.avatar_color_for(user1)).to eq(helper.avatar_color_for(user2))
    end
  end

  describe "#format_datetime" do
    it "時刻をフォーマットする" do
      time = Time.zone.local(2024, 1, 15, 12, 30)
      expect(helper.format_datetime(time)).to eq("2024/01/15 12:30")
    end

    it "nilの場合はnilを返す" do
      expect(helper.format_datetime(nil)).to be_nil
    end
  end
end
