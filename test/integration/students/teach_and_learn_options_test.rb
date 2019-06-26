require 'test_helper'

class StudentsSearchTest < ActionDispatch::IntegrationTest
   
    def setup
        setup_users
        setup_schools
        setup_seminars
        setup_objectives
        setup_scores
    end
    
    test "teach options correct seminar" do
        #Once this objective is removed from the seminar, it should no longer appear in the teach_options
        set_specific_score(@student_1, @objective_10, 8)
        assert @student_1.teach_options(@seminar).include?(@objective_10)
        
        @seminar.objectives.delete(@objective_10)
        assert_not @student_1.teach_options(@seminar).include?(@objective_10)
    end
    
    test "teach options priority order" do
        assert @student_1.teach_options(@seminar).count < 10
        
        15.times do |n|
            new_obj = Objective.create(:name => "Objective_#{n}")
            @seminar.objectives << new_obj
            @student_1.quizzes.create(:objective => new_obj, :origin => "teacher_granted", :total_score => 8)
        end
        assert_equal 10, @student_1.teach_options(@seminar).count
        
        @seminar.objective_seminars.update_all(:priority => 3)
        newest_obj = @seminar.objectives.last
        assert_not_equal newest_obj, @student_1.teach_options(@seminar)[0]
        @seminar.objective_seminars.find_by(:objective => newest_obj).update(:priority => 5)
        assert_equal newest_obj, @student_1.teach_options(@seminar)[0]
    end
    
    test "teach options ready and willing" do
        # Don't include objectives where the score is lower than 6, or higher than 9.
        set_specific_score(@student_1, @objective_10, 2)
        assert_not @student_1.teach_options(@seminar).include?(@objective_10)
        
        set_specific_score(@student_1, @objective_10, 8)
        assert @student_1.teach_options(@seminar).include?(@objective_10)
        
        set_specific_score(@student_1, @objective_10, 10)
        assert_not @student_1.teach_options(@seminar).include?(@objective_10)
    end
    
    test "teach options no zero priority" do
        #Obj should appear at first, but not after its priority is set to zero
        set_specific_score(@student_1, @objective_10, 8)
        ObjectiveSeminar.where(:objective => @objective_10, :seminar => @seminar).update(:priority => 2)
        assert @student_1.teach_options(@seminar).include?(@objective_10)
        
        ObjectiveSeminar.where(:objective => @objective_10, :seminar => @seminar).update(:priority => 0)
        assert_not @student_1.teach_options(@seminar).include?(@objective_10)
    end
    
    test "learn options ready and willing" do
        # Objective 10 is a pre-req for mainassign, so mainassign should not appear in the learn_options
        mainassign = @objective_10.mainassigns.first
        set_specific_score(@student_1, @objective_10, 2)
        assert_equal 1, @objective_10.mainassigns.count
        set_specific_score(@student_1, mainassign, 2)
        set_ready_all(@student_1)
        
        assert @student_1.learn_options(@seminar).include?(@objective_10)
        assert_not @student_1.learn_options(@seminar).include?(mainassign)
        
        # Now the student is ready, so mainassign should appear in learn options
        # But obj_10 should no longer appear
        set_specific_score(@student_1, @objective_10, 8)
        assert @student_1.learn_options(@seminar).include?(mainassign)
        assert_not @student_1.learn_options(@seminar).include?(@objective_10)
    end
    
    test "learn options no zero priority" do
        #Obj should appear at first, but not after its priority is set to zero
        set_specific_score(@student_1, @objective_10, 2)
        assert @student_1.learn_options(@seminar).include?(@objective_10)
        
        ObjectiveSeminar.where(:objective => @objective_10, :seminar => @seminar).update(:priority => 0)
        assert_not @student_1.learn_options(@seminar).include?(@objective_10)
    end
    
    test "learn options correct seminar" do
        #Once this objective is removed from the seminar, it should no longer appear in the learn_options
        set_specific_score(@student_1, @objective_10, 2)
        assert @student_1.learn_options(@seminar).include?(@objective_10)
        
        @seminar.objectives.delete(@objective_10)
        assert_not @student_1.learn_options(@seminar).include?(@objective_10)
    end
        
    
    test "learn options priority order" do
        assert @student_1.learn_options(@seminar).count < 10
        
        15.times do |n|
            new_obj = Objective.create(:name => "Objective_#{n}")
            @seminar.objectives << new_obj
            @student_1.quizzes.create(:objective => new_obj, :origin => "teacher_granted", :total_score => 2)
        end
        assert_equal 10, @student_1.learn_options(@seminar).count
        
        @seminar.objective_seminars.update_all(:priority => 3)
        newest_obj = @seminar.objectives.last
        assert_not_equal newest_obj, @student_1.learn_options(@seminar)[0]
        @seminar.objective_seminars.find_by(:objective => newest_obj).update(:priority => 5)
        assert_equal newest_obj, @student_1.learn_options(@seminar)[0]
    end
    
end