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
                    results = where("#{whichParam} ILIKE ?" , "%#{search}%")
                end
            end
            results = [0] if results == []
            return results
        end
        
        
    
    end
end