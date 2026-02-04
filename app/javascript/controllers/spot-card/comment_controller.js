import { Controller } from "@hotwired/stimulus"
import { showInfoWindowWithFrame } from "map/infowindow"

// ================================================================
// SpotCard::CommentController
// 用途: スポットカードのコメントボタンをクリック時に
//       InfoWindowを開き、コメントタブを自動選択する
// ================================================================

export default class extends Controller {
  static values = {
    spotId: Number,
    placeId: String,
    lat: Number,
    lng: Number,
    name: String,
    address: String
  }

  openComment(event) {
    event.preventDefault()
    event.stopPropagation()

    const position = new google.maps.LatLng(this.latValue, this.lngValue)

    showInfoWindowWithFrame({
      anchor: position,
      spotId: this.spotIdValue,
      placeId: this.placeIdValue,
      name: this.nameValue,
      address: this.addressValue,
      lat: this.latValue,
      lng: this.lngValue,
      showButton: false,
      defaultTab: "comment"
    })
  }
}
