class ObjectivesController < ApplicationController
  
  before_action only: [:delete, :destroy, :update] do
    correct_owner(Objective)
  end
  
  include BuildPreReqLists
  include SetPermissions
  include LabelsList
  
  
  def new
    @objective = Objective.new
    new_objective_stuff
  end
  
  def create
    @objective = Objective.new(objective_params_basic)
    
    if @objective.save
      flash[:success] = "Objective Created"
      redirect_to objective_path(@objective)
    else # This actually shouldn't be able to happen right now, since the controller gives the objective a name
      new_objective_stuff
      render 'new'
    end
  end
  
  def show
    @objective = Objective.find(params[:id])
  end
  
  def index
    if !params[:search].blank?
      if current_user.type == "Admin"
        @objectives = Objective.paginate(page: params[:page]).search(params[:search], params[:whichParam]).order(:name)
      else
        @objectives = Objective.where("user_id = ? OR extent = ?", current_user, "public").paginate(page: params[:page]).search(params[:search], params[:whichParam]).order(:name)
      end
    end
    
    if current_user.type == "Admin"
      @objectives ||= Objective.paginate(page: params[:page]).order(:name)
    elsif current_user.type == "Student"
      redirect_to login_url
    else
      @objectives ||= Objective.where("user_id = ? OR extent = ?", current_user.id, "public").paginate(page: params[:page]).order(:name)
    end
  end

  def edit
    @objective = Objective.find(params[:id])
    @fields = fields_list
    set_permissions(@objective)
  end

  def update
    @objective = Objective.find(params[:id])
    @old_seminars = @objective.seminar_ids
    @old_pre_reqs = @objective.preassign_ids
    redirect_path = @objective
    
    params_to_use = objective_params_basic
    @which_params = params[:objective][:which_params]
    if @which_params == "seminars"
      params_to_use = objective_params_seminars
    elsif @which_params == "labels"
      params_to_use = objective_params_labels
      @objective.label_ids = [] if params[:objective][:label_ids].nil?
      redirect_path = quantities_objective_path(@objective)
    elsif @which_params == "pre_reqs"
      params_to_use = objective_params_preassigns
      @objective.preassign_ids = [] if params[:objective][:preassign_ids].nil?
    elsif @which_params == "worksheets"
      params_to_use = objective_params_worksheets
      @objective.worksheet_ids = [] if params[:objective][:worksheet_ids].nil?
    end
    
    
    if @objective.update_attributes(params_to_use)
      pre_reqs_and_set_ready
      flash[:success] = "Objective Updated"
      redirect_to redirect_path
    end
  end
  
  def destroy
    @objective = Objective.find(params[:id])
    
    oldAssignId = @objective.id
    SeminarStudent.where(:teach_request => oldAssignId).update_all(:teach_request => nil)
    SeminarStudent.where(:learn_request => oldAssignId).update_all(:learn_request => nil)
    
    @objective.destroy
    flash[:success] = "Objective Deleted"
    
    redirect_to objectives_path
  end
  
  
  
  ## Submenu Actions
  
    
  def include_files
    @objective = Objective.find(params[:id])
    @worksheet = Worksheet.new
    @current_worksheets = @objective.worksheets.order(:name)
    set_permissions(@objective)
    @worksheets = Worksheet.all
  end
  
  def include_labels
    @objective = Objective.find(params[:id])
    set_permissions(@objective)
    @labels = labels_to_offer
  end
  
  def include_seminars
    @objective = Objective.find(params[:id])
  end
  
  def keys_for_objective
    @objective = Objective.find(params[:id])
  end
  
  def pre_reqs
    @objective = Objective.find(params[:id])
    set_permissions(@objective)
    @pre_req_list = build_pre_req_list(@objective)
  end
  
  def quantities
    @objective = Objective.find(params[:id])
    @label_objectives = @objective.label_objectives.sort_by{|x| [x.label.name]}
    set_permissions(@objective)
  end
  
  def whole_class_keys
    @objective = Objective.find(params[:id])
    @seminar = Seminar.find(params[:sem_id])
    new_keys = params[:new_keys]
    @seminar.students.each do |student|
      @objective.objective_students.find_by(:user => student).update_keys("teacher_granted", new_keys)
    end
  end
  
  
  
  
  
  private
    def objective_params_basic
        params.require(:objective).permit(:name, :catchy_name, :extent, :objective_number, :user_id, :topic_id)
    end
    
    def objective_params_labels
      params.require(:objective).permit(label_ids: [])
    end
    
    def objective_params_preassigns
      params.require(:objective).permit(preassign_ids: [])
    end
    
    def objective_params_seminars
        params.require(:objective).permit(seminar_ids: [])
    end
    
    def objective_params_worksheets
      params.require(:objective).permit(worksheet_ids: [])
    end
    
    # If preassigns or seminars are changed, add new preassigns to every class that doesn't yet have them.
    def add_pre_reqs_to_seminars
      unless @objective.seminar_ids == @old_seminars && @objective.preassign_ids == @old_pre_reqs
        @objective.objective_seminars.each do |o_sem|
          o_sem.add_preassigns
        end
      end
    end
    
    # If preassigns are changed, set_ready for all students
    def set_ready_for_all_students
      unless @objective.preassign_ids == @old_pre_reqs
        @objective.objective_students.each do |o_stud|
          o_stud.set_ready
        end
      end
    end
    
    
    def new_objective_stuff
      @objective.name = "Objective #{Objective.count}"
      @objective.user = current_user
      @labels = labels_to_offer
      @fields = Field.includes(domains: :topics)
      set_permissions(@objective)
      @pre_req_list = build_pre_req_list(@objective)
    end
    
    def pre_reqs_and_set_ready
      if @which_params == "pre_reqs" || @which_params == "seminars"
        add_pre_reqs_to_seminars
        set_ready_for_all_students
      end
    end
          
end
