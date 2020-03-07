require 'test_helper'

class SeminarsNewTest < ActionDispatch::IntegrationTest
   
    def setup
        setup_users
        setup_schools
        @old_seminar_count = Seminar.count
        setup_objectives
    end
    
    test "create new seminar" do
        capybara_login(@teacher_1)
        click_on("Create a New Class")
       
        fill_in "seminar[name]", with: "4th Period"
        find("#school_year_1").select("7")
        click_on("Create This Class")
       
        assert_equal @old_seminar_count + 1, Seminar.count
        @seminar = Seminar.last
        assert_equal "4th Period",  @seminar.name
        assert_equal 8, @seminar.school_year
        assert_equal 7, @seminar.consultantThreshold
        assert_equal @teacher_1, @seminar.teachers.first
        assert_equal @teacher_1, @seminar.owner
        assert_equal 1, @seminar.term
        assert_equal Seminar.due_date_array, @seminar.checkpoint_due_dates
        assert_equal 3, @seminar.columns
        assert_not @seminar.grading_needed
        
        sem_teach = SeminarTeacher.last
        assert_equal @teacher_1, sem_teach.user
        assert_equal @seminar, sem_teach.seminar
        assert sem_teach.can_edit
        assert sem_teach.accepted
        
        assert_selector('h2', :text => "Basic Info for #{@seminar.name}")
        
        # This section creates students for a new class, and then make sure those students show up
        # That feature wasn't working properly on 08/17/18
        
        click_on("Create New Students")
        
        fill_in ("first_name_1"), :with => "New Guy"
        fill_in ("last_name_1"), :with => "for Seminar Test"
        
        click_on("Create these student accounts")
        
        assert_text(@seminar.name)
        assert_selector('h2', :text => "Current Term Scores")
        
        assert_selector('a', :text => "New Guy")
    end
    
    test "seminar back link" do
        capybara_login(@teacher_1)
        click_on("Create a New Class")
        
        click_on("back_button")
        
        assert_text("Mr. Z School Teacher Since:")
        assert_equal @old_seminar_count, Seminar.count
    end
   
    test "empty seminar name" do
        capybara_login(@teacher_1)
        click_on("Create a New Class")
        click_on("Create This Class")
        
        assert_equal @old_seminar_count, Seminar.count
        assert_selector('h2', :text => "New Class")
        assert_selector('div', :id => "error_explanation")
        assert_selector('li', :text => "Name can't be blank")
    end
    
    test "name too long" do
        capybara_login(@teacher_1)
        click_on("Create a New Class")
        fill_in "seminar[name]", with: "a"*41
        
        click_on("Create This Class")
        
        assert_equal @old_seminar_count, Seminar.count
        assert_selector('h2', :text => "New Class")
        assert_selector('div', :id => "error_explanation")
        assert_selector('li', :text => "Name is too long (maximum is 40 characters)")
    end
end
