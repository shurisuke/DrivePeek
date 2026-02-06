import "@hotwired/turbo-rails"
import "controllers/application"
import "bootstrap"

// Service Worker登録（PWA対応）
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker.js")
}

// 地図初期化
import "plans/init_map_edit"
import "plans/init_map_show"
import "plans/plan_data"
import "spots/init_map_show"