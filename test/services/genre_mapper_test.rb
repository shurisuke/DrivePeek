require "test_helper"

class GenreMapperTest < ActiveSupport::TestCase
  test "map returns genre IDs for restaurant type" do
    result = GenreMapper.map(["restaurant", "food", "point_of_interest"])

    assert_includes result, genres(:gourmet).id
  end

  test "map returns genre IDs for cafe type" do
    result = GenreMapper.map(["cafe", "food", "establishment"])

    assert_includes result, genres(:cafe).id
  end

  test "map returns genre IDs for park type" do
    result = GenreMapper.map(["park", "point_of_interest"])

    assert_includes result, genres(:park).id
  end

  test "map returns genre IDs for museum type" do
    result = GenreMapper.map(["museum", "point_of_interest"])

    assert_includes result, genres(:museum).id
  end

  test "map returns genre IDs for spa type" do
    result = GenreMapper.map(["spa", "point_of_interest"])

    assert_includes result, genres(:onsen).id
  end

  test "map returns genre IDs for lodging type" do
    result = GenreMapper.map(["lodging", "establishment"])

    assert_includes result, genres(:accommodation).id
  end

  test "map returns genre IDs for place_of_worship type" do
    result = GenreMapper.map(["place_of_worship", "establishment"])

    assert_includes result, genres(:shrine_temple).id
  end

  test "map returns genre IDs for shopping_mall type" do
    result = GenreMapper.map(["shopping_mall", "establishment"])

    assert_includes result, genres(:shopping).id
  end

  test "map returns genre IDs for zoo type" do
    result = GenreMapper.map(["zoo", "establishment"])

    assert_includes result, genres(:zoo_aquarium).id
  end

  test "map returns genre IDs for amusement_park type" do
    result = GenreMapper.map(["amusement_park", "establishment"])

    assert_includes result, genres(:theme_park).id
  end

  test "map returns unique genre IDs for multiple matching types" do
    result = GenreMapper.map(["restaurant", "food", "meal_takeaway"])

    assert_equal 1, result.count { |id| id == genres(:gourmet).id }
  end

  test "map returns empty array for unmappable types" do
    result = GenreMapper.map(["natural_feature", "locality"])

    assert_empty result
  end

  test "map returns empty array for blank input" do
    assert_empty GenreMapper.map(nil)
    assert_empty GenreMapper.map([])
  end

  test "mappable? returns true for mappable types" do
    assert GenreMapper.mappable?(["restaurant"])
  end

  test "mappable? returns false for unmappable types" do
    assert_not GenreMapper.mappable?(["natural_feature"])
  end

  # 観光名所（sightseeing）のフォールバック動作テスト
  test "map excludes sightseeing when more specific genre matches" do
    # 公園 + 観光名所 の場合は公園のみ
    result = GenreMapper.map(["park", "tourist_attraction"])

    assert_includes result, genres(:park).id
    assert_not_includes result, genres(:sightseeing).id
  end

  test "map returns sightseeing when no other genre matches" do
    # 観光名所のみの場合は観光名所を返す
    result = GenreMapper.map(["tourist_attraction"])

    assert_includes result, genres(:sightseeing).id
  end

  test "map excludes sightseeing with multiple specific genres" do
    # レストラン + 公園 + 観光名所 の場合は観光名所を除外
    result = GenreMapper.map(["restaurant", "park", "tourist_attraction"])

    assert_includes result, genres(:gourmet).id
    assert_includes result, genres(:park).id
    assert_not_includes result, genres(:sightseeing).id
  end
end
