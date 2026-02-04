// ================================================================
// 現在地マーカー（単一責務）
// 用途: geolocation で現在地を取得し、現在地マーカーを表示する
// ================================================================

import { getMapInstance, setCurrentLocationMarker } from "map/state";
import { COLORS } from "map/constants";

export const addCurrentLocationMarker = async ({ panTo = false } = {}) => {
  const map = getMapInstance();
  if (!map) return;

  if (!navigator.geolocation) {
    console.warn("Geolocation はこのブラウザでサポートされていません");
    return;
  }

  // Permissions API で許可状態を確認（未許可なら確認ダイアログを出さずにスキップ）
  if (navigator.permissions) {
    try {
      const permission = await navigator.permissions.query({ name: "geolocation" });
      if (permission.state === "denied") {
        console.warn("位置情報の使用が拒否されています");
        return;
      }
      if (permission.state === "prompt") {
        // 未確認の場合はスキップ（プラン作成時に確認済みのはず）
        return;
      }
    } catch (e) {
      // Permissions API 非対応ブラウザは従来通り
    }
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

      if (panTo) {
        latestMap.panTo(latLng);
      }
    },
    (error) => {
      console.warn("⚠️ 現在地の取得に失敗しました:", error);
    }
  );
};