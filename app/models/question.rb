class Question < ApplicationRecord
  include ModelMethods
  
  belongs_to :user
  belongs_to :label
  
  has_many :ripostes, dependent: :destroy
  belongs_to :picture
  
  serialize :choices
  serialize :correct_answers
  
  attribute  :extent, :string, default: "private"
  attribute  :grade_type, :string, default: "computer"
  
  validates :prompt, :presence => true
  validates :extent, :presence => true
  
  def short_prompt
    prompt[0,45]
  end
  
  def create_multiplication_questions
    mult_topic = Topic.find_by(:name => "Multiplication")
    
    [0,1,2,3,4,5,6,7,8,9,10,11,12].each do |first_num|
      # Addition for updating
      label_to_delete = Label.find_by(:name => "Simple Multiply by #{first_num}")
      if label_to_delete.present?
        label_to_delete.questions.each do |question|
          question.destroy
        end
        label_to_delete.destroy
      end
      label_to_delete = Label.find_by(:name => "Multiply by #{first_num}, lv 2")
      if label_to_delete.present?
        label_to_delete.questions.each do |question|
          question.destroy
        end
        label_to_delete.destroy
      end
      
      this_label = Label.create(:name => "Multiply by #{first_num}, Lv 1")
      mult_topic.labels << this_label if !mult_topic.labels.include?(this_label)
      [0,1,2,3,4,5,6,7,8,9,10].each do |second_num|
        this_prompt = "#{first_num} * #{second_num} = ____"
        if Question.where(:prompt => this_prompt).count == 0 then
          Question.create(:style => "fill_in", :prompt => this_prompt,
                          :extent => "public", :label => this_label,
                          :correct_answers => ["#{first_num * second_num}"], :grade_type => "computer",
                          :user_id => 1)
          end
      end
      
      this_label = Label.create(:name => "Multiply by #{first_num}, Lv 2")
      mult_topic.labels << this_label if !mult_topic.labels.include?(this_label)
      [11,12,15,20,50,100,200,500,1000].each do |second_num|
        this_prompt = "#{first_num} * #{second_num} = ____"
        if Question.where(:prompt => this_prompt).count == 0 then
          Question.create(:style => "fill_in", :prompt => this_prompt,
                          :extent => "public", :label => this_label,
                          :correct_answers => ["#{first_num * second_num}"], :grade_type => "computer",
                          :user_id => 1)
          end
      end
      
    end
  end
  
  private
    
end
