module ModelMethods
    extend ActiveSupport::Concern
    
    def short_name
        name[0,30].split.map(&:capitalize).join(' ')
    end
    
    module ClassMethods
        
        # Search for specific records
        def search(search, whichParam)
            if search
                if whichParam == "user_number"
                    results = where(:user_number => search)
                else
                    case ActiveRecord::Base.connection.adapter_name
                    when 'PostgreSQL'
                        results = where("#{whichParam} ILIKE ?" , "%#{search}%")
                    else
                       results = where("#{whichParam} LIKE ?" , "%#{search}%")
                    end
                    
                end
            end
            results = [0] if results == []
            return results
        end
        
        
    
    end
end