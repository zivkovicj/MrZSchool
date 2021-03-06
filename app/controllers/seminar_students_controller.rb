class SeminarStudentsController < ApplicationController
  respond_to :html, :json
  before_action :correct_ss_user, only: [:destroy, :show, :edit]
  
  include AddStudentStuff


  def create
    # This method is called when the teacher adds an existing student to a class.
    # Or moves a student to a different class. 
    # It is not called when creating a new student.
    @ss = SeminarStudent.create(ss_params)
    @seminar = Seminar.find(@ss.seminar_id)
    @student = Student.find(@ss.user_id)
    @student.update(:sponsor => current_user) if current_user.type == "Teacher"
    refresh_all_obj_sems(@seminar)
    
    old_ss_id = params[:seminar_student][:is_move]
    if old_ss_id
      @old_ss = SeminarStudent.find(old_ss_id)
      old_sem = @old_ss.seminar
      @old_ss.destroy
      refresh_all_obj_sems(old_sem)
    end
    
    redirect_to scoresheet_seminar_url(@seminar)
  end
  
  def show
    setup_ss_vars
    #term = @seminar.term
    delete_broken_quizzes
  
    update_current_class
  end
  
  def update
    @ss = SeminarStudent.find(params[:id])
    if params[:present]
      @ss.update(:present => params[:present])
    else
      req_type = params[:seminar_student][:req_type]
      req_id = params[:seminar_student][:req_id]  
      @ss.write_attribute(:"#{req_type}_request", req_id)
      @ss.save
    end
    respond_with @ss
  end
  
  def destroy
    this_ss = SeminarStudent.find(params[:id])
    @seminar = Seminar.find(this_ss.seminar_id)
    this_ss.destroy
    refresh_all_obj_sems(@seminar)
    
    #Redirect
    flash[:success] = "Student removed from class period"
    redirect_to scoresheet_seminar_url(@seminar)
  end
  
  
  ## Views for submenus
  
  def give_keys
    setup_ss_vars
    
    @objectives = @seminar.objectives.order(:name)
  end
  
  def grades
    @ss = SeminarStudent.find(params[:id])
    @student = @ss.user
    @seminar = @ss.seminar
    
    @objectives = @seminar.objectives.order(:name)
    
    @scores = @student.objective_students.where(:objective => @objectives)
    @quiz_stars_this_term= @scores.sum(:points_this_term)
    @quiz_stars_all_time = @scores.sum(:points_all_time)
    
    @score_hash = @scores
    .pluck(:objective_id, :points_all_time)
    .reduce({}) do |result, (obj, points)|
        result[obj] = points
        result
    end
    
    @learn_options = @student.learn_options(@seminar)
    
  end
  
  
  def move_or_remove
    setup_ss_vars
    
    @new_ss = SeminarStudent.new
    @classes_without_student_list = current_user.seminars.select{|x| !x.students.include?(@student) }
    @classes_with_student_list = current_user.seminars.select{|x| x.students.include?(@student) }
  end
  
  
  def quizzes
    setup_ss_vars
    
    @unfinished_quizzes = @student.all_unfinished_quizzes(@seminar)
    @desk_consulted_objectives = @student.quiz_collection(@seminar, "dc")
    @pretest_objectives = @student.quiz_collection(@seminar, "pretest")
    @teacher_granted_quizzes = @student.quiz_collection(@seminar, "teacher_granted")
    @show_quizzes = @desk_consulted_objectives.present? || @pretest_objectives.present? || @unfinished_quizzes.present? || @teacher_granted_quizzes.present?
    
    # Lock quiz if it's outside seminars set times.
    @quizzes_open = true
    if params[:override]
        password = params[:password]
        @quizzes_open = false if !current_user.teachers.any?{|x| x.authenticate(password)}
    else
        @timescore = (Time.now.hour * 60) + (Time.now.min)
        @quizzes_open = false if @timescore < @seminar.quiz_open_times[0] or @timescore > @seminar.quiz_open_times[1]
        @quizzes_open = false unless @seminar.quiz_open_days.include?(Date.today.wday)
    end
  end

  private
      def ss_params
        params.require(:seminar_student).permit(:seminar_id, :user_id, :teach_request, 
                                  :learn_request, :pref_request, :present)
      end
      
      def correct_ss_user
        @ss = SeminarStudent.find(params[:id])
        @seminar = Seminar.find(@ss.seminar_id)
        redirect_to login_url unless (current_user && (@ss.user == current_user || current_user.seminars.include?(@seminar))) || user_is_an_admin
      end
      
      def delete_broken_quizzes
          Quiz.where(:user => @student).select{|x| x.ripostes.count == 0}.each do |quiz|
              quiz.ripostes.delete_all
              # Can delete this next line after the 2019 school year.  After I'm sure I no longer need the ripostes that still have quiz_ids
              Riposte.where(:quiz_id => quiz.id).destroy_all
              quiz.destroy
          end
      end
      
      def setup_ss_vars
        @ss = SeminarStudent.find(params[:id])
        @ss_id = @ss.id
        @student = @ss.user
        @seminar = @ss.seminar
        @teachers = @seminar.teachers
      end
      

end
