# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plan::Recalculator do
  let(:user) { create(:user) }
  let(:plan) { create(:plan, user: user) }
  let(:recalculator) { described_class.new(plan) }

  describe "#recalculate!" do
    let(:driving_instance) { instance_double(Plan::Driving, recalculate!: true) }
    let(:timetable_instance) { instance_double(Plan::Timetable, recalculate!: true) }

    before do
      allow(Plan::Driving).to receive(:new).with(plan).and_return(driving_instance)
      allow(Plan::Timetable).to receive(:new).with(plan).and_return(timetable_instance)
    end

    context "デフォルト（schedule: true, route: false）" do
      it "Timetableのみ再計算する" do
        recalculator.recalculate!

        expect(Plan::Driving).not_to have_received(:new)
        expect(Plan::Timetable).to have_received(:new).with(plan)
        expect(timetable_instance).to have_received(:recalculate!)
      end

      it "trueを返す" do
        expect(recalculator.recalculate!).to be true
      end
    end

    context "route: true の場合" do
      it "DrivingとTimetableの両方を再計算する" do
        recalculator.recalculate!(route: true)

        expect(Plan::Driving).to have_received(:new).with(plan)
        expect(driving_instance).to have_received(:recalculate!)
        expect(Plan::Timetable).to have_received(:new).with(plan)
        expect(timetable_instance).to have_received(:recalculate!)
      end

      it "Driving → Timetableの順で実行する" do
        call_order = []
        allow(driving_instance).to receive(:recalculate!) { call_order << :driving; true }
        allow(timetable_instance).to receive(:recalculate!) { call_order << :timetable; true }

        recalculator.recalculate!(route: true)

        expect(call_order).to eq([ :driving, :timetable ])
      end
    end

    context "schedule: false の場合" do
      it "Timetableを再計算しない" do
        recalculator.recalculate!(schedule: false)

        expect(Plan::Timetable).not_to have_received(:new)
      end
    end

    context "route: true, schedule: false の場合" do
      it "Drivingのみ再計算する" do
        recalculator.recalculate!(route: true, schedule: false)

        expect(Plan::Driving).to have_received(:new).with(plan)
        expect(driving_instance).to have_received(:recalculate!)
        expect(Plan::Timetable).not_to have_received(:new)
      end
    end

    context "Drivingが失敗した場合" do
      before do
        allow(driving_instance).to receive(:recalculate!).and_return(false)
      end

      it "falseを返す" do
        expect(recalculator.recalculate!(route: true)).to be false
      end

      it "Timetableは実行しない" do
        recalculator.recalculate!(route: true)

        expect(Plan::Timetable).not_to have_received(:new)
      end
    end

    context "Timetableが失敗した場合" do
      before do
        allow(timetable_instance).to receive(:recalculate!).and_return(false)
      end

      it "falseを返す" do
        expect(recalculator.recalculate!).to be false
      end
    end
  end
end
