import { renderPlanMarkers } from "plans/render_plan_markers";

let map;
let markers = [];

export const getMapInstance = () => map;
export const getMarkers = () => markers;
export const setMarkers = (newMarkers) => { markers = newMarkers; };

// 現在地マーカーを追加する関数
const addCurrentLocationMarker = () => {
  console.log("🟢 addCurrentLocationMarker が呼び出されました");

  if (!navigator.geolocation) {
    console.warn("Geolocation はこのブラウザでサポートされていません");
    return;
  }

  navigator.geolocation.getCurrentPosition(
    (position) => {
      const latLng = {
        lat: position.coords.latitude,
        lng: position.coords.longitude,
      };

      const marker = new google.maps.Marker({
        map,
        position: latLng,
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

      map.panTo(latLng); // 現在地を中心に移動
      console.log("✅ 現在地マーカーを表示しました:", latLng);
    },
    (error) => {
      console.warn("⚠️ 現在地の取得に失敗しました:", error);
    }
  );
};

export const renderMap = (center) => {
  const mapElement = document.getElementById("map");
  if (!mapElement) {
    console.error("地図を表示する #map 要素が見つかりません");
    return;
  }

  console.log("🗺️ 地図を初期化します（中心座標）:", center);

  map = new google.maps.Map(mapElement, {
    center,
    zoom: 12,
    disableDefaultUI: true,
  });

  setupSearchBox();
};

const setupSearchBox = () => {
  const input = document.getElementById("places-search-box");
  if (!input) return;

  const searchBox = new google.maps.places.SearchBox(input);

  map.addListener("bounds_changed", () => {
    searchBox.setBounds(map.getBounds());
  });

  searchBox.addListener("places_changed", () => {
    const places = searchBox.getPlaces();
    if (!places || places.length === 0) return;

    markers.forEach(marker => marker.setMap(null));
    markers = [];

    const bounds = new google.maps.LatLngBounds();

    places.slice(0, 10).forEach(place => {
      if (!place.geometry?.location) return;

      const marker = new google.maps.Marker({
        map,
        position: place.geometry.location,
        title: place.name
      });

      markers.push(marker);

      if (place.geometry.viewport) {
        bounds.union(place.geometry.viewport);
      } else {
        bounds.extend(place.geometry.location);
      }
    });

    map.fitBounds(bounds);
  });
};

// Turbo対応
document.addEventListener("turbo:load", () => {
  if (document.getElementById("map")) {
    const fallbackCenter = { lat: 35.681236, lng: 139.767125 }; // 東京駅
    console.log("🚀 turbo:load で地図初期化を開始します");
    renderMap(fallbackCenter);
    addCurrentLocationMarker();

    // ✅ ここでマーカーを描画
    const planData = window.planData; // グローバル変数として用意してあるなら
    if (planData) {
      renderPlanMarkers(planData);
    } else {
      console.warn("🟡 planData が存在しません");
    }
  }
});