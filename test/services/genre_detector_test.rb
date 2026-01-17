require "test_helper"

class GenreDetectorTest < ActiveSupport::TestCase
  setup do
    @spot = spots(:one)
    @original_api_key = ENV["OPENAI_API_KEY"]
  end

  teardown do
    ENV["OPENAI_API_KEY"] = @original_api_key
  end

  test "detect returns empty array when API key is not configured" do
    ENV["OPENAI_API_KEY"] = nil

    result = GenreDetector.detect(@spot)

    assert_empty result
  end

  test "detect returns genre IDs from API response" do
    ENV["OPENAI_API_KEY"] = "test_key"
    mock_response = mock_openai_response("sea_coast, scenic_view")

    mock_client = build_mock_client(mock_response)
    OpenAI::Client.stub :new, ->(**_args) { mock_client } do
      result = GenreDetector.detect(@spot)

      assert_includes result, genres(:sea_coast).id
      assert_includes result, genres(:scenic_view).id
    end
  end

  test "detect respects count parameter" do
    ENV["OPENAI_API_KEY"] = "test_key"
    mock_response = mock_openai_response("cafe, park, sea_coast")

    mock_client = build_mock_client(mock_response)
    OpenAI::Client.stub :new, ->(**_args) { mock_client } do
      result = GenreDetector.detect(@spot, count: 1)

      assert_equal 1, result.size
    end
  end

  test "detect handles single genre response" do
    ENV["OPENAI_API_KEY"] = "test_key"
    mock_response = mock_openai_response("cafe")

    mock_client = build_mock_client(mock_response)
    OpenAI::Client.stub :new, ->(**_args) { mock_client } do
      result = GenreDetector.detect(@spot)

      assert_equal [ genres(:cafe).id ], result
    end
  end

  test "detect returns empty array for unknown genre slugs" do
    ENV["OPENAI_API_KEY"] = "test_key"
    mock_response = mock_openai_response("unknown_genre")

    mock_client = build_mock_client(mock_response)
    OpenAI::Client.stub :new, ->(**_args) { mock_client } do
      result = GenreDetector.detect(@spot)

      assert_empty result
    end
  end

  test "detect handles nil response" do
    ENV["OPENAI_API_KEY"] = "test_key"

    mock_client = build_mock_client(nil)
    OpenAI::Client.stub :new, ->(**_args) { mock_client } do
      result = GenreDetector.detect(@spot)

      assert_empty result
    end
  end

  private

  def mock_openai_response(text)
    {
      "choices" => [
        { "message" => { "content" => text } }
      ]
    }
  end

  def build_mock_client(response)
    mock_client = Object.new
    mock_client.define_singleton_method(:chat) { |**_args| response }
    mock_client
  end
end
