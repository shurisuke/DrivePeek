// ================================================================
// プランのマーカー描画
// 用途: planData をもとに 出発・スポット・帰宅 の各マーカーを描画する
// ================================================================

import {
  getMapInstance,
  clearStartPointMarker,
  setStartPointMarker,
  clearEndPointMarker,
  setEndPointMarker,
  clearPlanSpotMarkers,
  setPlanSpotMarkers,
} from "map/state";

const normalizeLatLng = (p) => {
  if (!p) return null;
  return { lat: Number(p.lat), lng: Number(p.lng) };
};

export const renderPlanMarkers = (planData) => {
  const map = getMapInstance();
  if (!map) {
    console.error("マップインスタンスが存在しません");
    return;
  }

  // 既存マーカーを用途別にクリア
  clearStartPointMarker();
  clearPlanSpotMarkers();
  clearEndPointMarker();

  // 出発地点
  const start = normalizeLatLng(planData?.start_point);
  if (start) {
    const marker = new google.maps.Marker({
      map,
      position: start,
      title: "出発地点",
      icon: {
        url: "/icons/house-pin.png",
        scaledSize: new google.maps.Size(50, 55),
      },
    });
    setStartPointMarker(marker);
  }

  // スポット
  const spots = Array.isArray(planData?.spots) ? planData.spots : [];
  const spotMarkers = spots
    .map(normalizeLatLng)
    .filter(Boolean)
    .map((spot, index) => {
      return new google.maps.Marker({
        map,
        position: spot,
        title: `スポット ${index + 1}`,
      });
    });
  setPlanSpotMarkers(spotMarkers);

  // 帰宅地点
  const end = normalizeLatLng(planData?.end_point);
  if (end) {
    const marker = new google.maps.Marker({
      map,
      position: end,
      title: "帰宅地点",
      icon: {
        url: "/icons/house-pin.png",
        scaledSize: new google.maps.Size(50, 55),
      },
    });
    setEndPointMarker(marker);
  }
};