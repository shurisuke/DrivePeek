# frozen_string_literal: true

module ApiMocks
  module GoogleMaps
    def stub_directions_api(response: nil, status: "OK")
      response ||= {
        "status" => status,
        "routes" => [ {
          "legs" => [ {
            "duration" => { "value" => 1800, "text" => "30分" },
            "distance" => { "value" => 10500, "text" => "10.5 km" }
          } ],
          "overview_polyline" => { "points" => "encoded_polyline_string" }
        } ]
      }

      stub_request(:get, /maps.googleapis.com\/maps\/api\/directions/)
        .to_return(status: 200, body: response.to_json, headers: { "Content-Type" => "application/json" })
    end

    def stub_geocoding_api(response: nil)
      response ||= {
        "status" => "OK",
        "results" => [ {
          "formatted_address" => "東京都渋谷区渋谷1-1-1",
          "geometry" => { "location" => { "lat" => 35.6580, "lng" => 139.7016 } },
          "address_components" => [
            { "long_name" => "東京都", "types" => [ "administrative_area_level_1" ] },
            { "long_name" => "渋谷区", "types" => [ "locality" ] }
          ]
        } ]
      }

      stub_request(:get, /maps.googleapis.com\/maps\/api\/geocode/)
        .to_return(status: 200, body: response.to_json, headers: { "Content-Type" => "application/json" })
    end

    def stub_places_api(response: nil)
      response ||= {
        "status" => "OK",
        "result" => {
          "place_id" => "ChIJtest123",
          "name" => "テストスポット",
          "formatted_address" => "東京都渋谷区渋谷1-1-1",
          "geometry" => { "location" => { "lat" => 35.6580, "lng" => 139.7016 } },
          "photos" => [
            { "photo_reference" => "test_photo_ref_1" },
            { "photo_reference" => "test_photo_ref_2" }
          ]
        }
      }

      stub_request(:get, /maps.googleapis.com\/maps\/api\/place/)
        .to_return(status: 200, body: response.to_json, headers: { "Content-Type" => "application/json" })
    end

    def stub_places_nearby_api(response: nil)
      response ||= {
        "status" => "OK",
        "results" => [ {
          "place_id" => "ChIJtest123",
          "name" => "テストスポット",
          "geometry" => { "location" => { "lat" => 35.6580, "lng" => 139.7016 } }
        } ]
      }

      stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/nearbysearch/)
        .to_return(status: 200, body: response.to_json, headers: { "Content-Type" => "application/json" })
    end
  end
end

RSpec.configure do |config|
  config.include ApiMocks::GoogleMaps
end
