class Label < ApplicationRecord
  belongs_to :user
  has_many :questions
  has_many  :label_pictures, dependent: :destroy
  has_many  :pictures, through: :label_pictures
  has_many :label_objectives, dependent: :destroy
  has_many :objectives, through: :label_objectives
  delegate    :topic, :to => :objective, :allow_nil => false
  
  validates :name, :presence => true
  
  include ModelMethods
  
  attribute   :extent, :string, default: "private"

end
