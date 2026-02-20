import "@hotwired/turbo-rails"
import "controllers/application"
import "bootstrap"

// ローディングオーバーレイ表示（グローバル関数）
window.showCreatePlanLoading = function(message = "プランを準備しています...") {
  // auth-cardを非表示にして背景のローディングを見せる
  const authCard = document.querySelector(".auth-card")
  if (authCard) {
    authCard.style.opacity = "0"
    authCard.style.pointerEvents = "none"
  }

  // ローディングオーバーレイを表示（なければ作成）
  let overlay = document.getElementById("create-plan-loading")
  if (!overlay) {
    overlay = document.createElement("div")
    overlay.id = "create-plan-loading"
    overlay.className = "create-plan-loading"
    document.body.appendChild(overlay)
  }
  overlay.innerHTML = `
    <div class="create-plan-loading__content">
      <i class="fa-solid fa-spinner fa-spin fa-2x"></i>
      <p>${message}</p>
    </div>
  `
  overlay.hidden = false
}

// Service Worker登録（PWA対応）
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker.js")
}

// 地図初期化
import "plans/init_map_edit"
import "plans/init_map_show"
import "plans/plan_data"
import "spots/init_map_show"