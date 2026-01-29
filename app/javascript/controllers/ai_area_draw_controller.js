import { Controller } from "@hotwired/stimulus"
import { getMapInstance } from "map/state"

// ================================================================
// AiAreaDrawController
// 用途: 地図上でフリーハンド描画 → 円変換してエリア選択
// - ai:startAreaDraw イベントで描画モード開始
// - フリーハンド描画 → 円に変換
// - ai:areaSelected イベントで結果を通知
// ================================================================

export default class extends Controller {
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
  // this.overlayEl   - オーバーレイDOM要素
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

    // 1. オーバーレイ + ガイド表示（地図移動は可能）
    this.showOverlay()

    // 2. 描画イベントはまだ設定しない（「描き始める」ボタンで開始）
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
    this.hideConfirmPanel()

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
    this.showConfirmPanel()
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
  // UI（JSで動的生成）
  // ============================================

  showOverlay() {
    // 既存のオーバーレイがあれば削除
    this.hideOverlay()

    // モバイル時: ボトムシートを最小化
    const navibar = document.querySelector(".navibar")
    if (navibar) {
      const bottomSheetController = this.application.getControllerForElementAndIdentifier(navibar, "bottom-sheet")
      bottomSheetController?.collapse()
    }

    // ナビバーを暗転
    navibar?.classList.add("navibar--area-draw-dimmed")

    // 不要な要素を非表示
    document.querySelector(".map-search-box")?.classList.add("area-draw-hidden")
    document.querySelector(".plan-actions")?.classList.add("area-draw-hidden")
    document.querySelector(".hamburger")?.classList.add("area-draw-hidden")
    document.querySelector(".map-floating-buttons")?.classList.add("area-draw-hidden")

    this.overlayEl = document.createElement("div")
    this.overlayEl.className = "area-draw-overlay"
    this.overlayEl.innerHTML = `
      <div class="area-draw-guide">
        <div class="area-draw-guide__header">
          <div class="area-draw-guide__icon">
            <i class="bi bi-geo-alt"></i>
          </div>
          <div class="area-draw-guide__text">
            選択したいエリアまで<br>地図を移動してください
          </div>
        </div>
        <div class="area-draw-guide__actions">
          <button type="button" class="area-draw-guide__cancel-btn">
            キャンセル
          </button>
          <button type="button" class="area-draw-guide__start-btn">
            描き始める
          </button>
        </div>
      </div>
    `
    document.body.appendChild(this.overlayEl)

    // ボタンイベント
    const cancelBtn = this.overlayEl.querySelector(".area-draw-guide__cancel-btn")
    const startBtn = this.overlayEl.querySelector(".area-draw-guide__start-btn")
    cancelBtn.addEventListener("click", () => this.cancel())
    startBtn.addEventListener("click", () => this.startDrawingMode())
  }

  startDrawingMode() {
    // ガイドを描画モード用に変更
    const guide = this.overlayEl?.querySelector(".area-draw-guide")
    if (guide) {
      guide.innerHTML = `
        <div class="area-draw-guide__header">
          <div class="area-draw-guide__icon">
            <i class="bi bi-hand-index"></i>
          </div>
          <div class="area-draw-guide__text">
            地図上で円を描くように<br>エリアをなぞってください
          </div>
        </div>
        <div class="area-draw-guide__actions">
          <button type="button" class="area-draw-guide__cancel-btn">
            戻る
          </button>
        </div>
      `
      const cancelBtn = guide.querySelector(".area-draw-guide__cancel-btn")
      cancelBtn.addEventListener("click", () => this.backToMoveMode())
    }

    // 描画イベント設定
    this.setupDrawEvents()
  }

  backToMoveMode() {
    // 描画イベント解除
    this.removeDrawEvents()

    // 描画途中のポリラインを消去
    this.polyline?.setMap(null)
    this.polyline = null
    this.isDrawing = false
    this.drawPath = []

    // ガイドを地図移動モードに戻す
    const guide = this.overlayEl?.querySelector(".area-draw-guide")
    if (guide) {
      guide.innerHTML = `
        <div class="area-draw-guide__header">
          <div class="area-draw-guide__icon">
            <i class="bi bi-geo-alt"></i>
          </div>
          <div class="area-draw-guide__text">
            選択したいエリアまで<br>地図を移動してください
          </div>
        </div>
        <div class="area-draw-guide__actions">
          <button type="button" class="area-draw-guide__cancel-btn">
            キャンセル
          </button>
          <button type="button" class="area-draw-guide__start-btn">
            描き始める
          </button>
        </div>
      `
      const cancelBtn = guide.querySelector(".area-draw-guide__cancel-btn")
      const startBtn = guide.querySelector(".area-draw-guide__start-btn")
      cancelBtn.addEventListener("click", () => this.cancel())
      startBtn.addEventListener("click", () => this.startDrawingMode())
    }
  }

  hideOverlay() {
    this.overlayEl?.remove()
    this.overlayEl = null

    // ナビバーの暗転を解除
    document.querySelector(".navibar")?.classList.remove("navibar--area-draw-dimmed")

    // 非表示にした要素を再表示
    document.querySelectorAll(".area-draw-hidden").forEach(el => {
      el.classList.remove("area-draw-hidden")
    })
  }

  showCircle() {
    this.circle = new google.maps.Circle({
      map: this.map,
      center: this.circleData.center,
      radius: this.circleData.radius_km * 1000,
      strokeColor: "#667eea",
      strokeWeight: 2,
      fillColor: "#667eea",
      fillOpacity: 0.15,
      clickable: false
    })

    // 円に合わせてズーム
    this.map.fitBounds(this.circle.getBounds())
  }

  showConfirmPanel() {
    // ガイドを確定パネルに置き換え
    const guide = this.overlayEl?.querySelector(".area-draw-guide")
    if (guide) {
      guide.innerHTML = `
        <div class="area-draw-confirm__info">
          <span class="area-draw-confirm__radius">
            半径: ${this.circleData.radius_km.toFixed(1)} km
          </span>
        </div>
        <div class="area-draw-confirm__actions">
          <button type="button" class="area-draw-btn area-draw-btn--secondary">
            描き直す
          </button>
          <button type="button" class="area-draw-btn area-draw-btn--primary">
            決定
          </button>
        </div>
      `
      guide.className = "area-draw-confirm"

      // ボタンイベント
      const redrawBtn = guide.querySelector(".area-draw-btn--secondary")
      const confirmBtn = guide.querySelector(".area-draw-btn--primary")
      redrawBtn.addEventListener("click", () => this.redraw())
      confirmBtn.addEventListener("click", () => this.confirmArea())
    }
  }

  hideConfirmPanel() {
    const confirm = this.overlayEl?.querySelector(".area-draw-confirm")
    if (confirm) {
      confirm.innerHTML = `
        <div class="area-draw-guide__header">
          <div class="area-draw-guide__icon">
            <i class="bi bi-hand-index"></i>
          </div>
          <div class="area-draw-guide__text">
            地図上で円を描くように<br>エリアをなぞってください
          </div>
        </div>
        <div class="area-draw-guide__actions">
          <button type="button" class="area-draw-guide__cancel-btn">
            戻る
          </button>
        </div>
      `
      confirm.className = "area-draw-guide"

      const cancelBtn = confirm.querySelector(".area-draw-guide__cancel-btn")
      cancelBtn.addEventListener("click", () => this.backToMoveMode())
    }
  }

  // ============================================
  // アクション
  // ============================================

  confirmArea() {
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
    // 確定パネルをガイドに戻す
    const confirm = this.overlayEl?.querySelector(".area-draw-confirm")
    if (confirm) {
      confirm.className = "area-draw-guide"
    }
    this.backToMoveMode()
  }

  cancel() {
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
    this.hideOverlay()
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
