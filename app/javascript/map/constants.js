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
  SUGGESTION: "#9333EA",    // パープル（提案）
}

/**
 * 経路ポリラインのスタイル（自分のプラン用）
 */
export const ROUTE_POLYLINE_STYLE = {
  strokeColor: COLORS.MY_PLAN,
  strokeOpacity: 0.85,
  strokeWeight: 4,
  zIndex: 1,
}

/**
 * 経路ポリラインのスタイル（コミュニティプラン用）
 */
export const COMMUNITY_ROUTE_STYLE = {
  strokeColor: COLORS.COMMUNITY,
  strokeOpacity: 0.7,
  strokeWeight: 4,
  zIndex: 1,
}

/**
 * 提案スポット用のグラデーションピンSVGを生成
 * @param {number} number - ピンに表示する番号
 * @returns {string} data URI形式のSVG
 */
export const createSuggestionPinSvg = (number) => {
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
      <defs>
        <linearGradient id="suggestionGradient" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style="stop-color:#667eea"/>
          <stop offset="100%" style="stop-color:#764ba2"/>
        </linearGradient>
      </defs>
      <circle cx="18" cy="18" r="17" fill="url(#suggestionGradient)"/>
      <text x="18" y="24" text-anchor="middle" fill="white" font-size="16" font-weight="bold" font-family="sans-serif">${number}</text>
    </svg>
  `.trim()
  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`
}
