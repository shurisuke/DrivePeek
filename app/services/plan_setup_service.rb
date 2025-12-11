class PlanSetupService
  attr_reader :plan

  def initialize(user:, lat:, lng:)
    @user = user
    @lat = lat
    @lng = lng
  end

  def setup
    ActiveRecord::Base.transaction do
      @plan = Plan.create!(user: @user, title: "")

      start_point = StartPoint.build_from_location(plan: @plan, lat: @lat, lng: @lng)
      @plan.start_point = start_point
      @plan.save!

      goal_point = GoalPoint.build_from_start_point(plan: @plan, start_point: start_point)
      @plan.goal_point = goal_point
      @plan.save!
    end

    @plan
  end
end