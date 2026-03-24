class AccountSettingsController < ApplicationController
  before_action :require_account_authentication

  def show
    @user = current_account_user
  end

  def update
    @user = current_account_user

    if @user.update(account_settings_params)
      redirect_to settings_path, notice: "Account settings updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def account_settings_params
    params.require(:user).permit(:gst_enabled)
  end
end
