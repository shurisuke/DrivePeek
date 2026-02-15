// app/javascript/map/state.js
// ================================================================
// Map State（単一責務）
// 用途: Google Maps の map インスタンスと、用途別に分けた参照（marker / polyline）を保持する。
//       描画側は「作る」だけ、参照の差し替え・クリアはこの state に集約する。
// 補足:
//   - 参照を state 外に保持しない（重複描画・消し忘れ防止）
//   - set* は必ず対応する clear* を先に呼び、常に最新参照だけを保持する
//   - 管理対象: currentLocation / startPoint / endPoint / planSpotMarkers / searchHitMarkers / routePolylines
// ================================================================

let map = null;

// --- マーカー状態（用途別に分離） ---
let currentLocationMarker = null; // 現在地（単体）
let startPointMarker = null;      // 出発地点（単体）
let endPointMarker = null;        // 帰宅地点（単体）
let planSpotMarkers = [];         // プラン内スポット（配列）
let searchHitMarkers = [];        // 検索ヒット（配列）
let routePolylines = [];          // 経路ポリライン（配列）

// --- コミュニティプランプレビュー用 ---
let communityPreviewMarkers = [];   // コミュニティプランのスポット（配列）
let communityPreviewPolylines = []; // コミュニティプランの経路（配列）

// --- 単一スポットピン（カード・スポット詳細から地図表示用） ---
let spotPinMarker = null;           // 単一スポットピン（単体）

// --- 人気スポットマーカー ---
let popularSpotMarkers = [];        // 人気スポット（配列）

// --- 提案マーカー ---
let suggestionMarkers = [];         // 提案スポット（配列）
let suggestionOverlays = [];        // 提案パルスオーバーレイ（配列）
let suggestionAreaCircles = [];     // 提案エリア円（グロー効果用に複数）

// --- map instance ---
export const getMapInstance = () => map;

export const setMapInstance = (newMap) => {
  map = newMap;
  // Stimulus コントローラーからアクセスできるように window にもセット
  window.mapInstance = newMap;
};

// --- 現在地マーカー ---
export const clearCurrentLocationMarker = () => {
  if (currentLocationMarker) {
    currentLocationMarker.setMap(null);
    currentLocationMarker = null;
  }
};

export const setCurrentLocationMarker = (marker) => {
  clearCurrentLocationMarker();
  currentLocationMarker = marker;
};

// --- 出発地点マーカー ---
export const clearStartPointMarker = () => {
  if (startPointMarker) {
    startPointMarker.setMap(null);
    startPointMarker = null;
  }
};

export const setStartPointMarker = (marker) => {
  clearStartPointMarker();
  startPointMarker = marker;
};

export const getStartPointMarker = () => startPointMarker;

// --- 帰宅地点マーカー ---
export const clearEndPointMarker = () => {
  if (endPointMarker) {
    endPointMarker.setMap(null);
    endPointMarker = null;
  }
};

export const setEndPointMarker = (marker) => {
  clearEndPointMarker();
  endPointMarker = marker;
};

export const getEndPointMarker = () => endPointMarker;

// --- プラン内スポットマーカー ---
export const clearPlanSpotMarkers = () => {
  planSpotMarkers.forEach((m) => m.setMap(null));
  planSpotMarkers = [];
};

export const setPlanSpotMarkers = (markers) => {
  clearPlanSpotMarkers();
  planSpotMarkers = markers;
};

export const getPlanSpotMarkers = () => planSpotMarkers;

// --- 検索ヒットマーカー ---
export const clearSearchHitMarkers = () => {
  searchHitMarkers.forEach((m) => m.setMap(null));
  searchHitMarkers = [];
};

export const setSearchHitMarkers = (markers) => {
  clearSearchHitMarkers();
  searchHitMarkers = markers;
};

// --- 経路ポリライン ---
export const clearRoutePolylines = () => {
  routePolylines.forEach((p) => p.setMap(null));
  routePolylines = [];
};

export const setRoutePolylines = (polylines) => {
  clearRoutePolylines();
  routePolylines = polylines;
};

// --- コミュニティプランプレビュー用マーカー ---
export const clearCommunityPreviewMarkers = () => {
  communityPreviewMarkers.forEach((m) => m.setMap(null));
  communityPreviewMarkers = [];
};

export const setCommunityPreviewMarkers = (markers) => {
  clearCommunityPreviewMarkers();
  communityPreviewMarkers = markers;
};

export const getCommunityPreviewMarkers = () => communityPreviewMarkers;

// --- コミュニティプランプレビュー用ポリライン ---
export const clearCommunityPreviewPolylines = () => {
  communityPreviewPolylines.forEach((p) => p.setMap(null));
  communityPreviewPolylines = [];
};

export const setCommunityPreviewPolylines = (polylines) => {
  clearCommunityPreviewPolylines();
  communityPreviewPolylines = polylines;
};

// --- コミュニティプレビュー全クリア ---
export const clearCommunityPreview = () => {
  clearCommunityPreviewMarkers();
  clearCommunityPreviewPolylines();
  clearSpotPinMarker();
};

// --- 単一スポットピン ---
export const clearSpotPinMarker = () => {
  if (spotPinMarker) {
    spotPinMarker.setMap(null);
    spotPinMarker = null;
  }
};

export const setSpotPinMarker = (marker) => {
  clearSpotPinMarker();
  spotPinMarker = marker;
};

// --- 人気スポットマーカー ---
export const clearPopularSpotMarkers = () => {
  popularSpotMarkers.forEach((m) => m.setMap(null));
  popularSpotMarkers = [];
};

export const setPopularSpotMarkers = (markers) => {
  clearPopularSpotMarkers();
  popularSpotMarkers = markers;
};

// --- 提案マーカー ---
// 全クリア（マーカー + パルス + 円）
export const clearSuggestionMarkers = () => {
  suggestionMarkers.forEach((m) => m.setMap(null));
  suggestionMarkers = [];
  suggestionOverlays.forEach((o) => o.setMap(null));
  suggestionOverlays = [];
  suggestionAreaCircles.forEach(c => c.setMap(null));
  suggestionAreaCircles = [];
};

// エリア円を設定（配列対応）
export const setSuggestionAreaCircle = (circles) => {
  suggestionAreaCircles.forEach(c => c.setMap(null));
  suggestionAreaCircles = Array.isArray(circles) ? circles : [circles];
};

export const setSuggestionMarkers = (markers) => {
  clearSuggestionMarkers();
  suggestionMarkers = markers;
};

export const addSuggestionMarker = (marker) => {
  suggestionMarkers.push(marker);
};

export const addSuggestionOverlay = (overlay) => {
  suggestionOverlays.push(overlay);
};

export const getSuggestionMarkers = () => suggestionMarkers;