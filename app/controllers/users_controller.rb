class UsersController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if params[:avatar].present?
      preloaded = Cloudinary::PreloadedFile.new(params[:avatar])         
      raise "Invalid upload signature" if !preloaded.valid?
      @user.avatar = preloaded.identifier
    end

    @user.update_attributes(params.require(:user).permit(:first_name, :last_name, :zipcode, :about_me))

    if @user.valid?
      redirect_to(root_path)
    else
      render(:edit)
    end
  end
end
