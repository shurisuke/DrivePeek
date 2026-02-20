# DrivePeek

サービスURL：https://drivepeek.app/

<img width="1200" alt="DrivePeek サービス画面" src="https://github.com/user-attachments/assets/0dd1465b-ec63-472e-8a4f-e4d1d1830a64" />


<br>


# ■ サービス概要

DrivePeekは、地図探索・AI提案・みんなのプランの3つの方法でスポットを見つけ、
**ドライブプランを作成・共有できるアプリです。**

近くを旅した人のプランを参考にしたり、
友達とのドライブ計画をURLひとつで共有したり。
完成したらGoogle Mapsナビでそのまま出発できます。


<br>


# ■ 機能紹介

## 🗺️ プラン作成
<table>
  <tr>
    <td width="50%" align="center"><strong>スポットを見つけてプランに追加</strong></td>
    <td width="50%" align="center"><strong>盛り上がりスポット表示</strong></td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="https://github.com/user-attachments/assets/d86422a9-d6c6-4097-b65d-eaeef1dbcb4b" width="200" alt="スポットを見つけてプランに追加">
    </td>
    <td width="50%" align="center">
      <img src="https://github.com/user-attachments/assets/910521c7-c047-4273-b2ac-d6baf2a81c40" width="200" alt="盛り上がりスポット">
    </td>
  </tr>
  <tr>
    <td width="50%">地図検索・コミュニティ・AI提案、好きな方法でスポットを見つけてプランに追加。<br>マーカーをタップすれば写真・ジャンル・コメントをその場で確認できます。</td>
    <td width="50%">ワンタップで周辺の人気スポットを表示。<br>ユーザーのお気に入り数が多い場所だけを、ジャンルアイコンでわかりやすく地図上に表示します。</td>
  </tr>
</table>


## 🤖 AI スポット提案
<table>
  <tr>
    <td width="50%" align="center"><strong>エリア＆ジャンルを選ぶだけ</strong></td>
    <td width="50%" align="center"><strong>提案プランは一括採用可能</strong></td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="https://github.com/user-attachments/assets/0ccefb3e-a1ef-4665-8a72-3c1cb7914eea" width="200" alt="AI提案フロー">
    </td>
    <td width="50%" align="center">
      <img src="https://github.com/user-attachments/assets/3c37b35c-94f2-464e-945e-9a84187fc665" width="200" alt="プラン一括採用">
    </td>
  </tr>
  <tr>
    <td width="50%">地図上で指をなぞってエリアを囲み、食事・観光などのジャンルを選択。<br>文字入力なしでAIに提案をおまかせできます。</td>
    <td width="50%">AIが提案したプランは、気に入ったらワンタップで一括採用。<br>スポット単体での追加も可能です。</td>
  </tr>
</table>

## 🌐 コミュニティ
<table>
  <tr>
    <td width="50%" align="center"><strong>プラン・スポット検索</strong></td>
    <td width="50%" align="center"><strong>気になるプランを地図で追体験</strong></td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="https://github.com/user-attachments/assets/194b079e-04f4-4b70-a17e-34bc1fe5b5dc" width="200" alt="プラン・スポット検索">
    </td>
    <td width="50%" align="center">
      <img src="https://github.com/user-attachments/assets/68391ecd-9cd8-4c2a-962c-f90416754980" width="200" alt="気になるプランを地図で追体験">
    </td>
  </tr>
  <tr>
    <td width="50%">場所・ジャンル・フリーワードで他ユーザーのプランやスポットを検索できます。</td>
    <td width="50%">プランカード・スポットカードから地図上にプレビュー表示。<br>今のルートと比べながら、寄り道先を手軽に検討できます。</td>
  </tr>
</table>


<br>


## その他の機能

| 機能 | 説明 |
|------|------|
| プランコピー | 他ユーザーのプランを自分用に複製して編集可能 |
| スケジュール自動計算 | 滞在時間・移動時間を加味して予定時間を自動計算 |
| Google Mapsナビ連携 | 完成プランからワンタップでナビ起動、経由地もそのまま |
| SNS ログイン | LINE / X (Twitter) でワンクリック認証 |
| SNS シェア | プランを LINE / X / URL コピーで共有 |
| お気に入り | プラン・スポットをワンタップで保存、一覧管理 |
| メモ | スポットごとに注意点・買いたいものなどを記録 |
| コメント | スポットに感想・口コミを投稿・閲覧 |


<br>


# ■ 技術構成について

## 使用技術
| カテゴリ | 技術・ツール |
|---------|-------------|
| **バックエンド** | Ruby 3.2.2 / Ruby on Rails 8.1 |
| **フロントエンド** | Hotwire (Turbo + Stimulus) / Importmap / JavaScript |
| **UI/CSS** | Bootstrap 5 / SCSS (cssbundling-rails) |
| **データベース** | PostgreSQL |
| **認証** | Devise / OmniAuth (LINE / X) |
| **AI** | OpenAI API (ruby-openai) |
| **地図** | Google Maps JavaScript API / Places API / Directions API |
| **インフラ・デプロイ** | Render |
| **CI/CD** | GitHub Actions (RSpec / RuboCop / Brakeman) |
| **テスト** | RSpec / Factory Bot / Capybara / SimpleCov |
| **その他** | Kaminari (ページネーション) / Rack::Attack (レート制限) / Resend (メール) / Kramdown (Markdown) / Flatpickr (日時入力) / Solid Queue (ジョブ) / Solid Cache (キャッシュ) |


<br>


## 技術選定の理由
- **Ruby on Rails**: プランやスポットの管理等、サーバー側の処理はCRUDが中心のため、規約に沿うだけで素早く実装できるRailsを選択
- **Hotwire (Turbo + Stimulus)**: 地図操作など複雑なUIが必要な箇所はStimulusで対応しつつ、それ以外はTurboによるサーバー主導でJSを最小化。React/Vue等を導入せず、必要な複雑さだけに限定した
- **Google Maps API**: Mapbox等と比較し、日本のスポットデータの充実度から選択


<br>


## Stimulus コントローラ構成

機能ドメインごとにディレクトリを分割し、責務を明確化。

```
app/javascript/controllers/
├── plan_tab/          # プランタブ（スポット操作・時間管理）
├── community_tab/     # コミュニティタブ（検索・プレビュー）
├── suggestion_tab/    # AI提案タブ（エリア指定・プラン採用）
├── infowindow/        # InfoWindow（スポット詳細・コメント・写真）
└── ui/                # 汎用 UI（BottomSheet・ナビバー・モーダル等）
```

**設計方針**: サーバーがUI状態を決定し、Stimulusは表示制御・API通信に徹する。機能ドメインごとにディレクトリを分け、横断UIは `ui/` に集約。


<br>


## ER図

<img width="1634" height="845" alt="Image" src="https://github.com/user-attachments/assets/e56b97f9-e82e-402c-a64d-bb7387a7b62b" />


<br>


## テスト

| テスト種別 | 内容 |
|-----------|------|
| Model spec | バリデーション・アソシエーション・ビジネスロジック |
| Request spec | APIエンドポイント・認証・CRUD |
| System spec | E2E（Capybara + Selenium） |
| Service spec | AI提案サービス |
| Mailer spec | メール送信 |

**652 examples, 0 failures / カバレッジ 98.26%**

静的解析: RuboCop + Brakeman（セキュリティスキャン）
CI: GitHub ActionsでPRごとにRSpec・RuboCop・Brakemanを自動実行


<br>


## 画面遷移図
Figma：https://www.figma.com/design/k9Qhg0des02wxAjroLW3MA/DrivePeek-%E7%94%BB%E9%9D%A2%E9%81%B7%E7%A7%BB%E5%9B%B3-?node-id=0-1&p=f&t=Y0GH5C5Pvvhz2Ot9-0


<br>


# ■ 技術的チャレンジ

1. AI提案の3層分離設計
2. 経路計算と時刻計算の分離


<br>


## AI提案の3層分離設計

AIにスポット選定を丸投げしていた設計を、3層に分離しました。

| | Before | After |
|--|--------|-------|
| **絞り込み** | 地図の表示位置から | エリアを描画して選択、ジャンルは任意で指定 |
| **候補選定** | DBでランダムに選出 | DBがノイズとなるスポットをジャンルごとに除外。<br>描画エリア内のスポットをお気に入り数順で選出。|
| **最終判断** | AIが主観的に選定 | AIは季節・ドライブ適性のみを考慮し選定 |

**Before**: ホテルやコンビニなど的外れな提案、ハルシネーションが発生

**After**: ユーザーが意図を伝え、DBがノイズを除き、AIが文脈を読む。各層に適した役割を与えることで精度が向上。

<br>

## 経路計算と時刻計算の分離

不要なAPI呼び出しを避けるため、経路計算と時刻計算を分離しました。

| クラス | 責務 |
|--------|------|
| Plan::Recalculator | DrivingとTimetableを使い分ける指揮役 |
| Plan::Driving | スポット間の距離・移動時間を取得（API呼び出し） |
| Plan::Timetable | DBの移動時間を読み、到着・出発時刻を計算 |

```ruby
# Plan::Recalculatorの中身（指揮役）
# route: true  → 経路再計算（API呼び出し）+ 時刻再計算
# route: false → 時刻再計算のみ（APIなし）

class Plan::Recalculator
  def recalculate!(route: false, schedule: true)
    Plan::Driving.new(plan).recalculate! if route      # API呼び出し
    Plan::Timetable.new(plan).recalculate! if schedule # DB内で完結
  end
end
```

この分離により、Directions APIの呼び出し回数とコストを削減。ユーザーの操作へ即座に反応できる設計を意識しました。

<br>

# ■ サービス開発の背景

### 行きたい場所の"その先"が見つからない

外出を計画するたびに、一番行きたい場所はすぐ決まるのに、
その近くの素敵なスポットや飲食店を探すのに迷うことが何度かありました。

この「探す時間」を短縮したいと思い、開発を始めました。

---

### スムーズにドライブ計画を共有したい

友達と計画を立てる時、
「ここ行って、次ここで、そのあとここに寄って…」と文章で説明するのは意外と大変です。

地図アプリで場所を共有することはできても、
「複数スポット＋ルート＋スケジュール感」をまとめて送れるツールはまだ多くありません。

URLひとつでプラン全体を共有できて、
友達も同じツールで一緒に探せたら便利なのではないか。
そう感じたことも、開発の動機の一つです。
