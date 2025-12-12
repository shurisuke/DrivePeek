// ================================================================
// プラン作成トリガー
// 用途: プラン作成ボタン押下時に位置情報を取得してからplans#create に誘導
// ================================================================
document.querySelectorAll(".create-plan-trigger").forEach((el) => {
  el.addEventListener("click", (event) => {
    event.preventDefault();

    const createPlan = (lat, lng) => {

      fetch("/plans", {  // feachでHTTPリクエストを送信
        method: "POST",
        headers: {
          "Content-Type": "application/json",  // json型を宣言
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content  // CSFR対策
        },
        body: JSON.stringify({ lat, lng })  // lat,lngをJSON形式の文字列に変換して送信
      }).then((response) => {
        if (response.redirected) {
          window.location.href = response.url;  // レスポンス取得成功時：リダイレクトで次のページへ
        } else {
          alert("プラン作成に失敗しました");  // レスポンス取得失敗時：アラートで通知
        }
      });
    };

    if (navigator.geolocation) {  // ブラウザのGeolocationAPIが使用可能である時、現在地(緯度経度)を取得してプラン作成処理発火
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const lat = position.coords.latitude;
          const lng = position.coords.longitude;
          createPlan(lat, lng);
        },
        () => {  // 位置情報取得失敗時、東京駅の位置でプラン作成処理発火
          alert("現在地の取得に失敗しました。東京を出発地点としてプランを作成します。");
          createPlan(35.681236, 139.767125);
        }
      );
    } else {  // ブラウザのGeolocationAPIが使用できない時、東京駅の位置でプラン作成処理発火
      alert("位置情報が取得できません。東京を出発地点としてプランを作成します。");
      createPlan(35.681236, 139.767125);
    }
  });
});
