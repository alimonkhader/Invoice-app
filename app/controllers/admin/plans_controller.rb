module Admin
  class PlansController < BaseController
    before_action :set_plan, only: %i[edit update]

    def index
      authorize Plan
      @plans = Plan.ordered
      @plan = Plan.new(active: true)
    end

    def create
      authorize Plan
      @plans = Plan.ordered
      @plan = Plan.new(plan_params)

      if @plan.save
        redirect_to admin_plans_path, notice: "Plan created successfully."
      else
        render :index, status: :unprocessable_entity
      end
    end

    def edit
      authorize @plan
    end

    def update
      authorize @plan

      if @plan.update(plan_params)
        redirect_to admin_plans_path, notice: "Plan updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_plan
      @plan = Plan.find(params[:id])
    end

    def plan_params
      params.require(:plan).permit(:name, :code, :price, :invoice_limit, :duration_months, :excel_reports, :description, :active, :position)
    end
  end
end
