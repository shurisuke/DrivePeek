// ================================================================
// planData 取得ユーティリティ
// 用途: window.planData または #map の data-plan から planData を取得する
// ================================================================

export const getPlanDataFromPage = () => {
  // 既存方式（window 直置き）
  if (window.planData) return window.planData;

  // 将来移行用（data属性）
  const mapElement = document.getElementById("map");
  const datasetPlan = mapElement?.dataset?.plan;

  if (datasetPlan) {
    try {
      return JSON.parse(datasetPlan);
    } catch (e) {
      console.warn("🟡 data-plan の JSON パースに失敗しました:", e);
    }
  }

  return null;
};