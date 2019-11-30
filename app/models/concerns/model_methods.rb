module ModelMethods
    extend ActiveSupport::Concern
    
    def short_name
        name[0,30].split.map(&:capitalize).join(' ')
    end
    
    module ClassMethods
        
        # Search for specific records
        def search(search, which_param)
            if search
                if ["user_number", "id"].include?(which_param)
                    results = where(:"#{which_param}" => search)
                else
                    case ActiveRecord::Base.connection.adapter_name
                    when 'PostgreSQL'
                        results = where("#{which_param} ILIKE ?" , "%#{search}%")
                    else
                        results = where("#{which_param} LIKE ?" , "%#{search}%")
                    end
                end
            end
            results = [0] if results == []
            return results
        end
        
        
    
    end
end
