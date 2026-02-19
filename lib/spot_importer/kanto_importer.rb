# frozen_string_literal: true

module SpotImporter
  # 関東圏のスポットを一括取得・登録
  #
  # 使い方:
  #   importer = SpotImporter::KantoImporter.new
  #   importer.run              # 全グリッド実行
  #   importer.run(test_mode: true)  # テストモード（1グリッドのみ）
  #
  class KantoImporter
    # 検索ジャンルの定義
    # query: Google Text Search用のクエリ
    # genre_slug: 紐付けるジャンルのslug（nilの場合はAI判定）
    SEARCH_GENRES = [
      { query: "グルメ 飲食店", genre_slug: "food" },
      { query: "カフェ スイーツ", genre_slug: "sweets_cafe" },
      { query: "観光名所", genre_slug: "sightseeing" },
      { query: "文化財", genre_slug: "cultural_property" },
      { query: "夜景スポット", genre_slug: "night_view" },
      { query: "城", genre_slug: "castle" },
      { query: "絶景", genre_slug: "scenic_view" },
      { query: "美術館 博物館", genre_slug: "museum_category" },
      { query: "神社 寺", genre_slug: "shrine_temple" },
      { query: "道の駅 サービスエリア パーキングエリア", genre_slug: "roadside_station" },
      { query: "温泉", genre_slug: "bath" },
      { query: "テーマパーク 遊園地", genre_slug: "theme_park" }
    ].freeze

    # 検索半径（メートル）
    SEARCH_RADIUS = 5000

    def initialize
      @stats = { grids: 0, requests: 0, spots_created: 0, spots_skipped: 0, errors: 0 }
      @genre_cache = {}
    end

    # メイン実行
    # @param test_mode [Boolean] trueの場合、1グリッドのみ実行
    def run(test_mode: false)
      grids = test_mode ? GridGenerator.test_grids : GridGenerator.kanto_grids
      total_grids = grids.size
      total_requests = total_grids * SEARCH_GENRES.size

      puts "=" * 60
      puts "関東圏スポット一括取得"
      puts "=" * 60
      puts "グリッド数: #{total_grids}"
      puts "ジャンル数: #{SEARCH_GENRES.size}"
      puts "総リクエスト数: #{total_requests}"
      puts "=" * 60

      grids.each.with_index(1) do |grid, grid_index|
        process_grid(grid, grid_index, total_grids)
        @stats[:grids] += 1
      end

      print_summary
    end

    private

    def process_grid(grid, grid_index, total_grids)
      SEARCH_GENRES.each do |genre_config|
        process_search(grid, genre_config, grid_index, total_grids)
        @stats[:requests] += 1

        # API制限対策: 少し待機
        sleep(0.1)
      end
    end

    def process_search(grid, genre_config, grid_index, total_grids)
      query = genre_config[:query]
      genre_slug = genre_config[:genre_slug]

      print "\r[#{grid_index}/#{total_grids}] #{grid[:lat]}, #{grid[:lng]} - #{query.ljust(20)}"

      results = fetch_with_retry(query, grid)

      results.each do |result|
        save_spot(result, genre_slug)
      end
    rescue StandardError => e
      @stats[:errors] += 1
      puts "\nError at grid #{grid_index}: #{e.message}"
    end

    # リトライ付きAPI呼び出し（最大3回、指数バックオフ）
    def fetch_with_retry(query, grid, max_retries: 3)
      retries = 0
      begin
        GoogleApi::Places.text_search(
          query,
          lat: grid[:lat],
          lng: grid[:lng],
          radius: SEARCH_RADIUS
        )
      rescue StandardError => e
        retries += 1
        if retries <= max_retries
          sleep_time = 2**retries # 2, 4, 8秒
          puts "\n  Retry #{retries}/#{max_retries} after #{sleep_time}s: #{e.message}"
          sleep(sleep_time)
          retry
        else
          raise e
        end
      end
    end

    def save_spot(result, genre_slug)
      # place_idで既存チェック
      spot = Spot.find_by(place_id: result[:place_id])

      if spot
        # 既存スポットにジャンルを追加
        assign_genre(spot, genre_slug) if genre_slug
        @stats[:spots_skipped] += 1
        return
      end

      # 住所を解析
      address_parts = AddressParser.parse(result[:address])

      # 新規スポットを作成（コールバックをスキップしてGeocoding API呼び出しを防止）
      attributes = {
        place_id: result[:place_id],
        name: result[:name],
        address: result[:address],
        lat: result[:lat],
        lng: result[:lng],
        prefecture: address_parts[:prefecture],
        city: address_parts[:city],
        town: address_parts[:town],
        created_at: Time.current,
        updated_at: Time.current
      }

      # バリデーション用の一時オブジェクト
      temp_spot = Spot.new(attributes.except(:created_at, :updated_at))

      if temp_spot.valid?
        # insert でコールバックをスキップして挿入
        Spot.insert(attributes)
        # 挿入したスポットを再取得してジャンル紐付け
        spot = Spot.find_by(place_id: result[:place_id])
        assign_genre(spot, genre_slug) if spot
        @stats[:spots_created] += 1
      else
        @stats[:errors] += 1
        puts "\nValidation error: #{temp_spot.errors.full_messages.join(', ')}"
      end
    end

    def assign_genre(spot, genre_slug)
      return if genre_slug.nil?  # AI判定は後で別途実行

      genre = find_genre(genre_slug)
      return unless genre

      spot.spot_genres.find_or_create_by!(genre_id: genre.id)
    rescue ActiveRecord::RecordInvalid
      # 既に紐付いている場合は無視
    end

    def find_genre(slug)
      @genre_cache[slug] ||= Genre.find_by(slug: slug)
    end

    def print_summary
      puts "\n"
      puts "=" * 60
      puts "完了"
      puts "=" * 60
      puts "処理グリッド数: #{@stats[:grids]}"
      puts "APIリクエスト数: #{@stats[:requests]}"
      puts "新規スポット数: #{@stats[:spots_created]}"
      puts "スキップ数: #{@stats[:spots_skipped]}"
      puts "エラー数: #{@stats[:errors]}"
      puts "=" * 60
    end
  end
end
