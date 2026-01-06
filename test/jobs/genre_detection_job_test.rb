require "test_helper"

class GenreDetectionJobTest < ActiveJob::TestCase
  setup do
    @spot = spots(:one)
  end

  test "creates SpotGenre when GenreDetector returns genre IDs" do
    genre_ids = [genres(:gourmet).id, genres(:cafe).id]

    GenreDetector.stub :detect, genre_ids do
      assert_difference "SpotGenre.count", 2 do
        GenreDetectionJob.perform_now(@spot.id)
      end

      assert @spot.genres.exists?(id: genres(:gourmet).id)
      assert @spot.genres.exists?(id: genres(:cafe).id)
    end
  end

  test "skips when spot already has genres" do
    SpotGenre.create!(spot: @spot, genre: genres(:gourmet))

    GenreDetector.stub :detect, [genres(:cafe).id] do
      assert_no_difference "SpotGenre.count" do
        GenreDetectionJob.perform_now(@spot.id)
      end
    end
  end

  test "skips when spot does not exist" do
    assert_no_difference "SpotGenre.count" do
      GenreDetectionJob.perform_now(-1)
    end
  end

  test "skips when GenreDetector returns empty array" do
    GenreDetector.stub :detect, [] do
      assert_no_difference "SpotGenre.count" do
        GenreDetectionJob.perform_now(@spot.id)
      end
    end
  end

  test "does not duplicate SpotGenre records" do
    genre_ids = [genres(:gourmet).id]

    GenreDetector.stub :detect, genre_ids do
      GenreDetectionJob.perform_now(@spot.id)
    end

    # 既存のジャンルを削除してから再実行
    @spot.spot_genres.destroy_all

    GenreDetector.stub :detect, genre_ids do
      assert_difference "SpotGenre.count", 1 do
        GenreDetectionJob.perform_now(@spot.id)
      end
    end
  end
end
