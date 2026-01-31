# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContactMailer, type: :mailer do
  describe "#notify_admin" do
    let(:contact) do
      Contact.new(
        category: "bug",
        body: "アプリでエラーが発生しました。詳細を報告します。",
        email: "user@example.com"
      )
    end

    let(:mail) { described_class.notify_admin(contact) }

    it "正しい宛先に送信される" do
      expect(mail.to).to eq([ "drivepeek.app@gmail.com" ])
    end

    it "件名にカテゴリが含まれる" do
      expect(mail.subject).to include("お問い合わせ")
    end

    it "本文にお問い合わせ内容が含まれる" do
      expect(mail.body.encoded).to include(contact.body)
    end

    it "本文にメールアドレスが含まれる" do
      expect(mail.body.encoded).to include(contact.email)
    end
  end
end
