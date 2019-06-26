require 'test_helper'

class GoalStudentsEditTest < ActionDispatch::IntegrationTest
    
    def setup
        setup_users
        #setup_schools
        setup_seminars
        setup_goals
        #setup_scores
        
        @this_gs = @student_2.goal_students.find_by(:seminar => @seminar, :term => 1)
    end
    
    def go_to_goal_screen
        go_to_first_period
        click_on("Edit Goal")
    end
    
    test "basic goal choosing" do
        skip
        travel_to Time.zone.local(2011, 12, 07, 01, 04, 44)
        
        def reload_stuff
            @gs.reload
            @check_1.reload
            @check_2.reload
            @check_3.reload
            @check_4.reload
        end
        
        @gs = @student_2.goal_students.find_by(:seminar => @seminar, :term => @seminar.term)
        @check_1 = @gs.checkpoints.find_by(:sequence => 1)
        @check_2 = @gs.checkpoints.find_by(:sequence => 2)
        @check_3 = @gs.checkpoints.find_by(:sequence => 3)
        @check_4 = @gs.checkpoints.find_by(:sequence => 4)
        assert_nil @check_1.action
        
        go_to_first_period
        assert_selector('h3', :text => "No goal set")
        click_on("Edit Goal")
        assert_selector('input', :id => "goal_submit_button", :visible => false)
        select("#{Goal.second.name}", :from => 'goal_student_goal_id')
        assert_selector('input', :id => "goal_submit_button", :visible => true)
        select("60%", :from => 'goal_student_target')
        click_on("Save This Goal")
        
        reload_stuff
        assert_equal Goal.second, @gs.goal
        assert_equal 60, @gs.target
        assert_not @gs.approved
        assert_equal "Play something kind", @check_1.action
        assert_equal "Testing Placeholder", @check_2.action
        assert_equal "Play something kind", @check_3.action
        assert_equal "I will be kind (?) % of the time.", @check_4.action
        assert_equal "I will be kind 60 % of the time.", @check_4.statement
        
        assert_selector('h2', :text => "Choose your Checkpoints")
    
        select("Eat something kind", :from => "syl[#{@check_1.id}][action]")
        select("I will be kind 60 % of the time so far.", :from => "syl[#{@check_2.id}][action]")
        assert_no_selector('h5', :text => @seminar.name)
        click_on("Save These Checkpoints")
        
        reload_stuff
        assert_equal "Eat something kind", @check_1.action
        assert_equal "I will be kind (?) % of the time so far.", @check_2.action
        assert_equal "I will be kind 60 % of the time so far.", @check_2.statement
        assert_equal "Play something kind", @check_3.action  # Should stay as the default because it wasn't changed.
        
        assert_selector('h5', :text => @seminar.name)
        assert_no_selector('h3', :text => "No goal set")
        assert_selector('h2', :text => @gs.statement_with_target)
        assert_selector('h3', :text => @gs.checkpoints.find_by(:sequence => 1).statement)
    end
    
    test "default goal if already chosen" do
        skip
        @this_gs.update(:goal => Goal.first)
        
        go_to_goal_screen
        assert_selector('h2', :text => "Edit Goal")  #Counterpart for the test where the goal is already approved
        assert_no_selector('h2', :text => "Choose your Checkpoints")
        click_on("Save This Goal")
        
        assert_selector('h2', :text => "Choose your Checkpoints")
        @this_gs.reload
        assert_equal Goal.first, @this_gs.goal
    end
    
    test "goal already approved" do
        skip
        @this_gs.update(:approved => true, :goal => Goal.first)
        
        go_to_goal_screen
        
        assert_no_selector('h2', :text => "Edit Goal")
        assert_selector('h2', :text => "Choose your Checkpoints")
    end
    
    test "goal edit back button" do
        skip
        go_to_goal_screen
        assert_no_selector('h5', :text => @seminar.name)
        
        click_on("Back to Viewing Your Class")
        
        assert_selector('h5', :text => @seminar.name)
    end
    
    test "student cant edit old checkpoints" do
        skip
        setup_scores
        setup_goals
        travel_to Time.zone.local(2017, 12, 12, 01, 04, 44)
        
        go_to_goal_screen
        select("#{Goal.second.name}", :from => 'goal_student_goal_id')
        select("60%", :from => 'goal_student_target')
        click_on("Save This Goal")
        
        assert_selector('h5', :id => "past_due_0")  # Past the due date
        assert_no_selector('div', :id => "action_picker_0")
        
        assert_selector('h5', :id => "too_soon_1")
        assert_no_selector('div', :id => "action_picker_1")  # Too close to due date
        
        assert_selector('div', :id => "action_picker_2")  # Should show
        
        assert_no_selector('div', :id => "action_picker_3")  # Doesn't show because there's only one choice.
        assert_selector('h5', :id => "statement_3")
    end

        
end