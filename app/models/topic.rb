class Topic < ApplicationRecord
    belongs_to :domain
    has_many :objectives
    has_and_belongs_to_many  :labels
    
    delegate    :field, :to => :domain, :allow_nil => false
end