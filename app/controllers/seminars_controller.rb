class SeminarsController < ApplicationController
    
    before_action :logged_in_user, only: [:create]
    before_action :redirect_for_non_admin,    only: [:index]
    before_action :correct_seminar_user, only: [:destroy]
    
    def new
        @seminar = Seminar.new
        @this_teacher_can_edit = true
        update_current_class
    end
    
    def create
        @seminar = Seminar.new(seminar_params)
        if @seminar.save
            @creating_teacher = Teacher.find(params[:seminar][:teacher_id])
            @seminar.teachers << @creating_teacher
            
            edit_permission_for_creating_teacher
            update_current_class
            
            flash[:success] = "Class Created"
            redirect_to edit_seminar_path(@seminar)
        else
            render 'seminars/new'
        end
    end

    def index
        if !params[:search].blank?
          @seminars = Seminar.paginate(page: params[:page]).search(params[:search], params[:whichParam])
        else
          @seminars = Seminar.paginate(page: params[:page])
        end
    end
  
    def show
        @seminar = Seminar.find(params[:id])
        @teachers = @seminar.teachers
        update_current_class
    end
    
    def edit
        @seminar = Seminar.find(params[:id])
        @teacher = current_user
        set_editing_privilege
    end

    def update
        @seminar = Seminar.find(params[:id])
        if params[:priorities]
            set_priorities
        elsif params[:pretest_on]
            set_pretests
        elsif params[:seminar]
            @old_objectives = @seminar.objective_ids
            add_pre_reqs_to_seminar if @seminar.update(seminar_params)
        end
        flash[:success] = "Class Updated"
        redirect_to seminar_path(@seminar)
        #set_checkpoint_due_dates
        #@seminar.update_attributes(seminar_params)
        
    end
    
    def destroy
        @seminar = Seminar.find(params[:id])
        @seminar.destroy
        flash[:success] = "Class Deleted"
        redirect_to current_user
    end






    ### Sub-menus for editing seminar
    
    def copy_due_dates
        @seminar = Seminar.find(params[:id])
        first_seminar = current_user.first_seminar
        @seminar.update(:checkpoint_due_dates => first_seminar.checkpoint_due_dates)
        flash[:success] = "Checkpoint Due Dates Updated"
        redirect_to edit_seminar_path(@seminar)
    end
    
    def due_dates
        @seminar = Seminar.find(params[:id])
        set_editing_privilege
    end
    
    def objectives
        @seminar = Seminar.find(params[:id])
        set_editing_privilege
        @objectives = @seminar.objectives
    end
    
    def pretests
        @seminar = Seminar.find(params[:id])
        set_editing_privilege
        @objectives = @seminar.objectives
        @pretests = @seminar.objective_seminars.where(:pretest => 1).map(&:objective)
    end
    
    def priorities
        @seminar = Seminar.find(params[:id])
        set_editing_privilege
    end
    
    def scoresheet
        @seminar = Seminar.find(params[:id])
        @teacher = current_user
        @school = @teacher.school
        @students = @seminar.students.order(:last_name)
        @term = params[:term].to_i
        @show_all = params[:show_all]
        @pretests = params[:pretests].to_s
        
        col_to_use = :points_this_term
        if @pretests == "true"
            col_to_use = :pretest_score
        end
        
        gather_objectives_and_scores
        @scores = @seminar.obj_studs_for_seminar
            .pluck(:user_id, :objective_id, col_to_use)
            .reduce({}) do |result, (student, obj, points)|
                result[student] ||= {}
                result[student][obj] = points
                result
            end
        if @scores.empty?
            @seminar.students.each do |stud|
                @scores[stud.id] = {}
            end
        end
        update_current_class
    end
    
    def shared_teachers
        @seminar = Seminar.find(params[:id])
        set_editing_privilege
        @school = @seminar.school
    end
    
    def update_scoresheet
        @seminar = Seminar.find(params[:id])
        buncha_scores = params[:scores]
        old_scores = eval(params[:old_scores])
        buncha_scores.each do |key_x|
            stud_id = key_x.to_i
            buncha_scores[key_x].each do |key_y, value|
                obj_id = key_y.to_i
                this_val = Integer(value) rescue nil
                if this_val && this_val != old_scores[stud_id][obj_id]
                    this_quiz = Quiz.find_or_create_by(:user_id => stud_id,
                        :objective_id => obj_id,
                        :origin => "manual")
                    this_quiz.update(:total_score => this_val,
                        :seminar => @seminar)
                end
            end
        end
        redirect_to scoresheet_seminar_path(@seminar, :show_all => true)
    end
    
    def usernames
        @seminar = Seminar.find(params[:id])
        @students = @seminar.students
    end
    

    
    private 
        def seminar_params
            params.require(:seminar).permit(:name, :consultantThreshold, :default_buck_increment, :school_year, objective_ids: [], teacher_ids: [])
        end
        
        def add_pre_reqs_to_seminar
            if @seminar.objective_ids != @old_objectives
                @seminar.objective_seminars.each do |os|
                    os.addPreReqs
                end
            end
        end
        
        def correct_seminar_user
            @seminar = Seminar.find(params[:id])
            redirect_to(login_url) unless current_user && (current_user.type == "Admin" || current_user.can_edit_this_seminar(@seminar))
        end
        
        def edit_permission_for_creating_teacher
            @seminar.seminar_teachers.find_by(:user => @creating_teacher).update(:can_edit => true, :accepted => true) 
        end
        
        def set_checkpoint_due_dates
            date_array = [[],[],[],[]]
            params[:seminar][:checkpoint_due_dates].each do |level_x|
                x = level_x.to_i
                params[:seminar][:checkpoint_due_dates][level_x].each do |level_y|
                    y = level_y.to_i
                    this_date = params[:seminar][:checkpoint_due_dates][level_x][level_y]
                    date_array[x][y] = (this_date) if this_date.present?
                end
            end
            @seminar.checkpoint_due_dates = date_array 
        end
        
        def set_editing_privilege
            @this_teacher_can_edit = current_user.can_edit_this_seminar(@seminar) 
        end
        
        def gather_objectives_and_scores
            if @show_all == "false"
                pre_objectives = @seminar.obj_studs_for_seminar.where("points_this_term > ?", 0).map(&:objective).uniq
            else
                pre_objectives = @seminar.objectives
            end
            @objectives = pre_objectives.sort_by(&:name)
        end
        
        def set_pretests
            @seminar.objective_seminars.where.not(:id => params[:pretest_on]).each do |obj_sem|
                obj_sem.update(:pretest => 0)
                @seminar.students.each do |stud|
                    this_obj_stud = stud.objective_students.find_by(:objective => obj_sem.objective)
                    this_obj_stud.update(:pretest_keys => 0) if this_obj_stud
                end
            end
            @seminar.objective_seminars.where(:id => params[:pretest_on]).each do |obj_sem|
                obj_sem.update(:pretest => 1)
                @seminar.students.each do |stud|
                    this_obj_stud = stud.objective_students.find_by(:objective => obj_sem.objective)
                    this_obj_stud.update(:pretest_keys => 2) if this_obj_stud
                end
            end
        end
        
        def set_priorities
            if params[:priorities]
                params[:priorities].each do |key, value|
                    @objective_seminar = ObjectiveSeminar.find(key)
                    @objective_seminar.update(:priority => value)
                end
            end
        end
        

        
end
