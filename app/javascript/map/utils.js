// app/javascript/map/utils.js
//
// ================================================================
// Map Utilities（共通ユーティリティ）
// 用途: 地図関連の共通関数
// ================================================================

/**
 * Google Maps APIが利用可能になるまで待機する
 * @param {number} maxWait - 最大待機時間（ミリ秒）
 * @param {number} interval - チェック間隔（ミリ秒）
 * @returns {Promise<boolean>} - APIが利用可能になったらtrue
 */
export const waitForGoogleMaps = (maxWait = 5000, interval = 100) => {
  return new Promise((resolve) => {
    if (typeof google !== "undefined" && google.maps) {
      resolve(true)
      return
    }

    const startTime = Date.now()
    const checkInterval = setInterval(() => {
      if (typeof google !== "undefined" && google.maps) {
        clearInterval(checkInterval)
        resolve(true)
      } else if (Date.now() - startTime > maxWait) {
        clearInterval(checkInterval)
        console.error("[map/utils] Google Maps API の読み込みがタイムアウトしました")
        resolve(false)
      }
    }, interval)
  })
}

/**
 * 編集画面かどうかを判定
 */
export const isEditPage = () => {
  const mapElement = document.getElementById("map")
  return mapElement && mapElement.dataset.mapMode === "edit"
}

/**
 * プラン詳細画面かどうかを判定
 */
export const isShowPage = () => {
  const mapElement = document.getElementById("map")
  return mapElement && mapElement.dataset.mapMode === "show"
}

/**
 * スポット詳細画面かどうかを判定
 */
export const isSpotShowPage = () => {
  const mapElement = document.getElementById("map")
  return mapElement && mapElement.dataset.mapMode === "spot_show"
}
