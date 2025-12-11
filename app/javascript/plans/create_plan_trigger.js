// create_plan_trigger.js
document.querySelectorAll(".create-plan-trigger").forEach((el) => {
  el.addEventListener("click", (event) => {
    event.preventDefault();

    const createPlan = (lat, lng) => {
      fetch("/plans", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ lat, lng })
      }).then((response) => {
        if (response.redirected) {
          window.location.href = response.url;
        } else {
          alert("プラン作成に失敗しました");
        }
      });
    };

    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const lat = position.coords.latitude;
          const lng = position.coords.longitude;
          createPlan(lat, lng);
        },
        () => {
          alert("現在地の取得に失敗しました。東京を出発地点としてプランを作成します。");
          // 東京駅の緯度経度
          createPlan(35.681236, 139.767125);
        }
      );
    } else {
      alert("位置情報が取得できません。東京を出発地点としてプランを作成します。");
      createPlan(35.681236, 139.767125);
    }
  });
});
