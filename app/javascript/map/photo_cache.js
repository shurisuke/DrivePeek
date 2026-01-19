// ================================================================
// 写真キャッシュ
// 用途: Places APIの写真情報をキャッシュしてリクエスト数を削減
// ================================================================

// placeId -> { photoUrl, photos } のキャッシュ
const cache = new Map()

/**
 * キャッシュから写真URLを取得
 * @param {string} placeId
 * @returns {string|null}
 */
export const getCachedPhotoUrl = (placeId) => {
  if (!placeId) return null
  return cache.get(placeId)?.photoUrl || null
}

/**
 * キャッシュからphotos配列を取得
 * @param {string} placeId
 * @returns {Array|null}
 */
export const getCachedPhotos = (placeId) => {
  if (!placeId) return null
  return cache.get(placeId)?.photos || null
}

/**
 * 写真情報をキャッシュに保存
 * @param {string} placeId
 * @param {string|null} photoUrl
 * @param {Array|null} photos
 */
export const setCachedPhotos = (placeId, photoUrl, photos) => {
  if (!placeId) return
  cache.set(placeId, { photoUrl, photos })
}

// 後方互換性のため
export const setCachedPhotoUrl = (placeId, photoUrl) => {
  if (!placeId) return
  const existing = cache.get(placeId)
  cache.set(placeId, { ...existing, photoUrl })
}

/**
 * 写真情報を取得（キャッシュ優先、なければAPI呼び出し）
 * @param {Object} options
 * @param {string} options.placeId - Place ID
 * @param {google.maps.Map} options.map - マップインスタンス
 * @returns {Promise<{ photoUrl: string|null, photos: Array }>}
 */
export const getPlacePhotos = async ({ placeId, map }) => {
  if (!placeId || !map) return { photoUrl: null, photos: [] }

  // キャッシュにあればそれを返す
  const cached = cache.get(placeId)
  if (cached !== undefined) {
    return { photoUrl: cached.photoUrl, photos: cached.photos || [] }
  }

  // Places APIで取得
  if (!google.maps.places) return { photoUrl: null, photos: [] }

  return new Promise((resolve) => {
    const service = new google.maps.places.PlacesService(map)
    service.getDetails(
      { placeId, fields: ["photos"] },
      (place, status) => {
        let photoUrl = null
        let photos = []
        if (status === google.maps.places.PlacesServiceStatus.OK && place?.photos) {
          photos = place.photos.slice(0, 5) // 最大5枚
          if (photos[0]?.getUrl) {
            photoUrl = photos[0].getUrl({ maxWidth: 520 })
          }
        }
        // キャッシュに保存
        setCachedPhotos(placeId, photoUrl, photos)
        resolve({ photoUrl, photos })
      }
    )
  })
}

/**
 * 写真URLを取得（後方互換性）
 */
export const getPhotoUrl = async ({ placeId, map }) => {
  const { photoUrl } = await getPlacePhotos({ placeId, map })
  return photoUrl
}

/**
 * キャッシュをクリア
 */
export const clearPhotoCache = () => {
  cache.clear()
}
