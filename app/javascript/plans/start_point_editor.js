// ================================================================
// 出発地点変更UI（単一責務）
// 用途:
// - 「変更」ボタンでフォームを開閉
// - Enterで住所をGeocodingして、出発地点ピンを差し替え
// - 検索ヒットピンがあれば全消去
// - 地図をズーム/フォーカス（デフォルト挙動）
// - サーバへ更新をPATCH（StartPointsController#update）
// 注意:
// - ▼詳細パネルは Bootstrap dropdown だけで動かす（ここでは触らない）
// ================================================================

import {
  getMapInstance,
  clearSearchHitMarkers,
  clearStartPointMarker,
  setStartPointMarker,
} from "map/state";

import { geocodeAddress, normalizeDisplayAddress } from "map/geocoder";

const START_POINT_ICON_URL = "/icons/house-pin.png";
const START_POINT_ICON_SIZE = { w: 50, h: 55 };
const FOCUS_ZOOM = 16;

document.addEventListener("turbo:load", () => {
  const blocks = document.querySelectorAll(".start-point-block");
  if (blocks.length === 0) return;

  blocks.forEach((block) => {
    const toggleBtn = block.querySelector("[data-start-point-toggle]");
    const editArea = block.querySelector("#start-point-edit");
    const input = block.querySelector("#start-point-address");
    const addressSpan = block.querySelector(".start-label .address");

    if (!toggleBtn || !editArea || !input || !addressSpan) return;

    // Turboのキャッシュ復元などで二重バインドしない保険
    if (toggleBtn.dataset.bound === "true") return;
    toggleBtn.dataset.bound = "true";

    // ----------------------------------------------------------------
    // 1) 「変更」ボタンでフォームを開閉
    // ----------------------------------------------------------------
    toggleBtn.addEventListener("click", () => {
      const isOpen = editArea.hidden === false;

      editArea.hidden = isOpen;
      toggleBtn.setAttribute("aria-expanded", String(!isOpen));

      if (!isOpen) input.focus();
    });

    // --- IME変換中フラグ（変換確定Enterを除外するため） ---
    let isImeComposing = false;
    input.addEventListener("compositionstart", () => (isImeComposing = true));
    input.addEventListener("compositionend", () => (isImeComposing = false));

    // ----------------------------------------------------------------
    // 2) Enterで検索 → 更新（ピン差し替え + 地図フォーカス + サーバ更新）
    // ----------------------------------------------------------------
    input.addEventListener("keydown", async (e) => {
      // IME変換中Enterは発火させない（日本語変換対策）
      if (e.isComposing || isImeComposing || e.keyCode === 229) return;

      // Enter以外は無視
      if (e.key !== "Enter") return;

      // 確定Enter（実行）
      e.preventDefault();

      const map = getMapInstance();
      if (!map) {
        console.warn("🟡 map がまだ初期化されていません");
        return;
      }

      const query = input.value.trim();
      if (!query) return;

      try {
        // 検索ヒット地点ピンがある場合、全て消去
        clearSearchHitMarkers();

        // 住所を Geocoding
        const { location, viewport, formattedAddress } = await geocodeAddress(query);

        // 表示用に整形（日本/郵便番号を落とす）
        const displayAddress = normalizeDisplayAddress(formattedAddress);

        // スタート地点pinを消して差し直す
        clearStartPointMarker();

        const marker = new google.maps.Marker({
          map,
          position: location,
          title: "出発地点",
          icon: {
            url: START_POINT_ICON_URL,
            scaledSize: new google.maps.Size(START_POINT_ICON_SIZE.w, START_POINT_ICON_SIZE.h),
          },
        });

        setStartPointMarker(marker);

        // デフォルト挙動：
        // - viewport がある → fitBounds（Google Maps標準の寄せ）
        // - viewport がない → panTo + setZoom
        if (viewport) {
          map.fitBounds(viewport);
        } else {
          map.panTo(location);
          map.setZoom(FOCUS_ZOOM);
        }

        // UIの住所表示も更新（先に表示は更新してOK）
        addressSpan.textContent = displayAddress || query;

        // フォームは閉じる
        editArea.hidden = true;
        toggleBtn.setAttribute("aria-expanded", "false");

        // サーバへ保存（StartPointsController#update）
        const lat = typeof location.lat === "function" ? location.lat() : location.lat;
        const lng = typeof location.lng === "function" ? location.lng() : location.lng;

        const resJson = await persistStartPoint({
          lat,
          lng,
          address: displayAddress || query,
        });

        // サーバが返した値で最終上書き（表示ズレ防止）
        if (resJson?.ok && resJson?.start_point?.address) {
          addressSpan.textContent = resJson.start_point.address;
        }

        console.log("✅ start_point update success:", resJson);
      } catch (err) {
        console.warn("⚠️ 出発地点の更新に失敗:", err);
        alert("住所が見つからない、または保存に失敗しました。別のキーワードで試してください。");
      }
    });
  });
});

// ================================================================
// サーバ更新（単一責務）
// - StartPointsController#update にPATCHする
// ================================================================

const persistStartPoint = async ({ lat, lng, address }) => {
  const planId = detectPlanIdFromPath();
  if (!planId) {
    console.warn("🟡 planId が特定できません（サーバ更新をスキップ）");
    return null;
  }

  const token = document.querySelector('meta[name="csrf-token"]')?.content;
  const url = `/plans/${planId}/start_point`;

  const res = await fetch(url, {
    method: "PATCH",
    credentials: "same-origin",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": token,
      Accept: "application/json",
    },
    body: JSON.stringify({
      start_point: { lat, lng, address },
    }),
  });

  const json = await res.json().catch(() => null);

  if (!res.ok || !json?.ok) {
    const msg = json?.errors?.join(", ") || `status=${res.status}`;
    throw new Error(`start_point update failed: ${msg}`);
  }

  return json;
};

// /plans/:id/edit から id を抜く簡易関数
const detectPlanIdFromPath = () => {
  const m = window.location.pathname.match(/\/plans\/(\d+)(\/edit)?/);
  return m ? m[1] : null;
};