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
    
    [0,1,2,3,4,5,6,7,8,9,10].each do |first_num|
      this_label = Label.find_or_create_by(:name => "Simple Multiply by #{first_num}")
      mult_topic.labels << this_label if !mult_topic.labels.include?(this_label)
      [0,1,2,3,4,5,6,7,8,9,10].each do |second_num|
        this_prompt = "#{first_num} * #{second_num} = ____"
        if Question.where(:prompt => this_prompt).count == 0 then
          Question.create(:style => "fill_in", :prompt => this_prompt,
                          :extent => "public", :label => this_label,
                          :correct_answers => ["#{first_num * second_num}"], :grade_type => "computer")
          end
      end
    end
  end
  
  private
    
end
