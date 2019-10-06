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
        @creating_teacher = Teacher.find(params[:seminar][:teacher_id])
        @seminar.owner = @creating_teacher
        if @seminar.save
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
          @seminars = Seminar.order(:name).paginate(page: params[:page]).search(params[:search], params[:whichParam])
        else
          @seminars = Seminar.order(:name).paginate(page: params[:page])
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
        elsif params[:seminar][:checkpoint_due_dates]
            set_checkpoint_due_dates
        elsif params[:seminar][:term]
            these_sems = [@seminar]
            these_sems = current_user.seminars_i_can_edit if params[:repeat]
            these_sems.each do |sem|
                sem.update(seminar_params)
                reset_all_student_grades(sem) if params[:reset]
            end
        else
            @old_objectives = @seminar.objective_ids
            add_pre_reqs_to_seminar if @seminar.update(seminar_params)
        end
        flash[:success] = "Class Updated"
        redirect_to seminar_path(@seminar)
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
        redirect_to seminar_path(@seminar)
    end
    
    def change_owner
        @seminar = Seminar.find(params[:id])
        @teacher = Teacher.find(params[:new_owner])
    
        @seminar.update(:owner => @teacher)
        SeminarTeacher.find_or_create_by(:user => @teacher, :seminar => @seminar).update(:can_edit => true)
        
        flash[:success] = "Class Owner Updated"
        redirect_to @seminar
    end
    
    def change_term
       @seminar = Seminar.find(params[:id]) 
       @current_term = @seminar.term
       @current_checkpoint = @seminar.which_checkpoint
    end
    
    def due_dates
        @seminar = Seminar.find(params[:id])
        set_editing_privilege
    end
    
    def objectives
        @seminar = Seminar.find(params[:id])
        set_editing_privilege
        @objectives = Objective.where("extent = ? OR user_id = ?","public",current_user.id).order(:name)
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
    
    def quiz_grading
        @seminar = Seminar.find(params[:id])
        @quizzes_to_grade = @seminar.quizzes_to_grade
    end
    
    def remove
        @seminar = Seminar.find(params[:id])
    end
    
    def scoresheet
        @seminar = Seminar.find(params[:id])
        @teacher = current_user
        @school = @teacher.school
        @students = @seminar.students.order(:last_name)
        @term = params[:term].to_i
        
        @show_all = params[:show_all] || "true"
        which_score_param = params[:which_scores] || :points_this_term
        param_hash = {"points_this_term" => "Current Term", "points_all_time" => "All Time", "pretest_score" => "Pretest"}
        @special_title = "#{param_hash[which_score_param.to_s]} Scores"
        @which_scores = which_score_param.to_sym
        
        gather_objectives_and_scores
        make_empty_objectives
        @scores = @seminar.obj_studs_for_seminar
            .pluck(:user_id, :objective_id, @which_scores)
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
        which_scores = params[:which_scores]
        buncha_scores.each do |key_x|
            stud_id = key_x.to_i
            buncha_scores[key_x].each do |key_y, value|
                obj_id = key_y.to_i
                this_val = Integer(value) rescue nil
                if this_val && this_val != old_scores[stud_id][obj_id]
                    this_quiz = Quiz.find_or_create_by(:user_id => stud_id,
                        :objective_id => obj_id,
                        :origin => "manual_#{which_scores}")
                    this_quiz.update(:total_score => this_val,
                        :seminar => @seminar)
                end
            end
        end
        redirect_to scoresheet_seminar_path(@seminar, :show_all => true)
    end
    
    def usernames
        @seminar = Seminar.find(params[:id])
        update_current_class
        @students = @seminar.students
    end
    

    
    private 
        def seminar_params
            params.require(:seminar).permit(:name, :consultantThreshold, :default_buck_increment, 
                :school_year, :term, :which_checkpoint, objective_ids: [], teacher_ids: [])
        end
        
        def add_pre_reqs_to_seminar
            if @seminar.objective_ids != @old_objectives
                @seminar.objective_seminars.each do |os|
                    os.add_preassigns
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
            date_array = [[0], [],[],[],[]]
            params[:seminar][:checkpoint_due_dates].each do |level_x|
                x = level_x.to_i
                params[:seminar][:checkpoint_due_dates][level_x].each do |level_y|
                    y = level_y.to_i
                    this_date = params[:seminar][:checkpoint_due_dates][level_x][level_y]
                    date_array[x][y] = (this_date) if this_date.present?
                end
            end
            @seminar.checkpoint_due_dates = date_array
            @seminar.save
        end
        
        def set_editing_privilege
            @this_teacher_can_edit = current_user.can_edit_this_seminar(@seminar) 
        end
        
        def gather_objectives_and_scores    
            if @show_all == "false"
                pre_objectives = @seminar.obj_studs_for_seminar.where("#{@which_scores} > ?", 0).map(&:objective).uniq
            else
                pre_objectives = @seminar.objectives
            end
            @objectives = pre_objectives.sort_by(&:name)
        end
        
        def make_empty_objectives
            while @objectives.count < 14
                new_objective = Objective.new(:name => "")
                @objectives.push(new_objective)
            end
        end
        
        def reset_all_student_grades(seminar)
            seminar.obj_studs_for_seminar.update_all(:points_this_term => 0) 
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
