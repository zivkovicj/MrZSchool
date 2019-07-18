class Field < ApplicationRecord
    has_many    :domains
    has_many    :topics, through: :domains
end
