require 'test_helper'

class LabelsFormTest < ActionDispatch::IntegrationTest
    
    def setup
        setup_users
        setup_schools
        setup_labels
        setup_questions
        @new_name = "20.1 One-step equations with diagrams"
    end
    
    def go_to_all_labels
        click_on("View/Create Content")
        click_on("All Labels")
    end
    
    def go_to_new_label
        click_on("View/Create Content")
        click_on("Create a New Label")
    end
    
    test "create new label" do
        setup_topics
        old_label_count = Label.count
        
        capybara_login(@teacher_1)
        go_to_new_label
        fill_in "name", with: @new_name
        check("topic_#{@integers_topic.id}")
        check("topic_#{@roots_topic.id}")
        choose("grade_type_computer")
        click_on("Create This Label")
        
        assert_equal old_label_count + 1, Label.count
        @new_label = Label.last
        assert_equal @new_name, @new_label.name
        assert_equal "private", @new_label.extent
        assert_equal @teacher_1, @new_label.user
        assert @new_label.topics.include?(@roots_topic)
        assert @new_label.topics.include?(@integers_topic)
        assert_equal "computer", @new_label.grade_type
        assert_not @new_label.topics.include?(@transformations_topic)
        
        
        # Need to assert redirection soon
    end

    test "admin creates label" do
        capybara_login(@admin_user)
        go_to_new_label
        
        fill_in "name", with: @new_name
        choose("public_label")
        click_on("Create This Label")
        
        @new_label = Label.last
        assert_equal @new_name, @new_label.name
        assert_equal "public", @new_label.extent
        assert_equal @admin_user, @new_label.user

        # Need to assert redirection soon
    end
    
    test "invalid label" do
        capybara_login(@teacher_1)
        go_to_new_label
        
        # No name entered
        click_on("Create This Label")
        
        assert_selector('h2', :text => "New Label")
        assert_selector('div', :id => "error_explanation")
        assert_selector('li', :text => "Name can't be blank")
    end
    
    test "view other teacher label" do
        capybara_login(@teacher_1)
        go_to_all_labels
        click_on(@other_l_pub.name)
        
        assert_no_selector('textarea', :id => "name", :visible => true)
        assert_no_text("Save Changes")
    end
    
    test "edit admin label" do
        capybara_login(@teacher_1)
        go_to_all_labels
        click_on(@admin_l.name)
        
        assert_no_selector('textarea', :id => "name", :visible => true)
    end
    
    test "edit own label" do
        setup_topics
        new_name = "New name for this label"
        assert_not_equal new_name, @user_l.name
        @roots_topic.labels << @user_l
        assert @user_l.topics.include?(@roots_topic)
        assert_not @user_l.topics.include?(@integers_topic)
        assert_equal "computer", @user_l.grade_type
        
        capybara_login(@teacher_1)
        go_to_all_labels
        click_on(@user_l.name)
        
        assert_no_text("You may only edit a label that you have created.")
        
        fill_in "name", with: new_name
        check("topic_#{@integers_topic.id}")
        uncheck("topic_#{@roots_topic.id}")
        choose("grade_type_teacher")
        click_on("Save Changes")
        
        @user_l.reload
        assert_equal new_name, @user_l.name
        assert_not @user_l.topics.include?(@roots_topic)
        assert @user_l.topics.include?(@integers_topic)
        assert_equal "teacher", @user_l.grade_type
    end

    test "default label info" do
        setup_topics
        @roots_topic.labels << @user_l
        old_name = @user_l.name
        
        capybara_login(@teacher_1)
        go_to_all_labels
        click_on(@user_l.name)
        
        click_on("Save Changes")
        
        @user_l.reload
        assert_equal old_name, @user_l.name
        assert @user_l.topics.include?(@roots_topic)
        assert_equal "computer", @user_l.grade_type
    end
end
