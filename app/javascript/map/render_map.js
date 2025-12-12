// ================================================================
// 地図初期化（単一責務）
// 用途: Google Map を生成して state に登録し、検索機能を初期化する
// ================================================================

import { setMapInstance } from "map/state";
import { setupSearchBox } from "map/search_box";

export const renderMap = (center) => {
  const mapElement = document.getElementById("map");
  if (!mapElement) {
    console.error("地図を表示する #map 要素が見つかりません");
    return;
  }

  console.log("🗺️ 地図を初期化します（中心座標）:", center);

  const map = new google.maps.Map(mapElement, {
    center,
    zoom: 12,
    disableDefaultUI: true,
  });

  setMapInstance(map);

  setupSearchBox();
};