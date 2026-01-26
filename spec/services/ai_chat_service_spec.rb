# frozen_string_literal: true

require "rails_helper"

RSpec.describe AiChatService, type: :service do
  let(:user) { create(:user) }
  let(:plan) { create(:plan, user: user) }

  before do
    stub_openai_chat_api
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("test-key")
  end

  describe ".chat" do
    context "API設定がない場合" do
      before do
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return(nil)
      end

      it "エラーレスポンスを返す" do
        result = described_class.chat("テスト")

        expect(result[:type]).to eq("conversation")
        expect(result[:message]).to include("API設定エラー")
      end
    end

    context "場所が特定できない場合" do
      it "場所を聞き返すレスポンスを返す" do
        result = described_class.chat("温泉に行きたい")

        expect(result[:type]).to eq("conversation")
        expect(result[:message]).to include("どのエリア")
      end

      it "希望内容を認識したことを伝える" do
        result = described_class.chat("温泉に行きたい")

        expect(result[:message]).to include("温泉に行きたい")
      end
    end

    context "場所が特定できる場合" do
      let!(:spot) { create(:spot, city: "日光市", prefecture: "栃木県", lat: 36.75, lng: 139.6) }

      before do
        # OpenAI APIのモックレスポンスを設定
        stub_openai_chat_api_with_response({
          theme: "日光の旅",
          description: "テスト説明",
          spot_ids: [ spot.id ],
          spot_descriptions: { spot.id.to_s => "素敵なスポットです" },
          closing: "楽しんでください"
        })
      end

      it "planタイプのレスポンスを返す" do
        result = described_class.chat("日光で温泉に行きたい")

        expect(result[:type]).to eq("plan")
      end

      it "spotsを含むレスポンスを返す" do
        result = described_class.chat("日光で温泉に行きたい")

        expect(result[:spots]).to be_present
      end
    end

    context "候補スポットが見つからない場合" do
      before do
        # エリアは見つかるが、スポットがない状態
        allow(Spot).to receive(:where).and_return(Spot.none)
      end

      it "エリアでスポットが見つからないメッセージを返す" do
        # この場合、find_area_from_messageもnilになるため、場所を聞き返す
        result = described_class.chat("存在しないエリア")

        expect(result[:type]).to eq("conversation")
      end
    end

    context "通信エラーが発生した場合" do
      before do
        allow_any_instance_of(OpenAI::Client).to receive(:chat).and_raise(Faraday::Error.new("connection error"))
      end

      let!(:spot) { create(:spot, city: "日光市", prefecture: "栃木県") }

      it "通信エラーのレスポンスを返す" do
        result = described_class.chat("日光で温泉")

        expect(result[:type]).to eq("conversation")
        expect(result[:message]).to include("通信エラー")
      end
    end
  end

  describe "private methods (via send)" do
    describe "#extract_wishes" do
      it "グルメ系キーワードを抽出する" do
        result = described_class.send(:extract_wishes, "美味しいランチが食べたい")

        expect(result).to include(:gourmet)
      end

      it "温泉系キーワードを抽出する" do
        result = described_class.send(:extract_wishes, "温泉に入りたい")

        expect(result).to include(:onsen)
      end

      it "複数のジャンルを抽出する" do
        result = described_class.send(:extract_wishes, "温泉とグルメを楽しみたい")

        expect(result).to include(:onsen, :gourmet)
      end

      it "海系キーワードを抽出する" do
        result = described_class.send(:extract_wishes, "ビーチでゆっくりしたい")

        expect(result).to include(:sea)
      end

      it "空のメッセージは空配列を返す" do
        expect(described_class.send(:extract_wishes, "")).to eq([])
        expect(described_class.send(:extract_wishes, nil)).to eq([])
      end
    end

    describe "#detect_response_mode" do
      it "プラン系キーワードで:planを返す" do
        expect(described_class.send(:detect_response_mode, "ドライブプランを考えて")).to eq(:plan)
      end

      it "「〜たい」で終わる場合:planを返す" do
        expect(described_class.send(:detect_response_mode, "温泉に行きたい")).to eq(:plan)
      end

      it "「〜ない？」で終わる場合:spotsを返す" do
        expect(described_class.send(:detect_response_mode, "いいところない？")).to eq(:spots)
      end

      it "「おすすめ」を含む場合:spotsを返す" do
        expect(described_class.send(:detect_response_mode, "おすすめのスポット")).to eq(:spots)
      end

      it "「〜って何？」で終わる場合:answerを返す" do
        expect(described_class.send(:detect_response_mode, "日光って何？")).to eq(:answer)
      end

      it "空のメッセージは:planを返す" do
        expect(described_class.send(:detect_response_mode, "")).to eq(:plan)
      end

      it "デフォルトは:planを返す" do
        expect(described_class.send(:detect_response_mode, "こんにちは")).to eq(:plan)
      end
    end

    describe "#build_slots" do
      it "希望がなければデフォルトスロットを返す" do
        result = described_class.send(:build_slots, [])

        expect(result).to eq(described_class::DEFAULT_SLOTS)
      end

      it "希望に応じてスロットを入れ替える" do
        result = described_class.send(:build_slots, [ :sea ])

        expect(result).to include(:sea)
      end

      it "既存スロットと重複する希望は入れ替えない" do
        result = described_class.send(:build_slots, [ :onsen ])

        # onsenは既にDEFAULT_SLOTSに含まれているので変化なし
        expect(result.count(:onsen)).to eq(1)
      end

      it "優先度が低いスロットから入れ替える" do
        # sightseeingが最も優先度が低いので入れ替え対象
        result = described_class.send(:build_slots, [ :sea ])

        expect(result).to include(:sea)
        expect(result).not_to include(:sightseeing)
      end
    end

    describe "#add_request?" do
      it "「もう一個」を含む場合trueを返す" do
        expect(described_class.send(:add_request?, "もう一個追加して")).to be true
      end

      it "「追加」を含む場合trueを返す" do
        expect(described_class.send(:add_request?, "スポットを追加して")).to be true
      end

      it "追加パターンがない場合falseを返す" do
        expect(described_class.send(:add_request?, "変えて")).to be false
      end

      it "空のメッセージはfalseを返す" do
        expect(described_class.send(:add_request?, "")).to be false
        expect(described_class.send(:add_request?, nil)).to be false
      end
    end

    describe "#detect_partial_change" do
      let(:previous_context) do
        {
          spot_details: [
            { index: 0, spot_id: 1, name: "スポットA" },
            { index: 1, spot_id: 2, name: "スポットB" },
            { index: 2, spot_id: 3, name: "温泉C" }
          ],
          slots: %i[sightseeing gourmet onsen]
        }
      end

      it "「〇番だけ変えて」パターンを検出する" do
        result = described_class.send(:detect_partial_change, "2番だけ変えて", previous_context)

        expect(result[:change_indices]).to eq([ 1 ])
        expect(result[:keep_indices]).to eq([ 0, 2 ])
      end

      it "「〇〇以外変えて」パターンを検出する" do
        result = described_class.send(:detect_partial_change, "スポットA以外変えて", previous_context)

        expect(result[:keep_indices]).to eq([ 0 ])
        expect(result[:change_indices]).to eq([ 1, 2 ])
      end

      it "「〇〇は残して」パターンを検出する" do
        result = described_class.send(:detect_partial_change, "スポットBは残して", previous_context)

        expect(result[:keep_indices]).to eq([ 1 ])
        expect(result[:change_indices]).to eq([ 0, 2 ])
      end

      it "previous_contextがnilの場合nilを返す" do
        expect(described_class.send(:detect_partial_change, "2番変えて", nil)).to be_nil
      end

      it "メッセージが空の場合nilを返す" do
        expect(described_class.send(:detect_partial_change, "", previous_context)).to be_nil
      end

      it "パターンに一致しない場合nilを返す" do
        expect(described_class.send(:detect_partial_change, "こんにちは", previous_context)).to be_nil
      end
    end

    describe "#find_area_from_message" do
      let!(:spot) { create(:spot, city: "日光市", prefecture: "栃木県", address: "栃木県日光市") }

      it "メッセージからエリア情報を抽出する" do
        result = described_class.send(:find_area_from_message, "日光で温泉")

        expect(result).to be_present
        expect(result[:keyword]).to eq("日光")
        expect(result[:prefecture]).to eq("栃木県")
      end

      it "場所が見つからない場合nilを返す" do
        result = described_class.send(:find_area_from_message, "存在しない場所")

        expect(result).to be_nil
      end

      it "空のメッセージはnilを返す" do
        expect(described_class.send(:find_area_from_message, "")).to be_nil
        expect(described_class.send(:find_area_from_message, nil)).to be_nil
      end

      it "非場所キーワードを除外する" do
        # 「温泉」は NON_LOCATION_WORDS に含まれる
        result = described_class.send(:find_area_from_message, "温泉")

        expect(result).to be_nil
      end
    end

    describe "#calculate_distance" do
      it "2点間の距離をkmで計算する" do
        # 東京駅(35.6812, 139.7671) → 新宿駅(35.6896, 139.7006)
        result = described_class.send(:calculate_distance, 35.6812, 139.7671, 35.6896, 139.7006)

        # 約6-7km程度
        expect(result).to be_between(5, 8)
      end

      it "同一地点は0を返す" do
        result = described_class.send(:calculate_distance, 35.0, 139.0, 35.0, 139.0)

        expect(result).to eq(0)
      end
    end
  end

  describe "constants" do
    it "MODEL定数が設定されている" do
      expect(described_class::MODEL).to eq("gpt-4o-mini")
    end

    it "DEFAULT_SLOTSが正しい順序" do
      expect(described_class::DEFAULT_SLOTS).to eq(%i[sightseeing gourmet onsen])
    end

    it "SLOT_PRIORITYが設定されている" do
      expect(described_class::SLOT_PRIORITY).to eq({
        gourmet: 1,
        onsen: 2,
        sightseeing: 3
      })
    end

    it "WISH_KEYWORDSにグルメ系が含まれる" do
      expect(described_class::WISH_KEYWORDS["グルメ"]).to eq(:gourmet)
      expect(described_class::WISH_KEYWORDS["ランチ"]).to eq(:gourmet)
    end

    it "WISH_KEYWORDSに温泉系が含まれる" do
      expect(described_class::WISH_KEYWORDS["温泉"]).to eq(:onsen)
      expect(described_class::WISH_KEYWORDS["スパ"]).to eq(:onsen)
    end

    it "NON_LOCATION_WORDSが設定されている" do
      expect(described_class::NON_LOCATION_WORDS).to include("温泉", "ドライブ", "グルメ")
    end
  end
end
