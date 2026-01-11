// app/javascript/map/constants.js
//
// ================================================================
// Map Constants（定数）
// 用途: 地図関連の共通定数
// ================================================================

// ================================================================
// カラーパレット
// - MY_PLAN: 自分のプラン（最も目立つ）
// - COMMUNITY: コミュニティプラン/スポットプレビュー（控えめ）
// ================================================================
export const COLORS = {
  MY_PLAN: "#EF6C00",       // ダークイエローオレンジ（自分のプラン）
  COMMUNITY: "#3073F0",     // ブルー（コミュニティ）
  CURRENT_LOCATION: "#506d53", // パーソナルカラー（現在地）
}

/**
 * 経路ポリラインのスタイル（自分のプラン用）
 */
export const ROUTE_POLYLINE_STYLE = {
  strokeColor: COLORS.MY_PLAN,
  strokeOpacity: 0.85,
  strokeWeight: 4,
}

/**
 * 経路ポリラインのスタイル（コミュニティプラン用）
 */
export const COMMUNITY_ROUTE_STYLE = {
  strokeColor: COLORS.COMMUNITY,
  strokeOpacity: 0.7,
  strokeWeight: 4,
}
