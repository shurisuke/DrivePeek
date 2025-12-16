# Issue-40: 検索ピンの InfoWindow 実装 + 「プランに追加」保存フロー

## 目的 (Why)
検索結果のピンをクリックしたときに InfoWindow を表示し、ユーザーが「プランに追加」できるようにする。
追加時に Spot / PlanSpot / UserSpot / Tags / UserSpotTags を一貫して保存し、DrivePeek のドメインに沿ったデータ整合性を保つ。

## 完成条件 (Acceptance Criteria)

### A. InfoWindow 表示（検索ピン押下）
- [ ] 画像が表示される（なければ表示しない）
- [ ] 住所が表示される（formatted_address 等）
- [ ] 「プランに追加」ボタンが表示される（見た目は既存レイアウトを使用）
- [ ] InfoWindow 内ボタン押下が確実に拾える（動的DOMなのでイベント付与方式に注意）

### B. 「プランに追加」押下時の挙動（JS -> Rails）
- [ ] JSからRailsへ、以下を送信する
  - name（あれば）
  - address（整形済み）
  - lat / lng
  - place_id
  - prefecture / city（可能なら。難しければ一旦Rails側で逆ジオコーディングしても良い）
  - photo_reference（あれば）
  - top_types（Googleのplace typesから関連度が高いもの最大3つ）
- [ ] 通信は `POST plan_spots#create` を叩く（JSON送信）
- [ ] 成功時：UI側で「追加できた」状態に更新できる（最低限はconsole/logでもOK。UIは別Issueでも可）
- [ ] 失敗時：エラーをユーザーにわかる形で出す（最低限alertでも可）

### C. Rails 側の保存（plan_spots#create → SpotSetupService#setup）
- [ ] `PlanSpotsController#create` は薄く保つ（パラメータ抽出、現在のplan/user決定、サービス呼び出し、レスポンス）
- [ ] `SpotSetupService#setup` は「調整役」に徹し、実保存ロジックはモデルに寄せる

#### 保存要件（トランザクション）
- [ ] Spot:
  - place_id で検索して存在すれば再利用、なければ作成
  - 保存するカラム：
    - name（店名/場所名があれば）
    - address（整形済み）
    - lat / lng
    - place_id
    - prefecture / city
    - photo_reference
- [ ] PlanSpot:
  - 現在のplanに紐づけて作成
  - `toll_used` はデフォルト false（推奨：DB default + model validation）
  - `position` はプラン内で最後になるように付与（既に acts_as_list を使っているならそれに従う。未導入なら最大値+1で明示）
- [ ] UserSpot:
  - current_user と Spot の組み合わせがあれば再利用、なければ作成
- [ ] Tags / UserSpotTags:
  - top_types（最大3）を上から順に処理
  - Tag は存在確認してなければ作成
  - UserSpotTag を作成し関連付ける

## 実装方針（責務分離）
- Spot: `Spot.find_or_initialize_by(place_id:)` まではOK。ただし「更新許可する属性」と「保存」は Spot 側のメソッドに寄せる
  - 例：`spot.apply_google_payload(payload)` のようなモデルメソッド
- PlanSpot: position 付与やデフォルトは model / concern / callback に寄せる（controllerやserviceにロジックを溜めない）
- UserSpot: `UserSpot.find_or_create_by(user:, spot:)`
- Tag: `Tag.find_or_create_by(tag_name:)`（カラム名は実スキーマに合わせる）
- SpotSetupService: ルーティング（順序制御、transaction、例外処理）に限定

## 関連ファイル候補（Exploreで確認）
### Frontend (JS)
- app/javascript/map/search_box.js（検索結果ピン生成/クリック処理）
- app/javascript/map/state.js（marker管理ルール）
- app/javascript/map/*（InfoWindow生成がどこか）
- app/javascript/plans/init_map.js（turbo:loadの入口）

### Rails
- app/controllers/plan_spots_controller.rb
- app/models/spot.rb, plan_spot.rb, user_spot.rb, tag.rb, user_spot_tag.rb
- app/services/spot_setup_service.rb（新規作成 or 既存更新）
- config/routes.rb（plan_spots#create のルート）
- db/schema.rb（正確なカラム名・制約の確認）

## API設計（案）
- POST /plans/:plan_id/plan_spots もしくは /plan_spots
- params例:
  - plan_spot: { place_id, name, address, lat, lng, prefecture, city, photo_reference, top_types: [] }

## エラーハンドリング方針
- 例外は transaction をロールバック
- controller は JSON で成功/失敗を返す
  - success: { plan_spot_id, spot_id }
  - error: { message, details }

## 注意
- 要件の「緯度/経度をspotテーブルにnameとして保存」は誤記とみなし、lat/lngとして保存する。
- 既存のレイアウトは壊さない。ロジックのみ追加する。