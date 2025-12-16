# SortableJSでスポットブロック並び替えを実装して（DrivePeek）

## ゴール（やりたいこと）
プラン作成/編集画面（左のplanbar内「プラン」タブ）で表示している spot_block を、ドラッグ&ドロップで並び替えできるようにしてください。
並び替え結果は DB（plan_spots.position）に保存し、画面（planbar）にも即反映されるようにしてください。

前提：planbar は Turbo Frame 化されており、plan:spot-added で planbar を turbo-stream で更新できる状態です（既存の planbar_updater.js / planbars#show を流用可）。

---

## 対象HTML（ドラッグ対象）
ドラッグ対象は app/views/plans/form_components/_spot_block.html.erb の最外側 .spot-block です。

<div
  class="spot-block"
  data-spot-id="<%= spot.id %>"
  data-plan-spot-id="<%= plan_spot.id %>"
  data-position="<%= plan_spot.position %>"
  data-user-spot-id="<%= user_spot&.id %>"
>
...
</div>

---

## 期待するUX
- spot-block をドラッグして並び替えできる
- 並び替え後に自動で保存（AJAX/Fetch）
- 保存に成功したら planbar を再描画（Turbo Streamで planbar フレームだけ更新）
- 保存に失敗したら UI を元に戻す（またはエラー表示して再読み込み）

---

## 実装方針（要件）

### 1) SortableJS導入
- Importmap を使っている想定です（現状 importmap.rb で pin_all_from があり、ESM import をしている構成）
- SortableJS を importmap で pin して、JSモジュールから Sortable を使えるようにしてください

### 2) ドラッグできる範囲（誤操作防止）
- .spot-block 自体をドラッグ対象にしつつ、誤操作防止で「ドラッグハンドル」を追加してください
  - 例：.spot-order-pin をドラッグハンドルにする（ここだけ掴んで動かせる）
- collapse の開閉ボタン .detail-toggle を押したときはドラッグにならないようにしてください

### 3) 並び順保存API
- PlanSpot は acts_as_list scope: :plan を使用している前提
- 並び替え後、plan_spot_id の並び順（配列）をサーバーへ送信して position を更新してください
- 例：PATCH /plans/:plan_id/plan_spots/reorder のような専用エンドポイントを追加
- Controller は薄く、更新はトランザクションでまとめて安全に

リクエスト例（JSON）:
{
  "ordered_plan_spot_ids": [12, 9, 15, 20]
}

レスポンス：
- 成功: 204 もしくは 200
- 失敗: 422 JSON（message / details）

### 4) planbar再描画
- 並び順保存成功後に plan:spots-reordered の CustomEvent を発火
- planbar_updater 側でこのイベントも購読して refreshPlanbar() を呼ぶ（既存の仕組みを拡張）

### 5) Turbo遷移での二重バインド対策
- 既存の bindXxx() と同様、removeEventListener -> addEventListener で冪等にしてください
- Sortable 初期化も turbo 遷移で二重にインスタンスが作られないよう、ガードを入れてください
  - 例：container に data-sortable-initialized="true" を付ける等

---

## どこをドラッグ対象のコンテナにするか
planbar の「プランタブ」内で spot_block が描画されている箇所はこのあたりです：

<%= render "plans/form_components/start_point_block" %>

<% user_spots_by_spot_id =
     current_user.user_spots
       .includes(user_spot_tags: :tag)
       .where(spot_id: @plan.plan_spots.select(:spot_id))
       .index_by(&:spot_id)
%>

<% @plan.plan_spots.includes(:spot).order(:position).each do |plan_spot| %>
  <% user_spot = user_spots_by_spot_id[plan_spot.spot_id] %>

  <%= render "plans/form_components/spot_block",
             plan_spot: plan_spot,
             user_spot: user_spot %>
<% end %>

この spot_block 群をラップする要素（例：<div id="plan-spots-list">）を追加し、Sortable の対象コンテナにしてください。

---

## 追加してほしいIssue（3点セット）
以下の形式で GitHub Issue を作ってください。

### Issue名
Feature: SortableJSでプラン内スポットの並び替え（#XX）

### Issueの目的
- ユーザーがスポット順を直感的に入れ替えられるようにする
- position をDBに保持し、再読み込みしても順序が維持される

### 作業項目（チェックリスト）
- [ ] SortableJS を importmap で導入（pin追加）
- [ ] planbar のプランタブに並び替え対象コンテナを追加
- [ ] spot_block にドラッグハンドルUI追加（誤操作防止）
- [ ] Sortable 初期化JS作成（turbo対応、二重バインド防止）
- [ ] 並び順保存用 route/controller 作成
- [ ] 保存成功後に planbar を Turbo Stream で再描画
- [ ] 保存失敗時の挙動（元に戻す/通知）実装
- [ ] 手動テスト手順をREADME or コメントで残す

---

## 実装フロー（順番）
1. importmap に SortableJS を pin
2. planbar プランタブに「sortable対象コンテナ」を追加
3. spot_block にドラッグハンドルを追加（CSS/見た目は最低限でOK）
4. app/javascript/plans/spot_reorder_handler.js を新規作成
   - Sortable 初期化
   - onEnd で ordered ids を収集して fetch(PATCH)
   - 成功で plan:spots-reordered 発火
5. planbar_updater.js を拡張
   - plan:spot-added に加えて plan:spots-reordered でも refreshPlanbar する
6. Rails 側に reorder エンドポイントを追加
   - routes
   - PlanSpotsController に reorder を追加（または専用Controller）
   - トランザクションで position 更新
7. 動作確認
   - 並び替え→保存→planbar更新（spot-order-pin の数字も更新される）まで確認

---

## 注意
- Service オブジェクトは増やさない（RailsらしくController + Modelで）
- Controller は薄く、更新処理はできるだけモデルの責務に寄せる（ただし複数行更新なので transaction は使う）
- 既存のイベント設計（CustomEvent）と Turbo Frame 更新の流れを崩さない

---

## 最終成果物（期待する変更ファイル例）
- config/importmap.rb（Sortable pin）
- app/views/plans/form_components/_planbar.html.erb（または該当部分）（sortable container追加）
- app/views/plans/form_components/_spot_block.html.erb（ハンドル追加）
- app/javascript/plans/spot_reorder_handler.js（新規）
- app/javascript/plans/init_map.js（bindSpotReorderHandler を起動）
- app/javascript/plans/planbar_updater.js（event追加）
- config/routes.rb（reorder route）
- app/controllers/plan_spots_controller.rb（reorder action）
（必要に応じてCSS）

以上をこの方針で実装してください。