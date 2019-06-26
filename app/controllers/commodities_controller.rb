class CommoditiesController < ApplicationController
    
    # before_action   :commodity_permission, :except => [:index]
    
    def new
        @commodity = Commodity.new
        @school_id = params[:school_id]
        @user_id = params[:user_id]
        redirect_to login_url if !@school_id && !@user_id
        if @user_id
            @teacher = Teacher.find(@user_id)
            redirect_to login_url unless current_user == @teacher
        end
    end
    
    def create
        @commodity = Commodity.new(commodity_params)
        if @commodity.save
            set_commode_variables
            flash[:success] = "New Item Created for #{@market_name}"
            redirect_to commodities_path(:"#{@source_type}_id" => @source.id)
        else
            render 'new'
        end
    end

    def index
        @student = current_user
        
        set_commode_variables
        @commodities = @source.commodities.paginate(:per_page => 6, page: params[:page])
    end
    
    def edit
        @commodity = Commodity.find(params[:id])
    end
    
    def update
        @commodity = Commodity.find(params[:id])
        if params[:use]
            commodity_use
        elsif params[:multiplier]
            commodity_buy
        elsif @commodity.update(commodity_params)
            flash[:success] = "Item Updated"
            if @commodity.school_id
                redirect_to commodities_path(:school_id => @commodity.school_id)
            elsif @commodity.user_id
                redirect_to commodities_path(:user_id => @commodity.user_id)
            else
                redirect_to login_path
            end
        else
          render 'edit'
        end
    end
    
    def destroy
        @commodity = Commodity.find(params[:id])
        school_id = @commodity.school_id
        @commodity.destroy
        flash[:success] = "Item Deleted"
        
        redirect_to commodities_path(:user_id => current_user.id)
    end
    
    private

        def commodity_params
            params.require(:commodity).permit(:name, :image, :school_id, :user_id,
                :current_price, :quantity, :salable, :usable, :deliverable)
        end
        
        def add_stars_to_grade
            if @commodity.name == "Star"
                @seminar = Seminar.find(params[:seminar_id]) 
                @ss = SeminarStudent.find_by(:seminar => @seminar, :user => @student)
                @term = @seminar.term
                old_stars_used = @ss.stars_used_toward_grade[@term]
                @ss.stars_used_toward_grade[@term] = old_stars_used + 1
                @ss.save
            end
        end
        
        def commodity_buy
            @multiplier = params[:multiplier].to_i
            @student = Student.find(params[:student_id])
            if params[:school_or_seminar] == "seminar"
                bucks_to_check = @student.bucks_current(:seminar_id, params[:seminar_id])
            else
                bucks_to_check = @student.bucks_current(:school, @student.school)
            end
            
            sell_allowed = @student.com_quant(@commodity) > 0
            buy_allowed = bucks_to_check > 0 && @commodity.quantity > 0
            if (@multiplier > 0 && buy_allowed) || (@multiplier < 0 && sell_allowed)
                price_paid = @commodity.current_price * @multiplier
                @student.commodity_students.create(:commodity => @commodity, :quantity => @multiplier, 
                    :price_paid => price_paid, :seminar_id => params[:seminar_id], :school_id => params[:school_id])
              
                old_quant = @commodity.quantity
                @commodity.update(:quantity => old_quant - 1)
            end
        end
      
        def commodity_use
            @student = Student.find(params[:student_id])
            @student.commodity_students.create(:commodity => @commodity, :quantity => -1, :price_paid => 0)
            add_stars_to_grade
        end
        
        def set_commode_variables
            @seminar_id = nil
            @edit_commodity_permission = false
            if params[:school_id] || @commodity&.school.present?
                @school_or_seminar = "school"
                if params[:school_id]
                    @source = School.find(params[:school_id])
                else
                    @source = @commodity.school
                end
                @source_type = "school"
                @bucks_current = current_user.bucks_current(:school, @school) if current_user.type == "Student"
                @market_name = @source.market_name
                @edit_commodity_permission = true if current_user.school_admin > 0
            elsif params[:user_id] || @commodity&.user.present?
                @school_or_seminar = "seminar"
                if params[:user_id]
                    @source = Teacher.find(params[:user_id])
                else
                    @source = @commodity.user
                end 
                @source_type = "user"
                @bucks_current = current_user.bucks_current(:seminar, @seminar) if current_user.type == "Student"
                if params[:seminar_id]
                    @seminar = Seminar.find(params[:seminar_id]) 
                    @seminar_id = @seminar.id
                end
                @market_name = "#{@source.name_with_title} Market"
                @edit_commodity_permission = true if current_user = @source
            end
        end
end