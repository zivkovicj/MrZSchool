require 'test_helper'

class GoalStudentsEditTest < ActionDispatch::IntegrationTest
    
    def setup
        setup_users
        setup_seminars
    end
    
    test "student chooses goal" do
        setup_scores
        setup_goals
        travel_to_testing_date
        
        @gs = @student_2.goal_students.find_by(:seminar => @seminar, :term => @seminar.term)
        
        go_to_first_period
        click_on("Edit This Goal")
        select("#{Goal.second.name}", :from => 'goal_student_goal_id')
        select("60%", :from => 'goal_student_target')
        click_on("Save This Goal")
        
        assert_selector('h1', :text => "Choose your Checkpoints")
        @gs.reload
        assert_equal Goal.second, @gs.goal
        assert_equal 60, @gs.target
        assert_not @gs.approved
        assert_equal "Play something kind", @gs.checkpoints[0].action
        assert_equal "I will be kind (?) % of the time so far.", @gs.checkpoints[1].action
        assert_equal "Play something kind", @gs.checkpoints[2].action
        assert_equal "I will be kind 60 % of the time.", @gs.checkpoints[3].statement
         
        assert_text("Choose your Checkpoints")
        @checkpoint = @gs.checkpoints.find_by(:sequence => 2)
        select("Eat something kind", :from => "syl[#{@gs.checkpoints.first.id}][action]")
        click_on("Save These Checkpoints")
        
        assert_selector('h2', :text => "Current Stars for this Grading Term")
        
        @gs.reload
        assert_equal "Eat something kind", @gs.checkpoints[0].action
        assert_equal "I will be kind (?) % of the time so far.", @gs.checkpoints[1].action   # Not changed in the previous screen.
        assert_equal "Play something kind", @gs.checkpoints[2].action
    end
    
    test "default goal if already chosen" do
        setup_scores
        setup_goals
        @this_gs = @student_2.goal_students.find_by(:seminar => @seminar, :term => 1)
        @this_gs.update(:goal => Goal.first)
        
        go_to_first_period
        click_on("Edit This Goal")
        click_on("Save This Goal")
        
        assert_selector('h1', :text => "Choose your Checkpoints")
        @this_gs.reload
        assert_equal Goal.first, @this_gs.goal
    end
    
    test "dont choose goal" do    #counterpart to above goal
        setup_goals
        setup_scores
        go_to_first_period
        click_on("Edit This Goal")
        
        click_on("Save This Goal")
        
        assert_selector('h2', :text => "Current Stars for this Grading Term")
        
        @gs = @student_2.goal_students.where(:seminar => @seminar)[0]
        assert_nil @gs.goal
    end
    
    test "goal edit back button" do
        setup_goals
        setup_scores
        go_to_first_period
        click_on("Edit This Goal")
        
        click_on("Back to Viewing Your Class")
        
        assert_selector('h2', :text => "Current Stars for this Grading Term")
    end
    
    test "navigate goal screens" do
        setup_goals
        setup_scores
        
        assert_equal 1, @seminar.term
        assert_equal 0, @seminar.which_checkpoint
        
        capybara_login(@teacher_1)
        go_to_goals
        
        assert_text("Approve Student Goals")
        assert_no_text("View Student Goals")
        
        click_on("term_2")

        assert_text("Approve Student Goals")
        assert_no_text("View Student Goals")
        @seminar.reload
        assert_equal 2, @seminar.term
        assert_equal 0, @seminar.which_checkpoint
        
        click_on("checkpoint_3")
        
        assert_text("Approve Student Goals")
        assert_no_text("View Student Goals")
        @seminar.reload
        assert_equal 2, @seminar.term
        assert_equal 3, @seminar.which_checkpoint
        
        click_on("#{@seminar.name}_view_goals")
        
        assert_text("View Student Goals")
        assert_no_text("Approve Student Goals")
        @seminar.reload
        assert_equal 2, @seminar.term
        assert_equal 3, @seminar.which_checkpoint
        
        click_on("term_3")
        assert_text("View Student Goals")
        assert_no_text("Approve Student Goals")
        @seminar.reload
        assert_equal 3, @seminar.term
        assert_equal 3, @seminar.which_checkpoint
        
        click_on("checkpoint_1")
        assert_text("View Student Goals")
        assert_no_text("Approve Student Goals")
        @seminar.reload
        assert_equal 3, @seminar.term
        assert_equal 1, @seminar.which_checkpoint
        
    end

        
end