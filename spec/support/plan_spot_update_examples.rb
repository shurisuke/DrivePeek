# frozen_string_literal: true

# PlanSpot属性更新テストの共通化
RSpec.shared_examples "PlanSpot属性更新" do |attribute, value, expected = value|
  it "#{attribute}を#{value}に更新する" do
    patch plan_plan_spot_path(plan, plan_spot),
          params: { attribute => value },
          headers: turbo_stream_headers

    expect(response).to have_http_status(:ok)
    expect(plan_spot.reload.send(attribute)).to eq(expected)
  end
end

RSpec.shared_examples "PlanSpot属性をnilに更新" do |attribute|
  it "#{attribute}を空にする（nil）" do
    patch plan_plan_spot_path(plan, plan_spot),
          params: { attribute => "" },
          headers: turbo_stream_headers

    expect(response).to have_http_status(:ok)
    expect(plan_spot.reload.send(attribute)).to be_nil
  end
end
