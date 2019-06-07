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
            if search
                results = where("#{whichParam} LIKE ?" , "%#{actual_search}%")
            else
               nil
            end
            if results.nil? || results == []
                results = [0]
            end
            return results
        end
        
        
    
    end
end