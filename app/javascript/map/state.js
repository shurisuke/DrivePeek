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

// --- map instance ---
export const getMapInstance = () => map;

export const setMapInstance = (newMap) => {
  map = newMap;
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

// --- プラン内スポットマーカー ---
export const clearPlanSpotMarkers = () => {
  planSpotMarkers.forEach((m) => m.setMap(null));
  planSpotMarkers = [];
};

export const setPlanSpotMarkers = (markers) => {
  clearPlanSpotMarkers();
  planSpotMarkers = markers;
};

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

// --- 全状態クリア（ページ遷移時用） ---
export const clearAllMapState = () => {
  clearCurrentLocationMarker();
  clearStartPointMarker();
  clearEndPointMarker();
  clearPlanSpotMarkers();
  clearSearchHitMarkers();
  clearRoutePolylines();
  map = null;
};