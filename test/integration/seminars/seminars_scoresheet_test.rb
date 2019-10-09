require 'test_helper'

class SeminarsScoresheetTest < ActionDispatch::IntegrationTest
   
    def setup
        setup_users
        setup_schools
        setup_seminars
        setup_objectives
        setup_scores
        
        @test_obj_stud = @objective_10.objective_students.find_by(:user => @student_2)
        School.all.update_all(:term => 1)
    end
    
    test "teacher manual score" do
        set_specific_score(@test_obj_stud.user, @test_obj_stud.objective, 2)
        @test_obj_stud.update(:teacher_granted_keys => 2, :dc_keys => 2, :pretest_score => 4)
        
        capybara_login(@teacher_1)
        click_on("scoresheet_seminar_#{@seminar.id}")
        
        fill_in "scores[#{@student_2.id}][#{@objective_10.id}]", with: 8
        click_on("Save Scores")
        
        @test_obj_stud.reload
        assert_equal 4, @test_obj_stud.pretest_score
        assert_equal 8, @test_obj_stud.points_all_time
        assert_equal 8, @test_obj_stud.points_this_term
        assert_equal 0, @test_obj_stud.teacher_granted_keys  #Counterpart to the tests that take keys away.
        assert_equal 0, @test_obj_stud.dc_keys
    end
    
    test "lower previous teacher score" do  # But quizzes cannot lower scores.  They can only raise them.
        Quiz.create(:user => @student_2, :objective => @objective_10, :origin => "pretest", :total_score => 10)
        Quiz.create(:user => @student_2, :objective => @objective_10, :origin => "manual", :total_score => 6)
        @test_obj_stud.update(:teacher_granted_keys => 2, :dc_keys => 2, :points_all_time => 10, :points_this_term => 6)
        
        capybara_login(@teacher_1)
        click_on("scoresheet_seminar_#{@seminar.id}")
        
        fill_in "scores[#{@student_2.id}][#{@objective_10.id}]", with: 4
        click_on("Save Scores")
        
        @test_obj_stud.reload
        assert_equal 10, @test_obj_stud.points_all_time
        assert_equal 10, @test_obj_stud.pretest_score
        assert_equal 4, @test_obj_stud.points_this_term
    end
    
    test "lower not previous student quiz" do
        @test_obj_stud.update(:teacher_granted_keys => 2, :dc_keys => 2, :points_all_time => 6, :pretest_score => 2)
        Quiz.find_or_create_by(:user => @student_2, :objective => @objective_10, :origin => "teacher_granted").update(:total_score => 6)
        
        capybara_login(@teacher_1)
        click_on("scoresheet_seminar_#{@seminar.id}")
        
        fill_in "scores[#{@student_2.id}][#{@objective_10.id}]", with: 4
        
        click_on("Save Scores")
        
        @test_obj_stud.reload
        assert_equal 2, @test_obj_stud.pretest_score
        assert_equal 6, @test_obj_stud.points_all_time
    end
    
    test "bad score data" do
        @test_obj_stud.update(:teacher_granted_keys => 2, :dc_keys => 2, :pretest_score => 3)
        set_specific_score(@test_obj_stud.user, @test_obj_stud.objective, 8)
        
        capybara_login(@teacher_1)
        click_on("scoresheet_seminar_#{@seminar.id}")
        
        fill_in "scores[#{@student_2.id}][#{@objective_10.id}]", with: "a"
        click_on("Save Scores")
        
        @test_obj_stud.reload
        assert_equal 8, @test_obj_stud.points_all_time
        assert_equal 3, @test_obj_stud.pretest_score
        assert_equal 2, @test_obj_stud.teacher_granted_keys
        assert_equal 2, @test_obj_stud.dc_keys
    end
    
    test "update all time not this term" do
        Quiz.create(:user => @student_2, :objective => @objective_10, :origin => "teacher_granted", :total_score => 7)
        @test_obj_stud.update(:pretest_score => 2, :points_this_term => 6, :points_all_time => 6)
        
        capybara_login(@teacher_1)
        click_on("scoresheet_seminar_#{@seminar.id}")
        
        click_on("switch_to_all_time")
        
        fill_in "scores[#{@student_2.id}][#{@objective_10.id}]", with: 8
        click_on("Save Scores")
        
        @test_obj_stud.reload
        assert_equal 2, @test_obj_stud.pretest_score
        assert_equal 8, @test_obj_stud.points_all_time
        assert_equal 6, @test_obj_stud.points_this_term
    end
    
    test "update pretests" do
        set_specific_score(@test_obj_stud.user, @test_obj_stud.objective, 7)
        # Set pretest score to lower than all time.  Then teacher updates pretest manually to something in-between.
        @test_obj_stud.update(:pretest_score => 5, :points_this_term => 7)
        
        capybara_login(@teacher_1)
        click_on("scoresheet_seminar_#{@seminar.id}")
        
        click_on("switch_to_pretests")
        
        fill_in "scores[#{@student_2.id}][#{@objective_10.id}]", with: 5
        click_on("Save Scores")
        
        @test_obj_stud.reload
        assert_equal 7, @test_obj_stud.points_all_time
        assert_equal 5, @test_obj_stud.pretest_score
    end
    
    test "update this term not all time" do
        Quiz.create(:user => @student_2, :objective => @objective_10, :origin => "teacher_granted", :total_score => 8)
        @test_obj_stud.update(:pretest_score => 2, :points_this_term => 6)
        
        capybara_login(@teacher_1)
        click_on("scoresheet_seminar_#{@seminar.id}")
        
        fill_in "scores[#{@student_2.id}][#{@objective_10.id}]", with: 7
        click_on("Save Scores")
        
        @test_obj_stud.reload
        assert_equal 2, @test_obj_stud.pretest_score
        assert_equal 8, @test_obj_stud.points_all_time
        assert_equal 7, @test_obj_stud.points_this_term
    end
end
