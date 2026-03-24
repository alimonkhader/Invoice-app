class UserSessionsController < ApplicationController
  def new
  end

  def create
    user = User.active_account_admins.find_by(email: params[:email].to_s.strip.downcase)

    if user&.authenticate(params[:password].to_s)
      reset_session
      session[:user_id] = user.id
      redirect_to invoices_path, notice: "Login successful."
    else
      flash.now[:alert] = "Invalid email or password, or the plan payment is still pending."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "Logged out successfully."
  end
end
