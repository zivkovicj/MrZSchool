require 'test_helper'

class ObjectivesFormTest < ActionDispatch::IntegrationTest
    
    def setup
        setup_users
        
        @old_objective_count = Objective.count
    end
    
    def go_to_new_objective
        click_on("View/Create Content")
        click_on('Create a New Objective')
    end
    
    test "new objective button from main user page" do
        capybara_login(@teacher_1)
        assert_on_teacher_page
        go_to_new_objective
        assert_selector('h2', :text => 'New Objective', :visible => true)
        assert_not_on_teacher_page
    end
    
    
    test "empty name create" do
        capybara_login(@teacher_1)
        go_to_new_objective
        fill_in "name", with: ""
        click_on('Create a New Objective')
        
        assert_selector('h2', :text => "New Objective")
        assert_selector('div', :id => "error_explanation")
        assert_selector('li', :text => "Name can't be blank")
    end
    
    test "user creates objective" do
        first_topic = Topic.first
        
        capybara_login(@teacher_1)
        go_to_new_objective
        
        name = "009 Compare Unit Rates"
        fill_in "name", with: name
        find("#public_objective").choose
        choose("topic_#{first_topic.id}")
        click_on('Create a New Objective')
        
        assert_text name
        
        @new_objective = Objective.last
        assert_equal @old_objective_count + 1, Objective.count
        assert_equal name, @new_objective.name
        assert_equal @teacher_1, @new_objective.user
        assert_equal "public", @new_objective.extent
        assert_equal Topic.first, @new_objective.topic
    end
    
    test "admin creates objective" do
        capybara_login(@admin_user)
        go_to_new_objective

        name = "010 Destroy Unit Rates"
        fill_in "name", with: name
        click_on('Create a New Objective')
        
        @new_objective = Objective.last
        assert_equal @old_objective_count + 1, Objective.count
        assert_equal name, @new_objective.name
        assert_equal @admin_user, @new_objective.user
        assert_equal "private", @new_objective.extent
        assert_equal 0, @new_objective.objective_seminars.count
        assert_equal 0, @new_objective.labels.count
    end
    
end