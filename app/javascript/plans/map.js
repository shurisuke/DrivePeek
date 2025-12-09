// map.js

const renderMap = (center) => {
  const mapElement = document.getElementById("map");
  if (!mapElement) {
    console.error("地図を表示する #map 要素が見つかりません");
    return;
  }

  const map = new google.maps.Map(mapElement, {
    zoom: 12,
    center: center,
    disableDefaultUI: true,
  });

  new google.maps.Marker({
    position: center,
    map: map,
  });
};

document.addEventListener("turbo:load", () => {
  // このページに #map 要素があるかを確認
  if (document.getElementById("map") && typeof google !== "undefined" && google.maps) {
    initMap();
  }
});

// グローバル関数として保持（Google Maps API 用）
globalThis.initMap = function () {
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const center = {
          lat: position.coords.latitude,
          lng: position.coords.longitude,
        };
        renderMap(center);
      },
      (error) => {
        console.warn("位置情報取得に失敗しました", error);
        renderMap({ lat: 35.681236, lng: 139.767125 }); // fallback to Tokyo
      }
    );
  } else {
    renderMap({ lat: 35.681236, lng: 139.767125 });
  }
};