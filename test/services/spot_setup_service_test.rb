require "test_helper"

class SpotSetupServiceTest < ActiveSupport::TestCase
  setup do
    @plan = plans(:one)
    @spot_params = {
      place_id: "ChIJNewPlaceId123",
      name: "Test Restaurant",
      address: "1-2-3 Test, Tokyo",
      lat: 35.6762,
      lng: 139.6503,
      prefecture: "Tokyo",
      city: "Shibuya",
      top_types: [ "restaurant", "food", "establishment" ]
    }
  end

  # ジャンル判定テスト
  test "assigns genres via GenreMapper when types are mappable" do
    # GenreDetector をスタブして AI 補完をスキップ
    GenreDetector.stub :detect, [] do
      service = SpotSetupService.new(plan: @plan, spot_params: @spot_params)

      assert_difference "SpotGenre.count", 1 do
        result = service.setup
        assert result.success?
        assert result.spot.genres.exists?(id: genres(:gourmet).id)
      end
    end
  end

  test "uses GenreDetector synchronously when types are not mappable" do
    @spot_params[:top_types] = [ "natural_feature", "locality" ]

    # GenreDetector が呼ばれることを確認
    detector_called = false
    GenreDetector.stub :detect, ->(*args) { detector_called = true; [] } do
      service = SpotSetupService.new(plan: @plan, spot_params: @spot_params)
      result = service.setup
      assert result.success?
    end

    assert detector_called, "GenreDetector.detect should be called"
  end

  test "does not assign genres when spot already has genres" do
    # 別のプランを使用（既存スポットとの重複を避ける）
    other_plan = plans(:two)

    # 既存のスポットを使用（ジャンル付き）
    existing_spot = spots(:one)
    SpotGenre.create!(spot: existing_spot, genre: genres(:sightseeing))

    # GenreMapper がマッピング可能な types を使用
    spot_params = @spot_params.merge(
      place_id: existing_spot.place_id,
      top_types: [ "restaurant", "food" ]
    )
    service = SpotSetupService.new(plan: other_plan, spot_params: spot_params)

    # 既にジャンルがあるのでスキップされる
    result = service.setup

    assert result.success?, "Expected success but got: #{result.error_message} - #{result.errors}"
    # 新しいジャンルが追加されていないことを確認（既存の1件のみ）
    assert_equal 1, existing_spot.spot_genres.count
    assert existing_spot.genres.exists?(id: genres(:sightseeing).id)
  end

  test "assigns multiple genres when multiple types match" do
    # park + zoo の組み合わせ（両方ともFALLBACKではない）
    @spot_params[:top_types] = [ "park", "zoo", "establishment" ]
    service = SpotSetupService.new(plan: @plan, spot_params: @spot_params)

    result = service.setup
    assert result.success?
    assert result.spot.genres.exists?(id: genres(:park).id)
    assert result.spot.genres.exists?(id: genres(:zoo).id)
  end

  test "does not fail spot creation when genre assignment fails" do
    # GenreMapper を一時的に壊す
    GenreMapper.stub :map, ->(types) { raise StandardError, "Test error" } do
      service = SpotSetupService.new(plan: @plan, spot_params: @spot_params)

      result = service.setup
      assert result.success?
      assert result.spot.persisted?
    end
  end

  test "handles empty top_types gracefully" do
    @spot_params[:top_types] = []

    # GenreDetector が呼ばれ、facility がフォールバックされることを確認
    GenreDetector.stub :detect, [] do
      service = SpotSetupService.new(plan: @plan, spot_params: @spot_params)
      result = service.setup
      assert result.success?
      # facility がフォールバックで設定される
      assert result.spot.genres.exists?(slug: "facility")
    end
  end

  test "handles nil top_types gracefully" do
    @spot_params.delete(:top_types)

    GenreDetector.stub :detect, [] do
      service = SpotSetupService.new(plan: @plan, spot_params: @spot_params)
      result = service.setup
      assert result.success?
      # facility がフォールバックで設定される
      assert result.spot.genres.exists?(slug: "facility")
    end
  end
end
