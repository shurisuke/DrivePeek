import Rails from "@rails/ujs"
Rails.start()

import jquery from "jquery"
window.$ = window.jQuery = jquery
window.bootstrap = require("bootstrap")

$(function() {
  $("#Hamburger").click(function(){
    $(this).toggleClass('js-menu-open');
    $('.sp__menu').toggleClass('js-open');
    $('#menu__hamburger__nav li a').toggleClass('js-menu-open');
  });
});
