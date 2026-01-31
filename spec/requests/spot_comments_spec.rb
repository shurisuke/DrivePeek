# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SpotComments", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:spot) { create(:spot) }

  describe "POST /spots/:spot_id/comments" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "コメントを作成する" do
        expect {
          post spot_comments_path(spot),
               params: { spot_comment: { body: "素晴らしいスポットでした！また行きたいです。" } },
               as: :turbo_stream
        }.to change(SpotComment, :count).by(1)

        expect(response).to have_http_status(:ok)
      end

      it "作成されたコメントの内容が正しい" do
        post spot_comments_path(spot),
             params: { spot_comment: { body: "景色がきれいでした。おすすめです。" } },
             as: :turbo_stream

        comment = SpotComment.last
        expect(comment.body).to eq("景色がきれいでした。おすすめです。")
        expect(comment.user).to eq(user)
        expect(comment.spot).to eq(spot)
      end

      it "バリデーションエラーの場合はエラーを返す" do
        post spot_comments_path(spot),
             params: { spot_comment: { body: "" } },
             as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(SpotComment.count).to eq(0)
      end
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトする" do
        post spot_comments_path(spot),
             params: { spot_comment: { body: "テストコメントです。" } }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /spots/:spot_id/comments/:id" do
    let!(:comment) { create(:spot_comment, user: user, spot: spot) }

    context "ログイン済み・自分のコメントの場合" do
      before { sign_in user }

      it "コメントを削除する" do
        expect {
          delete spot_comment_path(spot, comment), as: :turbo_stream
        }.to change(SpotComment, :count).by(-1)
      end

      it "正常に完了する" do
        delete spot_comment_path(spot, comment), as: :turbo_stream
        expect(response).to have_http_status(:ok)
      end
    end

    context "ログイン済み・他人のコメントの場合" do
      before { sign_in other_user }

      it "forbiddenを返す" do
        delete spot_comment_path(spot, comment)
        expect(response).to have_http_status(:forbidden)
      end

      it "コメントは削除されない" do
        expect {
          delete spot_comment_path(spot, comment)
        }.not_to change(SpotComment, :count)
      end
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトする" do
        delete spot_comment_path(spot, comment)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
