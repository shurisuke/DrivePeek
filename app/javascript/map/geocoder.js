// ================================================================
// Geocoder（単一責務）
// 用途:
// - 住所文字列を Geocoding して位置情報を取得する
// - 失敗時は Promise を reject して呼び出し元にエラーを返す
// ================================================================

export const geocodeAddress = (address) => {
  // 呼び出し元で await できるよう Promise 化
  return new Promise((resolve, reject) => {

    // 1) 入力チェック（空なら失敗として返す）
    if (!address || address.trim() === "") {
      // ✅ reject = 「失敗として返す」(表示するかは呼び出し元の責務)
      reject(new Error("住所が空です"));
      return;
    }

    // 2) Google Maps API が読み込まれているかチェック
    if (!window.google?.maps?.Geocoder) {
      reject(new Error("Google Maps API (Geocoder) が読み込まれていません"));
      return;
    }

    // 3) Geocoder を作成して、住所 → 座標変換を実行
    const geocoder = new google.maps.Geocoder();

    geocoder.geocode({ address: address.trim() }, (results, status) => {

      // 4) 失敗判定（status がOKじゃない / 結果が空）
      if (status !== "OK" || !results || results.length === 0) {
        reject(new Error(`Geocoding に失敗しました: ${status}`));
        return;
      }

      // 5) 成功：1件目を採用して必要な情報だけ返す
      const result = results[0];

      resolve({
        location: result.geometry.location,     // google.maps.LatLng（lat(), lng() が取れる）
        viewport: result.geometry.viewport,     // google.maps.LatLngBounds | undefined（fitBoundsに使える）
        formattedAddress: result.formatted_address, // 表示用住所（例: "日本、〒... 栃木県..."）
        placeId: result.place_id,               // Google Places ID
      });
    });
  });
};

// ================================================================
// 表示用の住所整形（単一責務）
// 用途:
// - Googleが返す formatted_address は長いので、表示に不要な部分を削る
//   例: "日本、〒xxx-xxxx 栃木県..." → "栃木県..."
// ================================================================

export const normalizeDisplayAddress = (formattedAddress) => {
  // ✅ 何もなければ空文字
  if (!formattedAddress) return "";

  // 1) 先頭の「日本、」を削除
  let s = formattedAddress.replace(/^日本、\s*/u, "");

  // 2) 先頭の郵便番号「〒123-4567 」を削除
  s = s.replace(/^〒\d{3}-\d{4}\s*/u, "");

  // 3) 前後の空白を削って返す
  return s.trim();
};