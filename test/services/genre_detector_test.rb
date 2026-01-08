require "test_helper"

class GenreDetectorTest < ActiveSupport::TestCase
  setup do
    @spot = spots(:one)
    @original_api_key = ENV["ANTHROPIC_API_KEY"]
  end

  teardown do
    ENV["ANTHROPIC_API_KEY"] = @original_api_key
  end

  test "detect returns empty array when API key is not configured" do
    ENV["ANTHROPIC_API_KEY"] = nil

    result = GenreDetector.detect(@spot)

    assert_empty result
  end

  test "detect returns genre IDs from API response" do
    ENV["ANTHROPIC_API_KEY"] = "test_key"
    mock_response = mock_claude_response("sea_coast, scenic_view")

    mock_client = build_mock_client(mock_response)
    Anthropic::Client.stub :new, mock_client do
      result = GenreDetector.detect(@spot)

      assert_includes result, genres(:sea_coast).id
      assert_includes result, genres(:scenic_view).id
    end
  end

  test "detect handles single genre response" do
    ENV["ANTHROPIC_API_KEY"] = "test_key"
    mock_response = mock_claude_response("gourmet")

    mock_client = build_mock_client(mock_response)
    Anthropic::Client.stub :new, mock_client do
      result = GenreDetector.detect(@spot)

      assert_equal [ genres(:gourmet).id ], result
    end
  end

  test "detect returns empty array for unknown genre slugs" do
    ENV["ANTHROPIC_API_KEY"] = "test_key"
    mock_response = mock_claude_response("unknown_genre")

    mock_client = build_mock_client(mock_response)
    Anthropic::Client.stub :new, mock_client do
      result = GenreDetector.detect(@spot)

      assert_empty result
    end
  end

  test "detect handles nil response" do
    ENV["ANTHROPIC_API_KEY"] = "test_key"

    mock_client = build_mock_client(nil)
    Anthropic::Client.stub :new, mock_client do
      result = GenreDetector.detect(@spot)

      assert_empty result
    end
  end

  private

  def mock_claude_response(text)
    OpenStruct.new(
      content: [ { type: "text", text: text } ]
    )
  end

  def build_mock_client(response)
    mock_messages = Object.new
    mock_messages.define_singleton_method(:create) { |**_args| response }

    mock_client = Object.new
    mock_client.define_singleton_method(:messages) { mock_messages }
    mock_client
  end
end
