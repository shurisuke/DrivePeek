// ================================================================
// 現在地マーカー（単一責務）
// 用途: geolocation で現在地を取得し、現在地マーカーを表示する
// ================================================================

import { getMapInstance, setCurrentLocationMarker } from "map/state";
import { COLORS } from "map/constants";

export const addCurrentLocationMarker = () => {
  console.log("🟢 addCurrentLocationMarker が呼び出されました");

  const map = getMapInstance();
  if (!map) return;

  if (!navigator.geolocation) {
    console.warn("Geolocation はこのブラウザでサポートされていません");
    return;
  }

  navigator.geolocation.getCurrentPosition(
    (position) => {
      const latestMap = getMapInstance();
      if (!latestMap) return;

      const latLng = {
        lat: position.coords.latitude,
        lng: position.coords.longitude,
      };

      const marker = new google.maps.Marker({
        map: latestMap,
        position: latLng,
        title: "現在地",
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: 8,
          fillColor: COLORS.CURRENT_LOCATION,
          fillOpacity: 0.9,
          strokeWeight: 2,
          strokeColor: "white",
        },
      });

      setCurrentLocationMarker(marker);

      latestMap.panTo(latLng); // 現在地へ寄せる（不要なら削除OK）
      console.log("✅ 現在地マーカーを表示しました:", latLng);
    },
    (error) => {
      console.warn("⚠️ 現在地の取得に失敗しました:", error);
    }
  );
};