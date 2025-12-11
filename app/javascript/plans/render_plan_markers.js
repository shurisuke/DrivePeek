// app/javascript/maps/render_plan_markers.js
import { getMapInstance, getMarkers, setMarkers } from "plans/init_map";

export const renderPlanMarkers = (planData) => {
  const map = getMapInstance();
  if (!map) {
    console.error("マップインスタンスが存在しません");
    return;
  }

  // 既存マーカーを削除
  getMarkers().forEach(marker => marker.setMap(null));
  const newMarkers = [];

  // 出発地点
  if (planData.start_point) {
    newMarkers.push(new google.maps.Marker({
      map,
      position: planData.start_point,
      title: "出発地点",
      icon: {
        url: "/icons/house-pin.png",
        scaledSize: new google.maps.Size(50, 50),
      },
    }));
  }

  // スポット
  planData.spots.forEach((spot, index) => {
    newMarkers.push(new google.maps.Marker({
      map,
      position: spot,
      title: `スポット ${index + 1}`,
    }));
  });

  // 帰宅地点
  if (planData.end_point) {
    newMarkers.push(new google.maps.Marker({
      map,
      position: planData.end_point,
      title: "帰宅地点",
      icon: {
        url: "/icons/house-pin.png",
        scaledSize: new google.maps.Size(50, 50),
      },
    }));
  }

  // 現在地マーカー
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const currentLatLng = {
          lat: position.coords.latitude,
          lng: position.coords.longitude,
        };

        const currentLocationMarker = new google.maps.Marker({
          map,
          position: currentLatLng,
          title: "現在地",
          icon: {
            path: google.maps.SymbolPath.CIRCLE,
            scale: 8,
            fillColor: "#4285F4",
            fillOpacity: 0.9,
            strokeWeight: 2,
            strokeColor: "white",
          }
        });

        newMarkers.push(currentLocationMarker);
        setMarkers(newMarkers); // 位置情報取得後に setMarkers を更新
      },
      (error) => {
        console.warn("現在地取得に失敗しました", error);
        setMarkers(newMarkers); // 失敗しても他マーカーは保持
      }
    );
  } else {
    console.warn("このブラウザでは geolocation がサポートされていません");
    setMarkers(newMarkers);
  }
};