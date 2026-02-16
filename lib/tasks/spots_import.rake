# frozen_string_literal: true

# lib/spot_importer/ を読み込み
Dir[Rails.root.join("lib/spot_importer/**/*.rb")].each { |f| require f }

namespace :spots do
  desc "関東圏のスポットを一括取得"
  task import_kanto: :environment do
    importer = SpotImporter::KantoImporter.new
    importer.run
  end

  desc "テスト用: 1グリッド分だけ取得"
  task import_test: :environment do
    importer = SpotImporter::KantoImporter.new
    importer.run(test_mode: true)
  end

  desc "グルメスポットにAIでジャンル判定"
  task detect_gourmet_genres: :environment do
    spots = Spot.left_joins(:spot_genres).where(spot_genres: { id: nil })
    total = spots.count

    puts "ジャンル未設定スポット: #{total}件"

    spots.find_each.with_index(1) do |spot, index|
      print "\r[#{index}/#{total}] #{spot.name.truncate(30)}"
      spot.detect_genres!
      sleep(0.1)
    end

    puts "\n完了"
  end
end
