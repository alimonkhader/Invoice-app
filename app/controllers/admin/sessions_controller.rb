module Admin
  class SessionsController < ApplicationController
    def new
    end

    def create
      admin = User.admins.find_by(email: params[:email].to_s.strip.downcase)

      if admin&.valid_password?(params[:password].to_s)
        reset_session
        session[:admin_id] = admin.id
        redirect_to admin_plans_path, notice: "Admin login successful."
      else
        flash.now[:alert] = "Invalid admin credentials."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session.delete(:admin_id)
      redirect_to root_path, notice: "Admin logged out."
    end
  end
end
