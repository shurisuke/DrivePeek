## 依頼: plan_spot削除（Turbo Stream remove + planbar再描画 + ピン差し直し）

RSpec等の自動テストは不要。代わりに手動テストを必ず実施して確認してください。

### 削除ボタンの要件（重要）
- 削除ボタンは Turbo で送信する
- サーバーは Turbo Stream を返し、対象の spot-block を `remove` する（DOMから消す）
  - spot-block は `turbo_frame_tag dom_id(plan_spot)` などで「removeできるtarget」を用意する

### planbar再描画
- 既存の `app/javascript/plans/planbar_updater.js` を使う
- `plan:spot-deleted` イベントを新規に購読し、削除成功時に `refreshPlanbar(planId)` が走るようにする
  - `bindPlanbarRefresh()` に `plan:spot-deleted` のリスナーを追加

### ピン差し直し（スポットマーカー）
- planbar差し替え後に「最新DOM/最新planData」を正としてピンを作り直す
- `map/state.js` の
  - `clearPlanSpotMarkers()`
  - `setPlanSpotMarkers(markers)`
  を必ず使う（全消し→再生成→保存）
- 既存の `renderPlanMarkers(planData)` が使えるならそれでOK
  - ただし、削除後の最新 planData を取得してから実行する（`getPlanDataFromPage()` など）
- 実行タイミングは「planbar更新が完了してDOMが落ち着いた後」にする
  - 例: `planbar:updated` / `map:route-updated` をフックして実行

### positionについて
- plan_spot.position は acts_as_list に任せてOK（削除後の詰めはRails側で担保）
- ただしUIの番号/ピン番号は再描画 or 再生成で必ず追従させること

### 将来要件（今回は実装しない）
- 経路再計算、経路再描画、時間再計算→保存→planbar再描画
- TODOコメントで残すのみ

### 手動テスト（必ず実施）
- スポットを複数追加し、真ん中を削除して一覧から消える
- planbarが更新され、開いていたcollapse/スクロール位置が復元される
- 地図ピンが残スポット数に一致し、番号が1..Nで詰まる
- 連続削除でも壊れない