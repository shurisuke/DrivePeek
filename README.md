# DrivePeek

サービスURL：https://drivepeek.onrender.com/

<img width="1200" alt="DrivePeek サービス画面" src="https://github.com/user-attachments/assets/0dd1465b-ec63-472e-8a4f-e4d1d1830a64" />

# ■ サービス概要
**3つの探し方で見つけて、計画、そのまま出発。**

DrivePeekは、地図検索・AI提案・みんなのプランの3つの方法でスポットを見つけ、滞在時間・移動時間・有料道路の有無を加味したドライブプランを作成できるアプリです。
完成したプランはそのままGoogle Mapsのナビに連携できます。


# ■ 機能紹介

## 🗺️ プラン作成
<table>
  <tr>
    <td width="50%" align="center"><strong>スポットを見つけてプランに追加</strong></td>
    <td width="50%" align="center"><strong>InfoWindow（スポット詳細）</strong></td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="https://github.com/user-attachments/assets/485cbd03-15da-4681-862f-0e00aae37b4b" alt="スポットをプランに追加" width="95%">
    </td>
    <td width="50%" align="center">
      <img src="https://github.com/user-attachments/assets/b8e971db-62c1-41d5-ba0c-0f5c9b87d119" alt="InfoWindow" width="95%">
    </td>
  </tr>
  <tr>
    <td width="50%">地図検索・コミュニティ・AI提案、好きな方法でスポットを見つけてプランに追加。<br>並び替えやスケジュール管理も自由自在です。</td>
    <td width="50%">地図マーカーをクリックするとスポット情報をその場で表示。<br>写真・ジャンル・お気に入り・コメントをまとめて確認できます。</td>
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
      <img src="https://github.com/user-attachments/assets/532f4a70-ef9d-4576-b46a-8d1c37f5805a" alt="エリア＆ジャンル選択" width="95%">
    </td>
    <td width="50%" align="center">
      <img src="https://github.com/user-attachments/assets/950735bc-411d-4282-a64c-bd7a1d1cc822" alt="AI提案結果" width="95%">
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
      <img src="https://github.com/user-attachments/assets/e060adf3-3027-45c0-9fcb-1a65d4b134cd" alt="コミュニティ検索" width="95%">
    </td>
    <td width="50%" align="center">
      <img src="https://github.com/user-attachments/assets/e7688dba-634e-41c2-b706-ed055a59a791" alt="気になるプランを地図で追体験" width="95%">
    </td>
  </tr>
  <tr>
    <td width="50%">場所・ジャンル・フリーワードで他ユーザーのプランやスポットを検索できます。</td>
    <td width="50%">プランカード・スポットカードから地図上にプレビュー表示。<br>今のルートと比べながら、寄り道先を手軽に検討できます。</td>
  </tr>
</table>

## 📱 モバイル対応 & Google Mapsナビ連携
<table>
  <tr>
    <td width="50%" align="center"><strong>モバイル対応</strong></td>
    <td width="50%" align="center"><strong>Google Mapsナビ連携</strong></td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="https://github.com/user-attachments/assets/f0629f22-8a9d-452b-9bfc-d89a7ca27a95" alt="モバイル対応" height="400">
    </td>
    <td width="50%" align="center">
      <img src="https://github.com/user-attachments/assets/4cde3215-106f-45f4-a95a-a2156e60154b" alt="ナビ連携" height="400">
    </td>
  </tr>
  <tr>
    <td width="50%">スマートフォンに最適化されたUIで、外出先でもスムーズにプラン作成・スポット探しができます。</td>
    <td width="50%">完成したプランからGoogle Mapsナビをワンタップ起動。経由地もそのまま引き継がれ、すぐに出発できます。</td>
  </tr>
</table>

## その他の機能

| 機能 | 説明 |
|------|------|
| スケジュール自動計算 | 滞在時間・移動時間を加味して予定時間を自動計算 |
| お気に入り | プラン・スポットをワンタップで保存、一覧管理 |
| メモ | スポットごとに注意点・買いたいものなどを記録 |
| SNS ログイン | LINE / X (Twitter) でワンクリック認証 |
| SNS シェア | プランを LINE / X / URL コピーで共有 |


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

## 技術選定の理由
- **Ruby on Rails**: プランやスポットの管理等、サーバー側の処理はCRUDが中心のため、規約に沿うだけで素早く実装できるRailsを選択
- **Hotwire (Turbo + Stimulus)**: Rails標準搭載のフロントエンド技術として採用。サーバー側でUI状態を管理でき、別途フレームワークなしでリアルタイムなUI更新を実現できた
- **Google Maps API**: Mapbox等と比較し、日本のスポットデータの充実度から選択

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


## ER図

<img alt="ER図" src="https://github.com/user-attachments/assets/bca35b99-5b83-4301-95f1-ab2561062052" />


## テスト

| テスト種別 | 内容 |
|-----------|------|
| Model spec | バリデーション・アソシエーション・ビジネスロジック |
| Request spec | APIエンドポイント・認証・CRUD |
| System spec | E2E（Capybara + Selenium） |
| Service spec | AI提案サービス |
| Mailer spec | メール送信 |
| **合計** | **372 examples, 0 failures** |

静的解析: RuboCop + Brakeman（セキュリティスキャン）

CI: GitHub ActionsでPRごとにRSpec・RuboCop・Brakemanを自動実行


## 画面遷移図
Figma：https://www.figma.com/design/k9Qhg0des02wxAjroLW3MA/DrivePeek-%E7%94%BB%E9%9D%A2%E9%81%B7%E7%A7%BB%E5%9B%B3-?node-id=0-1&p=f&t=Y0GH5C5Pvvhz2Ot9-0


# ■ 技術的チャレンジ

## 経路計算と時刻計算の分離

不要なAPI呼び出しを避けるため、経路計算と時刻計算を分離した。

<table>
  <tr>
    <td><strong>Plan::Route</strong></td>
    <td>スポット間の距離・移動時間を計算</td>
  </tr>
  <tr>
    <td><strong>Plan::Schedule</strong></td>
    <td>DBの移動時間を読み、到着・出発時刻を計算</td>
  </tr>
  <tr>
    <td><strong>Plan::Recalculator</strong></td>
    <td>Route → Schedule の順序を保証するオーケストレータ</td>
  </tr>
</table>

この分離により、出発時間や滞在時間の変更時は時刻計算のみ実行し、Directions APIの呼び出し回数とコストを削減。ユーザーの操作に即座に反応できる設計とした。

## AI提案の設計

当初はAIにスポット選定を全て任せていたが、ホテルやチェーン店など的外れな提案や、ハルシネーションが課題となった。

**解決策**: 責務を3層に分離し、AIの役割を「候補から文脈に合うものを選ぶ」に限定した。

<table>
  <tr>
    <td><strong>ユーザー</strong></td>
    <td>エリア描画・ジャンル選択で意図を明示</td>
  </tr>
  <tr>
    <td><strong>DB</strong></td>
    <td>お気に入り数で人気スポットに絞り込み</td>
  </tr>
  <tr>
    <td><strong>AI</strong></td>
    <td>季節やドライブ適性を考慮して選定</td>
  </tr>
</table>

これにより、真冬に海水浴場をおすすめするような的外れな提案を防ぎつつ、ユーザーは文字入力なしの簡単な操作だけで、季節に合った精度の高い提案を受けられるようになった。


# ■ サービス開発の背景
私自身、休日のドライブが大好きで日々のリフレッシュになっています。
しかし計画段階で、いつも同じ悩みにぶつかっていました。

「途中でどこか寄りたいけど、どこかいい所ないかな...」
「滞在時間を考えると、帰りは何時になるんだろう...」
「友達と計画する時、ここ行って次ここで...の共有が面倒...」

こうした **スポット探し・時間計算・プラン共有** の3つの課題を、**地図 + AI + コミュニティ** で一気に解決したいという思いから開発しました。
他のユーザーのリアルなプランを参考にしたり、AIにおまかせで提案してもらえる。スポット探しの手間をなくし、「思い立ったらすぐ出発できる」体験を目指しています。
