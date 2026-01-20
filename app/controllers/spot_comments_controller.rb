class SpotCommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_spot
  before_action :set_comment, only: :destroy

  def create
    @comment = @spot.spot_comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @spot }
      end
    else
      render turbo_stream: turbo_stream.replace(
        "comment-form-errors",
        partial: "spot_comments/form_errors",
        locals: { comment: @comment }
      )
    end
  end

  def destroy
    if @comment.user == current_user
      @comment.destroy
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @spot }
      end
    else
      head :forbidden
    end
  end

  private

  def set_spot
    @spot = Spot.find(params[:spot_id])
  end

  def set_comment
    @comment = @spot.spot_comments.find(params[:id])
  end

  def comment_params
    params.require(:spot_comment).permit(:body)
  end
end
