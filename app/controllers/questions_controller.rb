class QuestionsController < ApplicationController
  
  before_action only: [:delete, :destroy] do
    correct_owner(Question)
  end
  
  include SetPermissions
  include LabelsList
  
  def new
    @labels = labels_to_offer()
    @created_by = current_user.full_name_with_title
    @fields = fields_list
    @grade_type = "computer"
    @extent = "private"
  end
  
  def details
    @extent = params[:questions]["0"][:extent]
    @label = Label.find(params[:questions]["0"][:label_id])
    @style = params[:questions]["0"][:style]
    @grade_type = params[:questions]["0"][:grade_type]
    @pictures = @label.pictures
    create_question_group
  end

  def create_group
    one_saved = false
  
    params["questions"].each do |n|
      if params["questions"][n][:prompt].present?
        @question = Question.new(multi_params(params["questions"][n]))
        @question.user = current_user
        set_answers_and_choices(params["questions"][n])
        one_saved = true if @question.save
      end
    end
    
    flash[:success] = "Questions Created" if one_saved
    redirect_to current_user
  end

  def index
    @labels = labels_to_offer
    @labels_to_check = []
    
    if params[:label_ids].blank?
      initial_list = Question.all
    else
      params[:label_ids].each do |label_id|
        num = (label_id == "on" ? nil : label_id.to_i)
        @labels_to_check.push(num)
      end
      initial_list = Question.where(label_id: params[:label_ids])
    end
    
    if current_user.type == "Admin"
      second_list = initial_list
    else
      second_list = initial_list.where("user_id = ? OR extent = ?", current_user.id, "public")
    end
    
    if params[:search].present?
      third_list = second_list.search(params[:search], params[:whichParam])
    else
      third_list = second_list
    end
    
    if third_list == [0] then
      @questions = [0]
    else
      @questions = third_list.order(:prompt).paginate(page: params[:page])
    end
  end

  def show
  end

  def edit
    @question = Question.find(params[:id])
    set_edit_variables
    render 'show' if @assign_permission == "other"
  end

  def update
    @question = Question.find(params[:id])
    #debugger
    set_answers_and_choices(params["questions"]["0"])
    if @question.update_attributes(multi_params(params["questions"]["0"]))
      flash[:success] = "Question Updated"
      redirect_to questions_path
    else
      set_edit_variables
      render 'edit'
    end
  end

  def destroy
    @question = Question.find(params[:id])
    
    if @question.destroy
      fix_quantities
      flash[:success] = "Question Deleted"
      redirect_to questions_path
    end
  end
  
  private
    def multi_params(my_params)
        my_params.permit(:prompt, :user_id, :label_id, :extent, :style, :picture_id, :grade_type)
    end
    
    def create_question_group
      @question_group = []
      5.times do
        @question_group << Question.new
      end
    end
    
    def set_answers_and_choices(these_params)
      correct_array = []
      choice_array = []
      if @question.style == "fill_in"
        correct_array = these_params["choices"].reject { |c| c.empty? }
      else
        choice_array = these_params["choices"].reject { |c| c.empty? } # Removes the blank elements from the array
        these_params["is_correct"]&.each do |correct_num|
          this_answer = these_params["choices"][correct_num.to_i]
          correct_array << this_answer unless this_answer.empty?
        end
      end
      @question.update(:correct_answers => correct_array, :choices => choice_array)
    end
    
    def set_edit_variables
      @style = @question.style
      @grade_type = @question.grade_type
      @labels = labels_to_offer
      @extent = @question.extent
      @pictures = @question.label.pictures
      @fields = fields_list
      set_permissions(@question)
    end
    
    def fix_quantities
      lab = @question.label
      new_quest_count = lab.questions.count
      if new_quest_count == 0
        lab.label_objectives.destroy_all
      else
        lab.label_objectives.each do |lo|
          lo.update(:quantity => new_quest_count) if lo.quantity > new_quest_count
        end
      end
    end
    
    
end
