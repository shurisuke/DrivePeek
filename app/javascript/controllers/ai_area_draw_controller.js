import { Controller } from "@hotwired/stimulus"
import { getMapInstance, setAiAreaCircle, clearAiSuggestionMarkers } from "map/state"
import { closeInfoWindow } from "map/infowindow"

// ================================================================
// AiAreaDrawController
// 用途: 地図上でフリーハンド描画 → 円変換してエリア選択
// - ai:startAreaDraw イベントで描画モード開始
// - フリーハンド描画 → 円に変換
// - ai:areaSelected イベントで結果を通知
// ================================================================

export default class extends Controller {
  static targets = ["modal", "moveMode", "drawMode", "confirmMode", "radiusDisplay"]

  // ============================================
  // 状態（thisで保持）
  // ============================================
  // this.mode        - "plan" | "spots"
  // this.condition   - 既存条件（エリア選び直し時）
  // this.isDrawing   - 描画中フラグ
  // this.drawPath    - 描画軌跡 [{lat, lng}, ...]
  // this.polyline    - Google Maps Polyline
  // this.circle      - Google Maps Circle
  // this.circleData  - { center: {lat, lng}, radius_km }
  // this.map         - Google Maps インスタンス

  connect() {
    this.handleStart = this.handleStart.bind(this)
    document.addEventListener("ai:startAreaDraw", this.handleStart)
  }

  disconnect() {
    document.removeEventListener("ai:startAreaDraw", this.handleStart)
    this.cleanup()
  }

  // ============================================
  // メイン処理
  // ============================================

  handleStart(e) {
    this.mode = e.detail?.mode || "spots"
    this.condition = e.detail?.condition || {}
    this.enterDrawMode()
  }

  enterDrawMode() {
    this.map = getMapInstance()
    if (!this.map) return

    // 既存のAI提案（円+ピン）をクリア
    clearAiSuggestionMarkers()
    closeInfoWindow()
    const clearBtn = document.getElementById("ai-pin-clear")
    if (clearBtn) clearBtn.hidden = true

    // 1. モーダル表示（移動モード）
    this.showModal()
  }

  // ============================================
  // 描画イベント
  // ============================================

  setupDrawEvents() {
    const mapDiv = this.map.getDiv()

    // バインド済み関数を保持（クリーンアップ用）
    this.boundMouseDown = (e) => this.startDraw(e)
    this.boundMouseMove = (e) => this.drawing(e)
    this.boundMouseUp = () => this.endDraw()
    this.boundTouchStart = (e) => { e.preventDefault(); this.startDraw(e) }
    this.boundTouchMove = (e) => { e.preventDefault(); this.drawing(e) }
    this.boundTouchEnd = () => this.endDraw()

    // マウスイベント
    mapDiv.addEventListener("mousedown", this.boundMouseDown)
    mapDiv.addEventListener("mousemove", this.boundMouseMove)
    mapDiv.addEventListener("mouseup", this.boundMouseUp)

    // タッチイベント
    mapDiv.addEventListener("touchstart", this.boundTouchStart, { passive: false })
    mapDiv.addEventListener("touchmove", this.boundTouchMove, { passive: false })
    mapDiv.addEventListener("touchend", this.boundTouchEnd)
  }

  removeDrawEvents() {
    if (!this.map) return
    const mapDiv = this.map.getDiv()

    mapDiv.removeEventListener("mousedown", this.boundMouseDown)
    mapDiv.removeEventListener("mousemove", this.boundMouseMove)
    mapDiv.removeEventListener("mouseup", this.boundMouseUp)
    mapDiv.removeEventListener("touchstart", this.boundTouchStart)
    mapDiv.removeEventListener("touchmove", this.boundTouchMove)
    mapDiv.removeEventListener("touchend", this.boundTouchEnd)
  }

  // ============================================
  // 描画処理
  // ============================================

  startDraw(e) {
    // 既存の円があれば削除
    this.circle?.setMap(null)
    this.switchToDrawMode()

    // 描画開始時に地図操作を無効化
    this.map.setOptions({
      draggable: false,
      scrollwheel: false,
      disableDoubleClickZoom: true,
      gestureHandling: "none"
    })

    this.isDrawing = true
    this.drawPath = []

    // ポリライン作成（リアルタイム描画用）
    this.polyline = new google.maps.Polyline({
      map: this.map,
      path: [],
      strokeColor: "#667eea",
      strokeWeight: 3,
      strokeOpacity: 0.8
    })

    this.addPoint(e)
  }

  drawing(e) {
    if (!this.isDrawing) return
    this.addPoint(e)
  }

  endDraw() {
    if (!this.isDrawing) return
    this.isDrawing = false

    // 描画終了時に地図操作を再度有効化
    this.map.setOptions({
      draggable: true,
      scrollwheel: true,
      disableDoubleClickZoom: false,
      gestureHandling: "greedy"
    })

    // 点が少なすぎる場合は無視
    if (this.drawPath.length < 3) {
      this.polyline?.setMap(null)
      return
    }

    // 軌跡 → 円変換
    this.circleData = this.calculateEnclosingCircle(this.drawPath)

    // ポリライン消去 → 円表示
    this.polyline?.setMap(null)
    this.showCircle()

    // 確定パネル表示
    this.switchToConfirmMode()
  }

  addPoint(e) {
    const latLng = this.getLatLngFromEvent(e)
    if (!latLng) return

    // 間引き（前回から一定距離以上離れている場合のみ追加）
    if (this.drawPath.length > 0) {
      const last = this.drawPath[this.drawPath.length - 1]
      const distance = google.maps.geometry.spherical.computeDistanceBetween(
        new google.maps.LatLng(last.lat, last.lng),
        new google.maps.LatLng(latLng.lat, latLng.lng)
      )
      // 50m未満は無視
      if (distance < 50) return
    }

    this.drawPath.push(latLng)
    this.polyline.setPath(this.drawPath.map(p => new google.maps.LatLng(p.lat, p.lng)))
  }

  getLatLngFromEvent(e) {
    // クライアント座標を取得
    const clientX = e.touches ? e.touches[0].clientX : e.clientX
    const clientY = e.touches ? e.touches[0].clientY : e.clientY

    // 地図のDOM要素の位置を取得
    const mapDiv = this.map.getDiv()
    const rect = mapDiv.getBoundingClientRect()

    // 地図内の相対座標
    const x = clientX - rect.left
    const y = clientY - rect.top

    // 地図の境界から座標を計算
    const bounds = this.map.getBounds()
    const ne = bounds.getNorthEast()
    const sw = bounds.getSouthWest()

    const mapWidth = rect.width
    const mapHeight = rect.height

    // 線形補間で座標を計算
    const lng = sw.lng() + (ne.lng() - sw.lng()) * (x / mapWidth)
    const lat = ne.lat() - (ne.lat() - sw.lat()) * (y / mapHeight)

    return { lat, lng }
  }

  // ============================================
  // 円変換アルゴリズム
  // ============================================

  calculateEnclosingCircle(points) {
    if (points.length === 0) return null
    if (points.length === 1) {
      return { center: points[0], radius_km: 1 }
    }

    // バウンディングボックスの中心を使用（重心より直感的）
    const lats = points.map(p => p.lat)
    const lngs = points.map(p => p.lng)
    const center = {
      lat: (Math.min(...lats) + Math.max(...lats)) / 2,
      lng: (Math.min(...lngs) + Math.max(...lngs)) / 2
    }

    // 最遠点までの距離を半径とする
    const centerLatLng = new google.maps.LatLng(center.lat, center.lng)
    let maxDistance = 0
    points.forEach(p => {
      const d = google.maps.geometry.spherical.computeDistanceBetween(
        centerLatLng,
        new google.maps.LatLng(p.lat, p.lng)
      ) / 1000 // メートル → km
      if (d > maxDistance) maxDistance = d
    })

    // 最小1km、最大50km
    const radius_km = Math.max(1, Math.min(50, maxDistance))

    return { center, radius_km }
  }

  // ============================================
  // UI状態切り替え
  // ============================================

  showModal() {
    // エリア描画モード開始（CSS一括制御 + 他コントローラーへ通知）
    document.body.classList.add("area-draw-active")
    document.dispatchEvent(new CustomEvent("ai:areaDrawStart"))

    // モーダル表示（移動モード）
    this.modalTarget.hidden = false
    this.moveModeTarget.hidden = false
    this.drawModeTarget.hidden = true
    this.confirmModeTarget.hidden = true
  }

  hideModal() {
    document.body.classList.remove("area-draw-active")
    this.modalTarget.hidden = true
  }

  // 描き始めるボタン → 描画モードへ
  startDrawingMode() {
    this.moveModeTarget.hidden = true
    this.drawModeTarget.hidden = false
    this.confirmModeTarget.hidden = true
    this.setupDrawEvents()
  }

  // 戻るボタン → 移動モードへ
  backToMoveMode() {
    this.removeDrawEvents()

    // 描画途中のポリラインを消去
    this.polyline?.setMap(null)
    this.polyline = null
    this.isDrawing = false
    this.drawPath = []

    this.moveModeTarget.hidden = false
    this.drawModeTarget.hidden = true
    this.confirmModeTarget.hidden = true
  }

  // 描画中の状態維持（描き直し時）
  switchToDrawMode() {
    this.moveModeTarget.hidden = true
    this.drawModeTarget.hidden = false
    this.confirmModeTarget.hidden = true
  }

  // 確定パネル表示
  switchToConfirmMode() {
    this.removeDrawEvents()
    this.moveModeTarget.hidden = true
    this.drawModeTarget.hidden = true
    this.confirmModeTarget.hidden = false
    this.radiusDisplayTarget.textContent = `半径: ${this.circleData.radius_km.toFixed(1)} km`
  }

  showCircle() {
    this.circle = new google.maps.Circle({
      map: this.map,
      center: this.circleData.center,
      radius: this.circleData.radius_km * 1000,
      strokeColor: "#667eea",
      strokeWeight: 2,
      fillColor: "#667eea",
      fillOpacity: 0.03,
      clickable: false
    })

    // 円に合わせてズーム
    this.map.fitBounds(this.circle.getBounds())
  }

  // ============================================
  // アクション
  // ============================================

  confirmArea() {
    // 円を専用変数に設定（クリアボタンで一緒に消える）
    if (this.circle) {
      setAiAreaCircle(this.circle)
      this.circle = null // cleanup で消されないように参照を外す
    }

    document.dispatchEvent(new CustomEvent("ai:areaSelected", {
      detail: {
        mode: this.mode,
        center_lat: this.circleData.center.lat,
        center_lng: this.circleData.center.lng,
        radius_km: this.circleData.radius_km,
        condition: this.condition
      }
    }))
    this.exitDrawMode()
  }

  redraw() {
    this.circle?.setMap(null)
    this.circle = null
    this.circleData = null
    this.backToMoveMode()
  }

  cancel() {
    // 円+ピンをクリア（enterDrawModeで既にクリア済みだが、念のため）
    clearAiSuggestionMarkers()
    const clearBtn = document.getElementById("ai-pin-clear")
    if (clearBtn) clearBtn.hidden = true

    this.exitDrawMode()
  }

  exitDrawMode() {
    if (this.map) {
      this.map.setOptions({
        draggable: true,
        scrollwheel: true,
        disableDoubleClickZoom: false,
        gestureHandling: "greedy"
      })
    }
    this.removeDrawEvents()
    this.cleanup()
    this.hideModal()
  }

  cleanup() {
    this.polyline?.setMap(null)
    this.polyline = null
    this.circle?.setMap(null)
    this.circle = null
    this.circleData = null
    this.drawPath = []
    this.isDrawing = false
  }
}
