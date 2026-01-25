module AiHelper
  # AI応答のdescriptionを最初の「。」で分割してサマリーと詳細に分ける
  # @param description [String] スポットの説明文
  # @return [Hash] { summary: String, details: String }
  def split_spot_description(description)
    desc = description.to_s
    first_period = desc.index("。")

    if first_period
      {
        summary: desc[0..first_period],
        details: desc[(first_period + 1)..-1].to_s.strip
      }
    else
      { summary: desc, details: "" }
    end
  end
end
