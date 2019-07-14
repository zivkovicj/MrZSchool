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
  
  def fill_new_choices 
    choice_array = []
    6.times do |n|
      choice_array << self.read_attribute(:"choice_#{n}")
    end
    self.update(:choices => choice_array)
  end
  
  private
  

        
  
    
end
