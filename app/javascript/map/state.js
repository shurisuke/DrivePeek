// ================================================================
// 地図とマーカーの状態管理（単一責務）
// 用途: mapインスタンスと各種マーカー参照を保持し、差し替え/クリアを提供する
// ================================================================

let map = null;

// --- マーカー状態（用途別に分離） ---
let currentLocationMarker = null; // 現在地（単体）
let startPointMarker = null;      // 出発地点（単体）
let endPointMarker = null;        // 帰宅地点（単体）
let planSpotMarkers = [];         // プラン内スポット（配列）
let searchHitMarkers = [];        // 検索ヒット（配列）

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