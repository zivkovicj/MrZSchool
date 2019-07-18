class Topic < ApplicationRecord
    belongs_to :domain
    has_many :objectives
    has_many    :labels, through: :objectives
    delegate    :field, :to => :domain, :allow_nil => false
end