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
end
