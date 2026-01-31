# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contact, type: :model do
  describe "validations" do
    it "有効な属性であれば有効" do
      contact = Contact.new(
        category: "bug",
        body: "テストのお問い合わせ内容です。10文字以上必要。",
        email: "test@example.com"
      )
      expect(contact).to be_valid
    end

    it "カテゴリが必須" do
      contact = Contact.new(category: nil, body: "テスト内容です。", email: "test@example.com")
      expect(contact).not_to be_valid
      expect(contact.errors[:category]).to be_present
    end

    it "カテゴリは指定値のみ" do
      contact = Contact.new(category: "invalid", body: "テスト内容です。10文字以上。", email: "test@example.com")
      expect(contact).not_to be_valid
    end

    it "本文が必須" do
      contact = Contact.new(category: "bug", body: nil, email: "test@example.com")
      expect(contact).not_to be_valid
    end

    it "本文は10文字以上必要" do
      contact = Contact.new(category: "bug", body: "短い", email: "test@example.com")
      expect(contact).not_to be_valid
    end

    it "メールアドレスが必須" do
      contact = Contact.new(category: "bug", body: "テスト内容です。10文字以上。", email: nil)
      expect(contact).not_to be_valid
    end

    it "メールアドレスの形式が正しい必要がある" do
      contact = Contact.new(category: "bug", body: "テスト内容です。10文字以上。", email: "invalid")
      expect(contact).not_to be_valid
    end
  end

  describe "#category_name" do
    it "カテゴリの日本語名を返す" do
      contact = Contact.new(category: "bug")
      expect(contact.category_name).to be_present
    end
  end

  describe "#submit" do
    let(:contact) do
      Contact.new(
        category: "bug",
        body: "テストのお問い合わせ内容です。10文字以上必要。",
        email: "test@example.com"
      )
    end

    context "有効な場合" do
      before do
        allow(ContactMailer).to receive_message_chain(:notify_admin, :deliver_now)
      end

      it "trueを返す" do
        expect(contact.submit).to be true
      end

      it "メールを送信する" do
        expect(ContactMailer).to receive_message_chain(:notify_admin, :deliver_now)
        contact.submit
      end
    end

    context "無効な場合" do
      let(:invalid_contact) { Contact.new(category: nil, body: nil, email: nil) }

      it "falseを返す" do
        expect(invalid_contact.submit).to be false
      end
    end

    context "メール送信に失敗した場合" do
      before do
        allow(ContactMailer).to receive_message_chain(:notify_admin, :deliver_now).and_raise(StandardError, "送信エラー")
      end

      it "falseを返す" do
        expect(contact.submit).to be false
      end

      it "エラーが追加される" do
        contact.submit
        expect(contact.errors[:base]).to be_present
      end
    end
  end
end
