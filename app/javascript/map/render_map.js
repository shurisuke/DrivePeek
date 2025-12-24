// ================================================================
// 地図初期化（単一責務）
// 用途: Google Map を生成して state に登録し、検索機能を初期化する
// ================================================================

import { setMapInstance, getMapInstance } from "map/state";
import { setupSearchBox } from "map/search_box";
import { showInfoWindow } from "map/infowindow";

// PlacesService のキャッシュ
let placesService = null;

const getPlacesService = () => {
  if (!placesService) {
    const map = getMapInstance();
    if (!map) return null;
    placesService = new google.maps.places.PlacesService(map);
  }
  return placesService;
};

/**
 * POIクリックイベントをセットアップ
 * 地図上のPOI（店舗・施設等）クリック時にInfoWindowを表示する
 */
const setupPoiClick = (map) => {
  map.addListener("click", (event) => {
    // placeId が存在する場合は POI クリック
    if (!event.placeId) return;

    // デフォルトのInfoWindowを抑制
    event.stop();

    const service = getPlacesService();
    if (!service) return;

    // Places API で詳細情報を取得
    service.getDetails(
      {
        placeId: event.placeId,
        fields: [
          "place_id",
          "name",
          "formatted_address",
          "vicinity",
          "geometry",
          "photos",
          "types",
        ],
      },
      (place, status) => {
        if (status !== google.maps.places.PlacesServiceStatus.OK || !place) {
          console.warn("POI詳細取得失敗:", status);
          return;
        }

        const buttonId = `dp-add-spot-poi-${place.place_id}`;

        showInfoWindow({
          anchor: event.latLng,
          place,
          buttonId,
          showButton: true,
        });
      }
    );
  });
};

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
  setupPoiClick(map);
};
