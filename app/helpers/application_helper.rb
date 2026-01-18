module ApplicationHelper
  def remaining_minutes(sent_at, duration: 30.minutes)
    ((sent_at + duration - Time.current) / 60).ceil
  end
end
