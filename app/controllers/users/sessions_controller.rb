module Users
  class SessionsController < Devise::SessionsController
    def create
      user = User.find_for_authentication(email: params.dig(:user, :email).to_s.strip.downcase)

      unless user&.account_admin?
        flash.now[:alert] = "Invalid email or password."
        self.resource = resource_class.new(sign_in_params)
        clean_up_passwords(resource)
        return render :new, status: :unprocessable_entity
      end

      unless user.active?
        flash.now[:alert] = "Your account is not active yet. Complete payment or contact support."
        self.resource = resource_class.new(sign_in_params)
        clean_up_passwords(resource)
        return render :new, status: :unprocessable_entity
      end

      self.resource = user
      return super if resource.valid_password?(params.dig(:user, :password).to_s)

      flash.now[:alert] = "Invalid email or password."
      clean_up_passwords(resource)
      render :new, status: :unprocessable_entity
    end
  end
end
