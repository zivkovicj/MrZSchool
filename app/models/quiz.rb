class Quiz < ApplicationRecord
    has_and_belongs_to_many :ripostes
    has_many :questions, through: :ripostes
    belongs_to  :seminar
    belongs_to :user
    belongs_to :objective
    
    after_save    :set_points_for_obj_stud
    
    
    
    def added_stars
        [self.total_score - self.old_stars, 0].max
    end
    
    def some_are_teacher_graded
        ripostes.each do |riposte|
            return true if riposte.question.grade_type != "computer"
        end
        return false
    end
    
    def points_still_to_grade
        ripostes.where(:graded => 0).sum(:poss)
    end
    
    def poss_sum
        ripostes.sum(:poss)
    end
    
    def tally_sum
        ripostes.sum(:tally)
    end
    
    def total_percentage(summed_score)
        ((summed_score * 10)/poss_sum.to_f).round
    end
    
    def max_after_grade
        summed_score = tally_sum + points_still_to_grade
        return total_percentage(summed_score)
    end
    
    def take_keys_for_perfect_score
        comp_graded_questions = ripostes.select{|x| x.question.label.grade_type != "teacher"}
        if comp_graded_questions.to_a.sum{|e| e.tally.to_i} == comp_graded_questions.sum(&:poss)
            ObjectiveStudent.find_by(:objective => objective, :user => user).take_all_keys
        end
    end
    
    def set_total_score
        summed_score = tally_sum
        new_needs_grading = points_still_to_grade > 0
        update(:total_score => total_percentage(summed_score), :needs_grading => new_needs_grading)
        take_keys_for_perfect_score
        self.seminar.set_grading_needed
    end
    
    private
        def set_points_for_obj_stud
            if total_score.present?
                this_obj_stud = ObjectiveStudent.find_by(:user_id => user_id, :objective_id => objective_id)
                this_obj_stud.set_points(origin, total_score)
            end
        end
end
