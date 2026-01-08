# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class Plan::DirectionsClientTest < ActiveSupport::TestCase
  # サンプルのAPIレスポンス
  SAMPLE_API_RESPONSE = {
    "status" => "OK",
    "routes" => [
      {
        "legs" => [
          {
            "duration" => { "value" => 1800, "text" => "30分" },
            "distance" => { "value" => 10500, "text" => "10.5 km" }
          }
        ],
        "overview_polyline" => { "points" => "encoded_polyline_string" }
      }
    ]
  }.freeze

  ERROR_API_RESPONSE = {
    "status" => "ZERO_RESULTS",
    "routes" => []
  }.freeze

  setup do
    @origin = { lat: 35.6580, lng: 139.7016 }
    @destination = { lat: 35.6586, lng: 139.7454 }
  end

  # ----------------------------------------------------------------
  # 正常系
  # ----------------------------------------------------------------
  test "fetch returns parsed route data from API response" do
    mock_http_response(SAMPLE_API_RESPONSE) do
      result = Plan::DirectionsClient.fetch(
        origin: @origin,
        destination: @destination,
        toll_used: false
      )

      assert_equal 30, result[:move_time]       # 1800秒 → 30分
      assert_equal 10.5, result[:move_distance] # 10500m → 10.5km
      assert_equal 0, result[:move_cost]        # Phase 2 では 0 固定
      assert_equal "encoded_polyline_string", result[:polyline]
    end
  end

  test "duration is rounded up to minutes" do
    response = deep_copy(SAMPLE_API_RESPONSE)
    response["routes"][0]["legs"][0]["duration"]["value"] = 125 # 2分5秒 → 3分（切り上げ）

    mock_http_response(response) do
      result = Plan::DirectionsClient.fetch(
        origin: @origin,
        destination: @destination,
        toll_used: false
      )

      assert_equal 3, result[:move_time]
    end
  end

  test "distance is rounded to 1 decimal place" do
    response = deep_copy(SAMPLE_API_RESPONSE)
    response["routes"][0]["legs"][0]["distance"]["value"] = 12345 # 12.345km → 12.3km

    mock_http_response(response) do
      result = Plan::DirectionsClient.fetch(
        origin: @origin,
        destination: @destination,
        toll_used: false
      )

      assert_equal 12.3, result[:move_distance]
    end
  end

  # ----------------------------------------------------------------
  # toll_used の反映
  # ----------------------------------------------------------------
  test "toll_used false adds avoid=tolls parameter" do
    captured_uri = nil

    stub_http_with_uri_capture(->(uri) { captured_uri = uri }, SAMPLE_API_RESPONSE) do
      Plan::DirectionsClient.fetch(
        origin: @origin,
        destination: @destination,
        toll_used: false
      )
    end

    assert_not_nil captured_uri
    assert_includes captured_uri.query, "avoid=tolls"
  end

  test "toll_used true does not add avoid parameter" do
    captured_uri = nil

    stub_http_with_uri_capture(->(uri) { captured_uri = uri }, SAMPLE_API_RESPONSE) do
      Plan::DirectionsClient.fetch(
        origin: @origin,
        destination: @destination,
        toll_used: true
      )
    end

    assert_not_nil captured_uri
    refute_includes captured_uri.query, "avoid="
  end

  # ----------------------------------------------------------------
  # エラーハンドリング
  # ----------------------------------------------------------------
  test "returns fallback result when API returns error status" do
    mock_http_response(ERROR_API_RESPONSE) do
      result = Plan::DirectionsClient.fetch(
        origin: @origin,
        destination: @destination,
        toll_used: false
      )

      assert_equal Plan::DirectionsClient::FALLBACK_RESULT[:move_time], result[:move_time]
      assert_equal Plan::DirectionsClient::FALLBACK_RESULT[:move_distance], result[:move_distance]
      assert_nil result[:polyline]
    end
  end

  test "returns fallback result when coordinates are invalid" do
    result = Plan::DirectionsClient.fetch(
      origin: { lat: nil, lng: nil },
      destination: @destination,
      toll_used: false
    )

    assert_equal Plan::DirectionsClient::FALLBACK_RESULT[:move_time], result[:move_time]
    assert_nil result[:polyline]
  end

  test "returns fallback result when origin is missing lat" do
    result = Plan::DirectionsClient.fetch(
      origin: { lat: nil, lng: 139.7016 },
      destination: @destination,
      toll_used: false
    )

    assert_equal 0, result[:move_time]
  end

  test "returns fallback result on network error" do
    Net::HTTP.stub(:new, ->(*_args) { raise StandardError, "Network error" }) do
      result = Plan::DirectionsClient.fetch(
        origin: @origin,
        destination: @destination,
        toll_used: false
      )

      assert_equal Plan::DirectionsClient::FALLBACK_RESULT[:move_time], result[:move_time]
    end
  end

  test "returns fallback result when routes array is empty" do
    response = { "status" => "OK", "routes" => [] }

    mock_http_response(response) do
      result = Plan::DirectionsClient.fetch(
        origin: @origin,
        destination: @destination,
        toll_used: false
      )

      assert_equal 0, result[:move_time]
      assert_nil result[:polyline]
    end
  end

  # ----------------------------------------------------------------
  # ヘルパーメソッド
  # ----------------------------------------------------------------
  private

  def deep_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end

  def mock_http_response(response_body)
    mock_response = Minitest::Mock.new
    mock_response.expect(:body, response_body.to_json)

    mock_http = Minitest::Mock.new
    mock_http.expect(:use_ssl=, nil, [ true ])
    mock_http.expect(:open_timeout=, nil, [ 10 ])
    mock_http.expect(:read_timeout=, nil, [ 10 ])
    mock_http.expect(:request, mock_response, [ Net::HTTP::Get ])

    Net::HTTP.stub(:new, mock_http) do
      yield
    end

    mock_response.verify
    mock_http.verify
  end

  def stub_http_with_uri_capture(uri_callback, response_body)
    mock_response = Minitest::Mock.new
    mock_response.expect(:body, response_body.to_json)

    mock_http = Object.new
    mock_http.define_singleton_method(:use_ssl=) { |_| }
    mock_http.define_singleton_method(:open_timeout=) { |_| }
    mock_http.define_singleton_method(:read_timeout=) { |_| }
    mock_http.define_singleton_method(:request) { |_req| mock_response }

    original_new = Net::HTTP::Get.method(:new)
    captured_request_uri = nil

    Net::HTTP::Get.stub(:new, ->(request_uri, *args) {
      captured_request_uri = request_uri
      original_new.call(request_uri, *args)
    }) do
      Net::HTTP.stub(:new, ->(*_args) { mock_http }) do
        yield
      end
    end

    # キャプチャしたrequest_uriをURIオブジェクトに変換してコールバック
    if captured_request_uri
      full_uri = URI.parse("https://maps.googleapis.com#{captured_request_uri}")
      uri_callback.call(full_uri)
    end
  end
end
