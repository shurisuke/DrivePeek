document.addEventListener("turbo:load", function() {
  // 要素を取得
  const hamburger = document.querySelector("#Hamburger");
  const spMenu = document.querySelector(".sp__menu");
  const menuLinks = document.querySelectorAll("#menu__hamburger__nav li a");

  // クリックイベントを設定
  hamburger.addEventListener("click", function() {
    // ① ハンバーガーボタンのクラスを切り替え
    this.classList.toggle("js-menu-open");

    // ② メニュー本体のクラスを切り替え
    spMenu.classList.toggle("js-open");

    // ③ メニュー内のリンクのクラスを切り替え
    menuLinks.forEach(function(link) {
      link.classList.toggle("js-menu-open");
    });
  });
});
