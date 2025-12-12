# app/models/start_point.rb
class StartPoint < ApplicationRecord
  belongs_to :plan

  validates :lat, :lng, :address, presence: true

  def self.build_from_location(plan:, lat:, lng:)
    attrs = ReverseGeocoder.lookup_address(lat: lat, lng: lng)
    plan.build_start_point(attrs)
  end
end