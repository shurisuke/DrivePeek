import "@hotwired/turbo-rails"
import "controllers"
import "bootstrap"
import "@popperjs/core"
import $ from 'jquery'
window.$ = $
window.jQuery = $
$(function() {
  $("#Hamburger").click(function(){
    $(this).toggleClass('js-menu-open');
    $('.sp__menu').toggleClass('js-open');
    $('#menu__hamburger__nav li a').toggleClass('js-menu-open');
  });
});