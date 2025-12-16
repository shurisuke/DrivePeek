# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this repository.

## 不変の前提 / ルール（必ず守る）

### Railsの思想
- Railsの規約に従い、シンプルで明示的な実装を優先する。
- コントローラは薄く保ち、ドメインロジックはモデル（または小さな調整役）に寄せ、責務を明確に分離する。
- 「巨大Service（god service）」は避ける。調整役が必要な場合も、役割は順序制御 + transaction に限定し、実ロジックは各モデルに持たせる。
- `Service#call` パターンは禁止。必要なら意図が伝わるメソッド名（例：`#setup`）を使う。

### Map / Marker の状態管理ルール
- マーカーの生成・クリアは必ず `app/javascript/map/state.js` の setter / clearer 経由で行う。
- state モジュールの外にマーカー参照を保持しない（迷子の参照を作らない）。

### Turbo / Stimulus ルール
- Map の初期化は `DOMContentLoaded` ではなく `turbo:load` で行う。
- InfoWindow のDOMは動的に生成されるため、イベント付与はイベントデリゲーション等で確実に拾う。

### 命名 / データ受け渡し（JS ↔ Rails）契約
- 「スポットをプランに追加」する際、JS → Rails へ送るpayloadは以下：
  - name（任意）
  - address（整形済み）
  - lat, lng
  - place_id
  - photo_reference（任意）
  - top_types（配列、最大3件：Googleのplace types）
- PlanSpot のデフォルト:
  - `toll_used` は DB default `false`（null:false）
  - `position` は acts_as_list により plan 単位で末尾に追加される

---

## プロジェクト概要
DrivePeekは、Google Maps連携を活用した日本語のドライブプランニングWebアプリケーションです。
ユーザーはスポットを検索し、複数の立ち寄り地点を含むルートを計画できます。
移動時間・距離の自動計算機能があり、プランを公開して他ユーザーと共有することも可能です。

主な機能:
- Google Mapsでスポット検索・追加
- 出発時間と滞在時間から帰宅時間を自動計算
- 他ユーザーのプランを参考にできる
- プライバシー保護（出発地・帰宅地は非公開）

## 開発コマンド
```bash
# 開発サーバー起動（Rails + CSS監視）
foreman start -f Procfile.dev

# 個別に起動する場合:
bin/rails server -p 3000
yarn run watch:css

# データベース
bin/rails db:create db:migrate

# CSS手動ビルド
yarn run build:css

# テスト
bin/rails test
bin/rails test test/models
bin/rails test test/path/to_test.rb:LINE

# コード品質
rubocop
brakeman
bundler-audit