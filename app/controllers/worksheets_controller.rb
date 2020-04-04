class WorksheetsController < ApplicationController
    
    include SetPermissions
    
    def new
        @worksheet = Worksheet.new
    end
    
    def create
      @worksheet = Worksheet.new(worksheet_params)
      @worksheet.user = current_user
  
      if @worksheet.save
        flash[:success] = "File Successfully Uploaded"
        this_obj_id = params[:worksheet][:objective] 
        if this_obj_id == nil
          redirect_to current_user
        else
          @objective = Objective.find_by(this_obj_id)
          @worksheet.objectives << @objective
          redirect_to @objective
        end
      else
        render 'new'
      end
    end
    
    def index
        if current_user
            if current_user.type == "Admin"
                @worksheets = Worksheet.all
            else
                @worksheets = Worksheet.where("extent = ? OR user_id = ?", "public", current_user.id)
            end
        else
            @worksheets = Worksheet.where(:extent => "public")
        end
    end
    
    def show
        @worksheet = Worksheet.find(params[:id])
        set_permissions(@worksheet)
    end
    
    def edit
        @worksheet = Worksheet.find(params[:id])
        set_permissions(@worksheet)
        render 'show' if @assign_permission == "other"
    end
    
    def update
        @worksheet = Worksheet.find(params[:id])
        
        if @worksheet.update_attributes(worksheet_params)
            flash[:success] = "File Updated"
            redirect_to worksheets_path
        else
            set_permissions(@worksheet)
            render 'edit'
        end
    end
    
    def destroy
      @worksheet = Worksheet.find(params[:id])
      @worksheet.destroy
      flash[:success] = "File Deleted"
      redirect_to worksheets_path
    end
    
    private
    
        def worksheet_params
            params.require(:worksheet).permit(:name, :uploaded_file, :extent, :description)
        end
    
end
