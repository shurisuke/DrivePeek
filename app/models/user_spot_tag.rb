class UserSpotTag < ApplicationRecord
  belongs_to :user_spot
  belongs_to :tag
end
