module TeachersHelper
    
    def admin_rank_compared(acting_faculty, target_faculty, level)
        acting_faculty.school_admin >= level && 
            (target_faculty.school_admin < level || 
            acting_faculty.school_admin > target_faculty.school_admin)
    end

    def teacher_show_links(grading_needed)
        which_quiz_pic = grading_needed ? "quiz_grading_needed.png" : "quiz.png"
        
        these_show_links = [["Scoresheet", "scoresheet.png", "scoresheet_seminar", "scoresheet", "seminars"],
        ["Desk Consultants", "desk_consult.png", "consultancy", "show", "consultancies"],
        ["Quiz Grading", which_quiz_pic,"quiz_grading_seminar","quiz_grading","seminar"],
        ["Students", "students.png", "usernames_seminar", "usernames", "seminars"],
        ["Edit", "E.png", "seminar", "show", "seminars"]
        ]
        
        return these_show_links
    end
      
    def verify_waiting_teachers_message
        "IMPORTANT: Some teachers are your school are waiting to be verified. Since you are an admin for #{@school.name}, will you please take a moment to verify the other teachers."
    end
    
end