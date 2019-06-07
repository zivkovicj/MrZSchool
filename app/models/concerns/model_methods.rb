module ModelMethods
    extend ActiveSupport::Concern
    
    def short_name
        name[0,30].split.map(&:capitalize).join(' ')
    end
    
    module ClassMethods
        
        # Search for specific records
        def search(search, whichParam)
            if search
                results = where("#{whichParam} LIKE ?" , "%#{search}%")
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