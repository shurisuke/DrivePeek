// ================================================================
// 写真URLキャッシュ
// 用途: Places APIの写真URLをキャッシュしてリクエスト数を削減
// ================================================================

// placeId -> photoUrl のキャッシュ
const cache = new Map()

/**
 * キャッシュから写真URLを取得
 * @param {string} placeId
 * @returns {string|null}
 */
export const getCachedPhotoUrl = (placeId) => {
  if (!placeId) return null
  return cache.get(placeId) || null
}

/**
 * 写真URLをキャッシュに保存
 * @param {string} placeId
 * @param {string|null} photoUrl
 */
export const setCachedPhotoUrl = (placeId, photoUrl) => {
  if (!placeId) return
  cache.set(placeId, photoUrl)
}

/**
 * 写真URLを取得（キャッシュ優先、なければAPI呼び出し）
 * @param {Object} options
 * @param {string} options.placeId - Place ID
 * @param {google.maps.Map} options.map - マップインスタンス
 * @returns {Promise<string|null>}
 */
export const getPhotoUrl = async ({ placeId, map }) => {
  if (!placeId || !map) return null

  // キャッシュにあればそれを返す
  const cached = getCachedPhotoUrl(placeId)
  if (cached !== null) {
    return cached
  }

  // Places APIで取得
  if (!google.maps.places) return null

  return new Promise((resolve) => {
    const service = new google.maps.places.PlacesService(map)
    service.getDetails(
      { placeId, fields: ["photos"] },
      (place, status) => {
        let photoUrl = null
        if (status === google.maps.places.PlacesServiceStatus.OK && place?.photos?.[0]) {
          photoUrl = place.photos[0].getUrl({ maxWidth: 520 })
        }
        // キャッシュに保存（nullも保存して再リクエスト防止）
        setCachedPhotoUrl(placeId, photoUrl)
        resolve(photoUrl)
      }
    )
  })
}

/**
 * キャッシュをクリア
 */
export const clearPhotoCache = () => {
  cache.clear()
}
