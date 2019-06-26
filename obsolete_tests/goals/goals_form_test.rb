require 'test_helper'

class GoalsFormTest < ActionDispatch::IntegrationTest
    
    def setup
        setup_users
        setup_schools
        @old_goal_count = Goal.count
    end
    
    def go_to_goals_page
        click_on("View/Create Content")
        click_on("Goals")
    end
    
    test "create new goal" do
        capybara_login(@teacher_1)
        
        go_to_goals_page
        click_on("Create a New Goal Option")
        
        # Fail on first try
        click_on('Create a New Goal Option')
        assert_text('Create a New Goal Option')
        fill_in "goal[actions][1][0]", with: "Research types of beetles" #These first two should carry over to the second try after the first try fails.
        fill_in "goal[actions][1][1]", with: "Buy beetles from Harmons"
        assert_selector('div', :id => "error_explanation")
        assert_selector('li', :text => "Name can't be blank")
        assert_selector('li', :text => "checkpoint 2 needs at least one action")
        assert_selector('li', :text => "Statement stem can't be blank")
        assert_equal @old_goal_count, Goal.count
        
        # Correct on second try
        fill_in "goal[name]", with: "Eat more beetles"
        fill_in "goal[statement_stem]", with: "I will eat (?)% of the beetles in Utah"
        fill_in "goal[actions][1][2]", with: "Sneak in to a demolished building"
        fill_in "goal[actions][2][2]", with: "I will eat (?)% of the beetles in my county"
        fill_in "goal[actions][3][2]", with: "Break the glass at an insect museum"
        fill_in "goal[actions][3][4]", with: "Buy beetles from Rancho Market"
        fill_in "goal[actions][4][0]", with: "I will eat (?) % of the beetles in the other counties."
        choose("public_goal")
        click_on('Create a New Goal Option')
        
        assert_equal @old_goal_count + 1, Goal.count
        newest_goal = Goal.last
        actions_should_be =
            [["0"],
            ["Research types of beetles", "Buy beetles from Harmons", "Sneak in to a demolished building"], 
            ["I will eat (?)% of the beetles in my county"], 
            ["Break the glass at an insect museum", "Buy beetles from Rancho Market"], 
            ["I will eat (?) % of the beetles in the other counties."]]
        assert_equal "Eat more beetles", newest_goal.name
        assert_equal "I will eat (?)% of the beetles in Utah", newest_goal.statement_stem
        assert_equal actions_should_be, newest_goal.actions
        assert_equal @teacher_1, newest_goal.user
        assert_equal "public", newest_goal.extent
        assert_text("Goal Options")
    end
    
    test "edit goal option" do
        edited_goal = Goal.second
        assert_equal "public", edited_goal.extent
        
        capybara_login(@teacher_1)
        go_to_goals_page
        
        assert_text(Goal.first.name)
        assert_text(goals(:other_teacher_goal).name)
        assert_no_text(goals(:private_goal).name)
        click_on(edited_goal.name)
        
        assert_no_text("You are viewing the details of this goal. You may not make any edits because it was created by another teacher.")
        fill_in "goal[name]", with: "Be shockingly kind"
        fill_in "goal[actions][1][1]", with: "Buy pez for my homies"
        fill_in "goal[actions][1][7]", with: ""
        fill_in "goal[actions][2][2]", with: "Will it add one option?"
        choose("private_goal")
        click_on('Update this Goal Option')
        
        actions_should_be =
            [["0"],
            ["Play something kind","Buy pez for my homies","Do something kind","Write something kind","Sing something kind","Watch something kind","Eat something kind"],
            ["Testing Placeholder","I will be kind (?) % of the time so far.","Will it add one option?"],
            ["Play something kind","Say something kind","Do something kind","Write something kind","Sing something kind","Watch something kind","Eat something kind","Imagine something kind"],
            ["I will be kind (?) % of the time."]]
        edited_goal.reload
        assert_equal "Be shockingly kind", edited_goal.name
        assert_equal actions_should_be, edited_goal.actions
        assert_equal @old_goal_count, Goal.count
        assert_equal "private", edited_goal.extent
        assert_equal @teacher_1, edited_goal.user
        
        assert_text("Goal Options")
    end
    
    test "default extent" do
        edited_goal = Goal.second
        assert_equal "public", edited_goal.extent
        
        capybara_login(@teacher_1)
        go_to_goals_page
        click_on(edited_goal.name)
        click_on('Update this Goal Option')
        
        edited_goal.reload
        assert_equal "public", edited_goal.extent
    end
    
    test "view other teacher goal" do
        other_teacher_goal = goals(:other_teacher_goal)
        
        capybara_login(@teacher_1)
        go_to_goals_page
        click_on(other_teacher_goal.name)
        
        assert_text("You are viewing the details of this goal. You may not make any edits because it was created by another teacher.")
        assert_no_selector('textarea', :id => "name", :visible => true)
        assert_no_text('Update this Goal Option')
    end
    
    
end
    
    