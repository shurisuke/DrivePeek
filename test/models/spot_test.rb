require "test_helper"

class SpotTest < ActiveSupport::TestCase
  setup do
    @spot = spots(:one)
  end

  # detect_genres! テスト
  test "detect_genres! assigns genres via AI" do
    genre_ids = [ genres(:gourmet).id, genres(:cafe).id ]

    GenreDetector.stub :detect, genre_ids do
      assert_difference "SpotGenre.count", 2 do
        result = @spot.detect_genres!
        assert result
      end

      assert @spot.genres.exists?(id: genres(:gourmet).id)
      assert @spot.genres.exists?(id: genres(:cafe).id)
    end
  end

  test "detect_genres! skips when spot already has 2 or more genres" do
    SpotGenre.create!(spot: @spot, genre: genres(:gourmet))
    SpotGenre.create!(spot: @spot, genre: genres(:cafe))

    GenreDetector.stub :detect, [ genres(:park).id ] do
      assert_no_difference "SpotGenre.count" do
        result = @spot.detect_genres!
        assert_not result
      end
    end
  end

  test "detect_genres! falls back to facility when AI returns empty" do
    GenreDetector.stub :detect, [] do
      assert_difference "SpotGenre.count", 1 do
        result = @spot.detect_genres!
        assert result
      end

      assert @spot.genres.exists?(slug: "facility")
    end
  end

  test "detect_genres! returns false on error" do
    GenreDetector.stub :detect, ->(*_args) { raise StandardError, "Test error" } do
      result = @spot.detect_genres!
      assert_not result
    end
  end
end
