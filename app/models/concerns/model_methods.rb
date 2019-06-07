module ModelMethods
    extend ActiveSupport::Concern
    
    def short_name
        name[0,30].split.map(&:capitalize).join(' ')
    end
    
    module ClassMethods
        
        # Search for specific records
        def search(search, whichParam)
            if whichParam == "user_number"
                actual_search = search.to_i
            else
                actual_search = search
            end
            results = [0]
            if search
                results = where("#{whichParam} LIKE ?" , "%#{actual_search}%")
            end
            return results
        end
        
        
    
    end
end