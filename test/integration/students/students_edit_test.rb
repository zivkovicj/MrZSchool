require 'test_helper'

class StudentsEditTest < ActionDispatch::IntegrationTest
    
    def setup
       setup_users
       setup_schools
       setup_objectives
       setup_seminars
    end
    
    def student_edit_stuff
        fill_in "student_first_name", with: "Burgle"
        fill_in "student_last_name", with: "Cut"
        fill_in "student_username", with: "myusername"
        fill_in "student_password", with: "Passy McPasspass"
        fill_in "student_email", with: "my_new_mail@email.com"
        fill_in "student_user_number", with: 1073514
        click_on("Save Changes")
        
        @student_2.reload
        assert_equal "Burgle", @student_2.first_name
        assert_equal "Cut", @student_2.last_name
        assert_equal "myusername", @student_2.username
        assert @student_2.authenticate("Passy McPasspass")
        assert_equal "my_new_mail@email.com", @student_2.email
        assert_equal 1073514, @student_2.user_number
    end
    
    test "student edits self" do
        skip
        go_to_first_period
        click_on("Edit Your Profile")
        assert_no_selector('input', :id => "student_user_number")
        student_edit_stuff
    end

    test "teacher edits student" do
        capybara_login(@teacher_1)
        click_on("scoresheet_seminar_#{@seminar.id}")
        click_on("ss_#{@student_2.id}")
        click_on("Profile")
        
        student_edit_stuff
    end
        
    
    test "admin edits student" do
        capybara_login(@admin_user)
        click_on("Students Index")
        fill_in "search_field", with: @student_2.user_number
        choose("Student number")
        click_button('Search')
        click_on(@student_2.last_name_first)
        assert_selector('input', :id => "student_user_number")
        
        student_edit_stuff
    end
    
    test "edit username to already taken" do
        @student_1.update(:username => "beersprinkles07")
        capybara_login(@admin_user)
        click_on("Students Index")
        fill_in "search_field", with: @student_2.user_number
        choose('Student number')
        click_button('Search')
        click_on(@student_2.last_name_first)
        
        fill_in "student_username", with: "beersprinkles07"
        click_on("Save Changes")
        
        assert_equal "dv2", @student_2.username
    end
end
