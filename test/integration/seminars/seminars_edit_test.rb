require 'test_helper'

class SeminarsEditTest < ActionDispatch::IntegrationTest
   
    def setup
        setup_users
        setup_schools
        setup_seminars
        
        @old_seminar_count = Seminar.count
        @old_st_count = SeminarTeacher.count
        
        @old_name = @seminar.name
        @old_school_year = @seminar.school_year
        @old_columns = @seminar.columns
        @old_open_times = @seminar.quiz_open_times
        @old_open_days = @seminar.quiz_open_days
    end
    
    def go_to_term
        click_on("Term")
    end
    
    def set_score_for_random_student(seminar)
        test_student = seminar.students.limit(1).order("RANDOM()").first
        test_obj = seminar.objectives.limit(1).order("RANDOM()").first
        test_obj_stud = ObjectiveStudent
            .find_by(:user => test_student, :objective => test_obj)
        test_obj_stud.update(:points_this_term => 4)
        return test_obj_stud
    end
    
    test "add obj and preassign at once" do
        setup_objectives
        setup_scores
        
        @this_preassign = @assign_to_add.preassigns.first
        
        capybara_login(@teacher_1)
        go_to_seminar
        click_on("Objectives")
        
        check("check_#{@assign_to_add.id}")
        check("check_#{@this_preassign.id}")
        
        click_on("Update This Class")
        
        @seminar.reload
        assert_equal 1, @seminar.objective_seminars.where(:objective => @assign_to_add).count
        assert_equal 1, @seminar.objective_seminars.where(:objective => @this_preassign).count
    end

    def assert_all_defaults
        assert_equal @old_name, @seminar.name
        assert_equal @old_school_year, @seminar.school_year
        assert_equal @old_columns, @seminar.columns
        assert_equal @old_open_times, @seminar.quiz_open_times
        assert_equal @old_open_days, @seminar.quiz_open_days
    end

    test "basic seminar info defaults" do
        capybara_login(@teacher_1)
        go_to_seminar
        click_on("Basic Info")
        click_on("Update This Class")
        
        @seminar.reload
        assert_all_defaults
        
        assert_selector('div', :text => "Class Updated")
        assert_selector('h2', :text => "Edit #{@seminar.name}")
    end
    
    test "basic info change" do
        assert_not_equal 4, @seminar.school_year
        assert_not_equal 4, @seminar.columns
        
        capybara_login(@teacher_1)
        go_to_seminar
        click_on("Basic Info")
        
        fill_in "seminar[name]", with: "Dangle"
        find("#seminar_columns").select("4") # Set to four columns
        find("#school_year_1").select("3")  # Choose 3 for 5th grade
        find("#quiz_open_time").select("2:00")
        find("#quiz_close_time").select("5:00")
        check("seminar_quiz_open_days_0")
        uncheck("seminar_quiz_open_days_2") #Fixture begins with quiz_open_days: [1,2,3,4,5]
        
        click_on("Update This Class")
        
        @seminar.reload
        assert_equal "Dangle", @seminar.name
        assert_equal 4, @seminar.school_year
        assert_equal 4, @seminar.columns
        assert_equal [120,300], @seminar.quiz_open_times
        assert_equal [0,1,3,4,5], @seminar.quiz_open_days
        
        assert_selector('div', :text => "Class Updated")
        assert_selector('h2', :text => "Edit #{@seminar.name}")
    end

    test "basic info blank name" do
        capybara_login(@teacher_1)
        go_to_seminar
        click_on("Basic Info")
        
        fill_in "seminar[name]", with: ""
        
        click_on("Update This Class")
        
        @seminar.reload
        assert_equal @old_name, @seminar.name
        
        assert_selector('h2', :text => "Edit #{@seminar.name}")
    end
    
    test "change term and reset grades" do
        assert_equal 1, @seminar.term
        setup_scores
        this_obj = @seminar.objectives.first
        
        # Give a student a score that will be reset
        stud_5 = @seminar.students[5]
        obj_stud_5 = ObjectiveStudent.find_by(:user => stud_5, :objective => this_obj)
        obj_stud_5.update(:points_all_time => 4, :points_this_term => 4)
        
        # Give some other key types that will turn into pretest keys
        stud_6 = @seminar.students[6]
        obj_stud_6 = ObjectiveStudent.find_by(:user => stud_6, :objective => this_obj)
        obj_stud_6.update(:teacher_granted_keys => 2, :pretest_keys => 0)
        
        stud_7 = @seminar.students[7]
        obj_stud_7 = ObjectiveStudent.find_by(:user => stud_7, :objective => this_obj)
        obj_stud_7.update(:dc_keys => 1, :pretest_keys => 0)
        
        stud_8 = @seminar.students[8]
        obj_stud_8 = ObjectiveStudent.find_by(:user => stud_8, :objective => this_obj)
        obj_stud_8.update(:teacher_granted_keys => 0, :pretest_keys => 1)
        
        # Student 8 has a finished quiz and an unfisished quiz
        q1 = Quiz.create(:user => stud_8, :objective => this_obj, :total_score => nil)
        q2 = Quiz.create(:user => stud_8, :objective => this_obj, :total_score => 8)
        assert_equal 2, Quiz.where(:user => stud_8, :objective => this_obj).count
        
        capybara_login(@teacher_1)
        go_to_seminar
        go_to_term
        
        find("#seminar_term").select("3")
        check("reset")
        click_on("Update This Class")
        
        @seminar.reload
        assert_all_defaults
        
        # Term has changed
        assert_equal 3, @seminar.term
        assert_equal 1, @seminar_2.reload.term    # To make sure that only changes if the repeat choice is checked.
        
        # Score has been reset
        assert_nil obj_stud_5.reload.points_this_term
        assert_equal 4, obj_stud_5.points_all_time
        
        # Other key types have turned into pretest keys
        obj_stud_6.reload
        obj_stud_7.reload
        obj_stud_8.reload
        assert_equal 0, obj_stud_6.teacher_granted_keys
        assert_equal 0, obj_stud_7.dc_keys
        assert_equal 0, obj_stud_8.teacher_granted_keys
        assert_equal 1, obj_stud_8.pretest_keys
        
        # Unfinished quizzes have been deleted, but not finished quizzes
        q2.reload
        assert_equal 1, Quiz.where(:user => stud_8, :objective => this_obj).count
    end
    
    test "change term default" do
        assert_equal 1, @seminar.term
        
        capybara_login(@teacher_1)
        go_to_seminar
        go_to_term
        
        click_on("Update This Class")
        
        assert_equal 2, @seminar.reload.term
    end
    
    test "change term do not reset grades" do
        setup_scores
        test_obj_stud = set_score_for_random_student(@seminar)
        
        capybara_login(@teacher_1)
        go_to_seminar
        go_to_term
        
        find("#seminar_term").select("3")  # Choose 5 for 5th grade
        click_on("Update This Class")
        
        assert_equal 4, test_obj_stud.reload.points_this_term
    end
    
    test "change term repeat" do
        assert_equal 1, @seminar.term
        assert_equal 1, @seminar_2.term
        assert_equal 1, @avcne_seminar.term
        
        setup_scores
        test_obj_stud_1 = set_score_for_random_student(@seminar)
        test_obj_stud_2 = set_score_for_random_student(@seminar_2)
        
        capybara_login(@teacher_1)
        go_to_seminar
        go_to_term
        
        find("#seminar_term").select("3")  # Choose 5 for 5th grade
        check("reset")
        check("repeat")
        click_on("Update This Class")
        
        assert_equal 3, @seminar.reload.term
        assert_equal 3, @seminar_2.reload.term
        assert_equal 1, @avcne_seminar.reload.term
        assert_nil test_obj_stud_1.reload.points_this_term
        assert_nil test_obj_stud_2.reload.points_this_term
    end
    

    test "seminar objectives" do
        setup_objectives
        obj_array = [@objective_30, @objective_40, @objective_50, @own_assign, @assign_to_add]
        assert_not @seminar.objectives.include?(@assign_to_add)
        assert_nil @assign_to_add.objective_seminars.find_by(:seminar => @seminar)
        assert_equal 0, @objective_30.preassigns.count
        @this_preassign = @assign_to_add.preassigns.first
        @objective_zero_priority = objectives(:objective_zero_priority)
        
        # Mark a student ready, in order to test students_needed
        # It should be greater than zero because of this student
        @seminar.students << @student_3
        make_ready(@student_3, @assign_to_add)
        key_os = ObjectiveStudent.find_by(:user => @student_3, :objective => @assign_to_add)
        assert key_os.ready
        key_os.update(:points_all_time => 2)
        
        capybara_login(@teacher_1)
        go_to_seminar
        click_on("Objectives")
        
        obj_array.each do |obj|
            check("check_#{obj.id}")
        end
        uncheck("check_#{@objective_zero_priority.id}")
        
        click_on("Update This Class")
        
        @seminar.reload
        assert_all_defaults
        
        obj_array.each do |obj|
            assert @seminar.objectives.include?(obj)
        end
        assert_not @seminar.objectives.include?(@objective_zero_priority)
        assert @seminar.objectives.include?(@assign_to_add)
        assert_equal 1, @seminar.objective_seminars.where(:objective => @this_preassign).count
        assert @seminar.objectives.include?(@assign_to_add.preassigns.first)  
        @seminar.students.each do |student|
            assert_not_nil ObjectiveStudent.find_by(:objective => @assign_to_add, :user => student)
            # Mark ready for an objective with no pre-reqs
            assert ObjectiveStudent.find_by(:user => student, :objective => @objective_30).ready  
        end
        
        assert @assign_to_add.objective_seminars.find_by(:seminar => @seminar).students_needed > 0
        assert_selector('div', :text => "Class Updated")
        assert_selector('h2', :text => "Edit #{@seminar.name}")
    end

    test "objectives private dont show" do
        @priv_obj = Objective.where(:extent => "private").where.not(:user => @teacher_1).first
        assert_not_nil @priv_obj
        @seminar.objectives << @priv_obj
        
        capybara_login(@teacher_1)
        go_to_seminar
        click_on("Objectives")
        
        assert_no_selector("input", :id => "check_#{@priv_obj.id}")
        
        logout
        
        other_user = @priv_obj.user
        
        capybara_login(other_user)
        click_on("seminar_#{other_user.seminars.first.id}")
        click_on("Objectives")
        
        assert_selector("input", :id => "check_#{@priv_obj.id}")
    end

    test "pretests" do
        setup_scores
        ObjectiveStudent.update_all(:pretest_keys => 0)
        @seminar.objective_seminars.update_all(:pretest => 0)
        @os_0 = @seminar.objective_seminars[0]
        @os_1 = @seminar.objective_seminars[1]
        @os_2 = @seminar.objective_seminars[2]
        @os_3 = @seminar.objective_seminars[3]
        @os_2.update(:pretest => 1)
        @os_3.update(:pretest => 1)
        first_student = @seminar.students.first
        second_student = @seminar.students.second
        obj_stud_0_0 = ObjectiveStudent.find_by(:objective => @os_0.objective, :user => first_student)
        obj_stud_0_1 = ObjectiveStudent.find_by(:objective => @os_1.objective, :user => first_student)
        obj_stud_0_2 = ObjectiveStudent.find_by(:objective => @os_2.objective, :user => first_student)
        obj_stud_0_3 = ObjectiveStudent.find_by(:objective => @os_3.objective, :user => first_student)
        obj_stud_1_1 = ObjectiveStudent.find_by(:objective => @os_3.objective, :user => second_student)
        obj_stud_0_0.update(:points_all_time => 3)
        obj_stud_0_1.update(:points_all_time => 3)
        obj_stud_0_2.update(:pretest_keys => 2, :points_all_time => 3)
        obj_stud_0_3.update(:pretest_keys => 2, :points_all_time => 3)
        obj_stud_1_1.update(:pretest_keys => 0, :points_all_time => 10)
        
        capybara_login(@teacher_1)
        go_to_seminar
        click_on("Pretests")
        
        check("pretest_on_#{@os_1.objective.id}")
        uncheck("pretest_on_#{@os_3.objective.id}")
        
        click_on("Update This Class")
        
        assert_equal 0, @os_0.reload.pretest
        assert_equal 1, @os_1.reload.pretest
        assert_equal 1, @os_2.reload.pretest
        assert_equal 0, @os_3.reload.pretest
        
        # Give or take keys for added or removed pretests
        assert_equal 0, obj_stud_0_0.reload.pretest_keys
        assert_equal 2, obj_stud_0_1.reload.pretest_keys
        assert_equal 2, obj_stud_0_2.reload.pretest_keys
        assert_equal 0, obj_stud_0_3.reload.pretest_keys
        assert_equal 0, obj_stud_1_1.reload.pretest_keys    # Shouldn't give keys because the student already has a perfect score
        
        assert_selector('div', :text => "Class Updated")
        assert_selector('h2', :text => "Edit #{@seminar.name}")
    end
    
    test "seminar priorities" do
        @os_0 = @seminar.objective_seminars[0]
        @os_1 = @seminar.objective_seminars[1]
        @seminar.objective_seminars.update_all(:priority => 2)
        
        capybara_login(@teacher_1)
        go_to_seminar
        click_on("Priorities")
        
        choose("#{@os_0.id}_3")
        choose("#{@os_1.id}_0")
        
        click_on("Update This Class")
        
        @seminar.reload
        assert_all_defaults
        @os_0.reload
        @os_1.reload
        assert_equal 3, @os_0.priority
        assert_equal 0, @os_1.priority
        
        assert_selector('div', :text => "Class Updated")
        assert_selector('h2', :text => "Edit #{@seminar.name}")
    end
    
    test "delete seminar" do
        capybara_login(@teacher_1)
        go_to_seminar
        click_on("Remove This Class")
        
        assert_no_selector('a', :id => "confirm_remove_#{@seminar.id}")
        assert_selector('a', :id => "confirm_delete_#{@seminar.id}")  #Counterpart.  This button should not exist if the class is shared.
        find("#confirm_delete_#{@seminar.id}").click
        
        assert_equal @old_seminar_count - 1, Seminar.count
    end
    
    test "owner message" do
        assert_equal @seminar.owner, @teacher_1
        assert @seminar.teachers << @other_teacher # Need two teachers for the owner message to appear.
        
        capybara_login(@teacher_1)
        click_on("seminar_#{@seminar.id}")
        click_on("Remove This Class")
        
        assert_selector('div', :id => "owner_message")
    end

    test "remove seminar when alone" do
        # Does this one still need to be written?
    end

    test "remove seminar when sharing" do
        assert @teacher_1.seminars.include?(@avcne_seminar)
        assert @avcne_seminar.teachers.include?(@teacher_1)
        
        capybara_login(@teacher_1)
        click_on("seminar_#{@avcne_seminar.id}")
        click_on("Remove This Class")
        assert_no_selector('a', :id => "confirm_delete_#{@avcne_seminar.id}")  # Delete button shouldn't be offered for a shared class.
        assert_selector('a', :id => "confirm_remove_#{@avcne_seminar.id}")
        find("#confirm_remove_#{@avcne_seminar.id}").click
        
        @teacher_1.reload
        assert_equal @old_st_count - 1, SeminarTeacher.count
        assert_not @teacher_1.seminars.include?(@avcne_seminar)
        assert_not @avcne_seminar.teachers.include?(@teacher_1)
    end


    
    
end
