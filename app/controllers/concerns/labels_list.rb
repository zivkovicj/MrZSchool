module LabelsList
    extend ActiveSupport::Concern
   
    def labels_to_offer
      labels_list = (current_user.type == "Admin" ? Label.all : Label.where("user_id = ? OR extent = ?", current_user.id, "public"))
      return labels_list.order(:name)
    end
    
    def fields_list
      Field.includes(domains: :topics)
    end
    
end
