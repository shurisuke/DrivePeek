# frozen_string_literal: true

require "rails_helper"

RSpec.describe Genre::Detector do
  let(:spot) { create(:spot, name: "テストラーメン店", address: "東京都渋谷区") }

  describe ".detect" do
    context "APIキーが設定されていない場合" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return(nil)
      end

      it "空配列を返す" do
        expect(Genre::Detector.detect(spot)).to eq([])
      end
    end

    context "APIキーが設定されている場合" do
      let!(:ramen_genre) { create(:genre, slug: "ramen", name: "ラーメン") }
      let!(:night_view_genre) { create(:genre, slug: "night_view", name: "夜景") }
      let(:openai_client) { instance_double(OpenAI::Client) }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("test-key")
        allow(OpenAI::Client).to receive(:new).and_return(openai_client)
      end

      context "正常なレスポンスの場合" do
        before do
          allow(openai_client).to receive(:chat).and_return({
            "choices" => [ {
              "message" => { "content" => "ramen, night_view" }
            } ]
          })
        end

        it "ジャンルIDの配列を返す" do
          result = Genre::Detector.detect(spot)
          expect(result).to contain_exactly(ramen_genre.id, night_view_genre.id)
        end
      end

      context "1つだけのジャンルを返す場合" do
        before do
          allow(openai_client).to receive(:chat).and_return({
            "choices" => [ {
              "message" => { "content" => "ramen" }
            } ]
          })
        end

        it "1つのジャンルIDを返す" do
          result = Genre::Detector.detect(spot)
          expect(result).to eq([ ramen_genre.id ])
        end
      end

      context "noneを返す場合" do
        before do
          allow(openai_client).to receive(:chat).and_return({
            "choices" => [ {
              "message" => { "content" => "none" }
            } ]
          })
        end

        it "空配列を返す" do
          result = Genre::Detector.detect(spot)
          expect(result).to eq([])
        end
      end

      context "存在しないジャンルslugを返す場合" do
        before do
          allow(openai_client).to receive(:chat).and_return({
            "choices" => [ {
              "message" => { "content" => "invalid_slug" }
            } ]
          })
        end

        it "空配列を返す" do
          result = Genre::Detector.detect(spot)
          expect(result).to eq([])
        end
      end

      context "countを指定した場合" do
        let!(:cafe_genre) { create(:genre, slug: "cafe", name: "カフェ") }

        before do
          allow(openai_client).to receive(:chat).and_return({
            "choices" => [ {
              "message" => { "content" => "ramen, cafe, night_view" }
            } ]
          })
        end

        it "指定した件数まで返す" do
          result = Genre::Detector.detect(spot, count: 2)
          expect(result.size).to eq(2)
        end
      end

      context "観光名所と特定ジャンルが同時に選ばれた場合" do
        let!(:sightseeing) { create(:genre, slug: "sightseeing", name: "観光名所") }
        let!(:shrine_temple) { create(:genre, slug: "shrine_temple", name: "神社・寺") }

        before do
          allow(openai_client).to receive(:chat).and_return({
            "choices" => [ {
              "message" => { "content" => "sightseeing, shrine_temple" }
            } ]
          })
        end

        it "観光名所を除外して返す" do
          result = Genre::Detector.detect(spot)
          expect(result).to eq([ shrine_temple.id ])
        end
      end

      context "レスポンスがnilの場合" do
        before do
          allow(openai_client).to receive(:chat).and_return(nil)
        end

        it "空配列を返す" do
          result = Genre::Detector.detect(spot)
          expect(result).to eq([])
        end
      end

      context "レスポンスにcontentがない場合" do
        before do
          allow(openai_client).to receive(:chat).and_return({
            "choices" => [ { "message" => {} } ]
          })
        end

        it "空配列を返す" do
          result = Genre::Detector.detect(spot)
          expect(result).to eq([])
        end
      end

      context "Faradayエラーが発生した場合" do
        before do
          allow(openai_client).to receive(:chat).and_raise(Faraday::TimeoutError.new("timeout"))
        end

        it "空配列を返す" do
          result = Genre::Detector.detect(spot)
          expect(result).to eq([])
        end
      end

      context "予期しないエラーが発生した場合" do
        before do
          allow(openai_client).to receive(:chat).and_raise(StandardError.new("unexpected"))
        end

        it "空配列を返す" do
          result = Genre::Detector.detect(spot)
          expect(result).to eq([])
        end
      end
    end
  end
end
