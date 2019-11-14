module AddStudentStuff
    extend ActiveSupport::Concern

    def calculate_percentile(array, percentile)
        array.sort[(percentile * array.length).ceil - 1]
    end
    
    def refresh_all_obj_sems(seminar)
        ObjectiveSeminar.where(:seminar => seminar).each do |obj_sem|
            obj_sem.students_needed_refresh
        end
    end
        
end
