// navibar.js
document.addEventListener("turbo:load", () => {
  const tabButtons = document.querySelectorAll(".tab-btn");
  const tabContents = document.querySelectorAll(".tab-content");

  tabButtons.forEach((btn) => {
    btn.addEventListener("click", () => {
      const selected = btn.dataset.tab;

      // ボタンの active 状態を切り替え
      tabButtons.forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");

      // コンテンツの表示切り替え
      tabContents.forEach((content) => {
        content.classList.remove("active");
        if (content.classList.contains(`tab-${selected}`)) {
          content.classList.add("active");
        }
      });
    });
  });
});