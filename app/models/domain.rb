class Domain < ApplicationRecord
    belongs_to  :field
    has_many    :topics
    has_many    :objectives, :through => :topics
    
end