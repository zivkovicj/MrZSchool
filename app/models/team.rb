class Team < ApplicationRecord
    belongs_to :objective
    belongs_to :consultancy
    has_one :seminar, :through => :consultancy
    
    belongs_to  :consultant, class_name: "User"
    
    has_and_belongs_to_many  :users

end
