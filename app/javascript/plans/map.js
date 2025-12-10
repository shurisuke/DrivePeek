let map;
let markers = []; // ← 複数マーカー管理用

const renderMap = (center) => {
  const mapElement = document.getElementById("map");
  if (!mapElement) {
    console.error("地図を表示する #map 要素が見つかりません");
    return;
  }

  map = new google.maps.Map(mapElement, {
    center,
    zoom: 12,
    disableDefaultUI: true,
  });

  setupSearchBox(); // ← 初期マーカーは削除（任意）
};

const setupSearchBox = () => {
  const input = document.getElementById("places-search-box");
  if (!input) return;

  const searchBox = new google.maps.places.SearchBox(input);

  // map の表示範囲に合わせて検索優先領域を設定
  map.addListener("bounds_changed", () => {
    searchBox.setBounds(map.getBounds());
  });

  // 🔍 候補が選ばれたとき
  searchBox.addListener("places_changed", () => {
    const places = searchBox.getPlaces();
    if (!places || places.length === 0) return;

    // 古いマーカーを削除
    markers.forEach(marker => marker.setMap(null));
    markers = [];

    // 表示範囲調整用
    const bounds = new google.maps.LatLngBounds();

    // 最大 10 件
    places.slice(0, 10).forEach(place => {
      if (!place.geometry || !place.geometry.location) return;

      // マーカー作成
      const marker = new google.maps.Marker({
        map,
        position: place.geometry.location,
        title: place.name,
      });

      markers.push(marker);

      // 表示範囲に追加
      if (place.geometry.viewport) {
        bounds.union(place.geometry.viewport);
      } else {
        bounds.extend(place.geometry.location);
      }
    });

    // 地図上に全ピンが収まるように移動（周囲100px余白）
    map.fitBounds(bounds, {
      top: 100, bottom: 100, left: 100, right: 100
    });
  });
};

// Turbo対応
document.addEventListener("turbo:load", () => {
  if (document.getElementById("map") && typeof google !== "undefined" && google.maps) {
    initMap();
  }
});

// 現在地 → 地図描画
globalThis.initMap = function () {
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      (position) => {
        renderMap({
          lat: position.coords.latitude,
          lng: position.coords.longitude,
        });
      },
      () => {
        renderMap({ lat: 35.681236, lng: 139.767125 }); // fallback: 東京駅
      }
    );
  } else {
    renderMap({ lat: 35.681236, lng: 139.767125 });
  }
};