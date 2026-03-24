module Users
  class PasswordsController < Devise::PasswordsController
    def create
      email = resource_params[:email].to_s.strip.downcase
      user = User.account_admins.find_by(email: email)

      if user.present?
        user.send_reset_password_instructions
      end

      redirect_to new_user_session_path, notice: "If that email exists in our system, password reset instructions have been sent."
    end
  end
end
