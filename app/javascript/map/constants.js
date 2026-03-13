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

// ================================================================
// グラデーションカラー（円・ピン用）
// - outer: 外側（薄め）
// - mid: 中間
// - inner: 内側（濃いめ）
// ================================================================
export const GRADIENTS = {
  SUGGESTION: {
    outer: "#764ba2",
    mid: "#7164c0",
    inner: "#667eea"
  },
  COMMUNITY: {
    outer: "#1565C0",
    mid: "#1E88E5",
    inner: "#42A5F5"
  }
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
 * エリア選択円のスタイル（影 + グラデーション3層）
 */
export const AREA_CIRCLE_STYLES = {
  shadow: { offset: 20, color: "#000", weight: 12, opacity: 0.08 },
  suggestion: [
    { offset: 8, color: GRADIENTS.SUGGESTION.outer, opacity: 0.3 },
    { offset: 4, color: GRADIENTS.SUGGESTION.mid, opacity: 0.5 },
    { offset: 0, color: GRADIENTS.SUGGESTION.inner, opacity: 0.9 }
  ],
  community: [
    { offset: 8, color: GRADIENTS.COMMUNITY.outer, opacity: 0.3 },
    { offset: 4, color: GRADIENTS.COMMUNITY.mid, opacity: 0.5 },
    { offset: 0, color: GRADIENTS.COMMUNITY.inner, opacity: 0.9 }
  ]
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
          <stop offset="0%" style="stop-color:${GRADIENTS.SUGGESTION.inner}"/>
          <stop offset="100%" style="stop-color:${GRADIENTS.SUGGESTION.outer}"/>
        </linearGradient>
      </defs>
      <circle cx="18" cy="18" r="17" fill="url(#suggestionGradient)"/>
      <text x="18" y="25" text-anchor="middle" fill="white" font-size="19" font-weight="600" font-family="system-ui, -apple-system, sans-serif">${number}</text>
    </svg>
  `.trim()
  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`
}
