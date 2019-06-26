class QuestionsController < ApplicationController
  
  before_action only: [:delete, :destroy] do
    correct_owner(Question)
  end
  
  include SetPermissions
  include LabelsList
  
  def new
    @labels = labels_to_offer()
    @created_by = current_user.full_name_with_title
  end
  
  def details
    @extent = params[:extent]
    @label = Label.find(params[:label])
    @style = params[:style]
    @grade_type = params[:grade_type]
    @pictures = @label.pictures
    create_question_group
  end

  def create_group
    one_saved = false
    
    params["questions"].each do |n|
      if params["questions"][n][:prompt].present?
        @question = Question.new(multi_params(params["questions"][n]))
        @question.user = current_user
        ensure_essentials
        set_correct_answers(params["questions"][n])
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
    
    @questions = third_list.order(:prompt).paginate(page: params[:page])
  end

  def show
  end

  def edit
    @question = Question.find(params[:id])
    @grade_type = @question.grade_type
    @labels = labels_to_offer()
    @pictures = @question.label.pictures
    set_permissions(@question)
    render 'show' if @assign_permission == "other"
  end

  def update
    @question = Question.find(params[:id])
    ensure_essentials
    @question.label_id = params[:label]
    @question.extent = params[:extent]
    @question.grade_type = params[:grade_type]
    set_correct_answers(params["questions"]["0"])
    if @question.update_attributes(multi_params(params["questions"]["0"]))
      flash[:success] = "Question Updated"
      redirect_to questions_path
    else
      @labels = labels_to_offer()
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
      my_params.permit(:prompt, :choice_0, :choice_1, :choice_2, :choice_3,
        :choice_4, :choice_5, :user_id, :label_id, :extent, :style, :picture_id, :grade_type)
    end
    
    def create_question_group
      @question_group = []
      5.times do
        @question_group << Question.new
      end
    end
    
    def ensure_essentials
      @question.update(:choice_0 => "First Choice") if @question.choice_0.blank?
      @question.update(:choice_1 => "Second Choice") if @question.choice_1.blank? if @question.style == "multiple-choice"
    end
    
    def set_correct_answers(these_params)
      correct_array = []
      case @question.style
      when 'multiple-choice'
        param_num = these_params[:whichIsCorrect]
        correct_num = param_num ? param_num.to_i : 0
        correct_value = @question.read_attribute(:"choice_#{correct_num}")
        correct_value ||= "Correct Answer"
        correct_array.push(correct_value)
      when 'fill-in'
        correct_array = (0..5).map { |i| these_params[:"choice_#{i}"] }.select(&:present?)
      end
      @question.update(:correct_answers => correct_array)
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
