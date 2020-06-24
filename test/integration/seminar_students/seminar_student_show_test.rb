require 'test_helper'

class SeminarStudentsShowTest < ActionDispatch::IntegrationTest
    
    def setup
        setup_users
        setup_schools
        setup_seminars
        setup_scores
    end
    
    def button_not_present(id)
        assert_no_selector('div', :id => id) 
    end
    
    def element_present_and_showing(id)
        assert_selector('div', :id => id)
        assert_no_selector('div', :id => id, :class => "currently_hidden") 
    end
    
    def element_present_and_hidden(id)
        assert_selector('div', :id => id)
        assert_selector('div', :id => id, :class => "currently_hidden") 
    end
    
    def check_visibility_use_and_sell_buttons
        # Sell Buttons
        element_present_and_showing("sell_button_#{@teacher_1_star.id}")
        element_present_and_showing("sell_button_#{@game_time_ticket.id}")
        button_not_present("sell_button_#{@fidget_spinner.id}")  # Fidget Spinner is not salable
        element_present_and_hidden("sell_button_#{@piece_of_candy.id}")
        
        # Use Buttons
        element_present_and_showing("use_button_#{@teacher_1_star.id}")
        button_not_present("use_button_#{@game_time_ticket.id}")  # Game ticket is salable, but not usable
        button_not_present("use_button_#{@fidget_spinner.id}")      # Fidget spinner not salable or usable
        element_present_and_hidden("use_button_#{@piece_of_candy.id}")
    end
    
    test 'grades back button' do
        capybara_login(@student_2)
        click_on("1st Period")
        click_on("Scores")
    end
    
    test 'objective downloading screen' do
        setup_objectives
        setup_worksheets
        @worksheet_1.objectives << @own_assign
        
        capybara_login(@student_2)
        click_on("1st Period")
        click_on("Scores")
        
        assert_selector("h3", :text => "Stars This Term")
        assert_selector("a", :text => @own_assign.name)
        assert_no_selector("a", :text => @objective_10.name)
        assert_selector("td", :text => @objective_10.name)
        
        # Check that student can link to download files for an objective, but not change them.
        click_link("link_to_all_#{@own_assign.id}")
        
        assert_no_selector("h5", :text => "1st Period")
        assert_selector("h2", :text => "for #{@own_assign.name}")
        assert_selector("h2", :text => "Current Files")
        assert_no_selector("h3", :text => "Upload a New File")  #Counterpart is in objectives_edit_test
        
        # Back to class screen
        click_on("Back to 1st Period")
        
        assert_no_selector("h2", :text => "Current Files")
        assert_selector("h5", :text => "1st Period")
    end
    test "move student to different class" do
        sem_2 = @teacher_1.seminars.second
        
        # Make sure that new student gets an objective_student for an objective that she didn't have
        new_seminar_objective = sem_2.objectives.create(:name => "Flap")
        assert_nil @student_2.objective_students.find_by(:objective => new_seminar_objective)
        
            # Update students_needed for that new objective
            this_obj_sem = ObjectiveSeminar.find_by(:objective => new_seminar_objective, :seminar => sem_2)
            this_obj_sem.students_needed_refresh
            old_stud_need_count = this_obj_sem.students_needed
            
            # Establish students_needed for the old seminar
            obj_from_old_sem = @seminar.objectives[0]
            this_obj_stud = ObjectiveStudent.find_by(:objective => obj_from_old_sem, :user => @student_2)
            set_specific_score(@student_2, obj_from_old_sem, 2)
            prev_obj_sem = ObjectiveSeminar.find_by(:objective => obj_from_old_sem, :seminar => @seminar)
            prev_obj_sem.students_needed_refresh
            prev_sem_stud_need_count = prev_obj_sem.students_needed
        
        assert @student_2.seminars.include?(@seminar)
        assert @seminar.students.include?(@student_2)
        assert_not @student_2.seminars.include?(sem_2)
        assert_not sem_2.students.include?(@student_2)
        assert_nil SeminarStudent.find_by(:user => @student_2, :seminar => sem_2)
        
        capybara_login(@teacher_1)
        click_on("scoresheet_seminar_#{@seminar.id}")
        click_on(@student_2.last_name_first)
        click_on("Move or Remove")
        click_on("Move to #{sem_2.name}")
        
        @student_2.reload
        sem_2.reload
        assert_not @student_2.seminars.include?(@seminar)
        assert_not @seminar.students.include?(@student_2)
        assert @student_2.seminars.include?(sem_2)
        assert sem_2.students.include?(@student_2)
        newest_sem_stud = SeminarStudent.find_by(:user => @student_2, :seminar => sem_2)
        assert_equal Date.today, newest_sem_stud.last_consultant_day
        
        # Students_needed for the specific objective_seminar has increased by one because of the new student
        assert_equal old_stud_need_count + 1, this_obj_sem.reload.students_needed
        assert_equal prev_sem_stud_need_count - 1, prev_obj_sem.reload.students_needed
        
        assert_not_nil @student_2.objective_students.find_by(:objective => new_seminar_objective)
    end
    
    test "remove student from class" do
        # Establish students_needed for an objective, to test that it gets updated
        first_obj_sem = @seminar.objective_seminars[0]
        this_obj = first_obj_sem.objective
        make_ready(@student_2, this_obj)
        set_specific_score(@student_2, this_obj, 2)
        first_obj_sem.students_needed_refresh
        old_stud_need_count = first_obj_sem.students_needed
        
        capybara_login(@teacher_1)
        click_on("scoresheet_seminar_#{@seminar.id}")
        click_on(@student_2.last_name_first)
        click_on("Move or Remove")
        find("#delete_#{@seminar.id}").click
        
        @student = @student_2
        click_on("confirm_#{@seminar.id}")
        
        assert_not @seminar.students.include?(@student_2)
        assert_not @student_2.seminars.include?(@seminar)
        assert_equal old_stud_need_count - 1, first_obj_sem.reload.students_needed
    end

    
end
