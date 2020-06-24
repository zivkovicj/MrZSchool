require 'test_helper'

class SchoolsEditTest < ActionDispatch::IntegrationTest
    
    include TeachersHelper
    
    def setup
        setup_users
        setup_schools
    end
    
    def set_admin_levels_for_extra_teachers
        @extra_teacher_0 = Teacher.find_by(:first_name => "User 10")
        @extra_teacher_0.update(:school_admin => 0)
        @extra_teacher_1 = Teacher.find_by(:first_name => "User 1")
        @extra_teacher_1.update(:school_admin => 1)
        @extra_teacher_2 = Teacher.find_by(:first_name => "User 2")
        @extra_teacher_2.update(:school_admin => 2)
    end
    
    
    test "edit_term_dates" do
        @teacher_1.update(:school_admin => 2)
        capybara_login(@teacher_1)
        assert_selector('input', :id => "edit_school_#{@school.id}")
        find("#edit_school_#{@school.id}").click
        
        fill_in "school[term_dates][2][1]", with: "06/06/2019"
        click_on("Save Changes")
        
        @school.reload
        new_date_array = [["08/14/2018","10/27/2018"],
         ["10/28/2018","01/19/2019"],
         ["01/20/2019","06/06/2019"],
         ["03/24/2019","06/05/2019"]]
        assert_equal new_date_array, @school.term_dates
    end
    
    test "other teacher cannot edit school" do
        capybara_login(@other_teacher)
        assert_no_selector('input', :id => "edit_school_#{@school.id}" )
    end
    
    test "admin level zero" do
        @teacher_1.update(:school_admin => 0)
        
        capybara_login(@teacher_1)
        assert_no_selector('input', :id => "edit_school_#{@school.id}")
    end
    
    test "admin level one" do
        @teacher_1.update(:school_admin => 1)
        set_admin_levels_for_extra_teachers
        
        capybara_login(@teacher_1)
        find("#edit_school_#{@school.id}").click
        
        assert_no_selector('input', :id => "school_name_edit")
        assert_no_selector('input', :id => "school_city_edit")
        assert_no_selector('select', :id => "school_state")
        
        assert_selector('input', :id => "admin_lv_0_#{@extra_teacher_0.id}")
        assert_selector('input', :id => "admin_lv_1_#{@extra_teacher_0.id}")
        assert_no_selector('input', :id => "admin_lv_2_#{@extra_teacher_0.id}")
        
        assert_no_selector('input', :id => "admin_lv_0_#{@extra_teacher_1.id}")
        assert_selector('input', :id => "admin_lv_1_#{@extra_teacher_1.id}")
        assert_no_selector('input', :id => "admin_lv_2_#{@extra_teacher_1.id}")
        
        assert_no_selector('input', :id => "admin_lv_0_#{@extra_teacher_2.id}")
        assert_no_selector('input', :id => "admin_lv_1_#{@extra_teacher_2.id}")
        assert_selector('input', :id => "admin_lv_2_#{@extra_teacher_2.id}")
    end
    
    test "admin level two" do
        @teacher_1.update(:school_admin => 2)
        set_admin_levels_for_extra_teachers
        
        capybara_login(@teacher_1)
        find("#edit_school_#{@school.id}").click
        
        assert_selector('input', :id => "school_name_edit")
        assert_selector('input', :id => "school_city_edit")
        assert_selector('select', :id => "school_state")
        
        assert_selector('input', :id => "admin_lv_0_#{@extra_teacher_0.id}")
        assert_selector('input', :id => "admin_lv_1_#{@extra_teacher_0.id}")
        assert_selector('input', :id => "admin_lv_2_#{@extra_teacher_0.id}")
        
        assert_selector('input', :id => "admin_lv_0_#{@extra_teacher_1.id}")
        assert_selector('input', :id => "admin_lv_1_#{@extra_teacher_1.id}")
        assert_selector('input', :id => "admin_lv_2_#{@extra_teacher_1.id}")
        
        assert_no_selector('input', :id => "admin_lv_0_#{@extra_teacher_2.id}")
        assert_no_selector('input', :id => "admin_lv_1_#{@extra_teacher_2.id}")
        assert_selector('input', :id => "admin_lv_2_#{@extra_teacher_2.id}")
    end
    
    test "change admin levels" do
        @teacher_1.update(:school_admin => 2)
        set_admin_levels_for_extra_teachers
        
        capybara_login(@teacher_1)
        find("#edit_school_#{@school.id}").click
        
        choose("admin_lv_2_#{@extra_teacher_0.id}")
        choose("admin_lv_0_#{@extra_teacher_1.id}")
        
        click_on("Save Changes")
        
        assert_equal 2, @extra_teacher_0.reload.school_admin
        assert_equal 0, @extra_teacher_1.reload.school_admin
    end
    
    test "no verify submenu if useless" do
        @school.teachers.update_all(:verified => 1)
        
        capybara_login(@teacher_1)
        find("#edit_school_#{@school.id}").click
        
        assert_no_selector('td', :id => 'navribbon_verify_faculty')
    end
    
    test "approve unverified teachers" do
        @right_teacher = users(:user_2)
        @wrong_teacher = users(:user_1)
        @ignored_teacher = users(:user_3)
        
        assert_equal 0, @right_teacher.verified
        assert_equal 0, @wrong_teacher.verified
        assert_equal 0, @ignored_teacher.verified
        @right_teacher_student = Student.all[55]
        @wrong_teacher_student = Student.all[56]
        @ignored_teacher_student = Student.all[57]
        @right_teacher_student.update(:sponsor => @right_teacher, :verified => 0)
        @wrong_teacher_student.update(:sponsor => @wrong_teacher, :verified => 0)
        @ignored_teacher_student.update(:sponsor => @ignored_teacher, :verified => 0)
        
        capybara_login(@teacher_1)
        assert_text(verify_waiting_teachers_message)
        click_on("goto_verify")
        
        assert_selector('td', :id => 'navribbon_verify_faculty')
        choose("teacher_#{@right_teacher.id}_approve")
        choose("teacher_#{@wrong_teacher.id}_decline")
        click_on("Save Changes")
        
        assert_equal 1, @right_teacher.reload.verified
        assert_equal 0, @ignored_teacher.reload.verified
        assert_equal (-1), @wrong_teacher.reload.verified
        assert_equal 1, @right_teacher_student.reload.verified
        assert_equal 0, @ignored_teacher_student.reload.verified
        assert_equal 0, @wrong_teacher_student.reload.verified
    end
end
