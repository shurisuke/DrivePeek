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
        scaledSize: new google.maps.Size(50, 55),
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
        scaledSize: new google.maps.Size(50, 55),
      },
    }));
  }
};