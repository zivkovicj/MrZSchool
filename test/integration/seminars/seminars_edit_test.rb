require 'test_helper'

class SeminarsEditTest < ActionDispatch::IntegrationTest
   
    def setup
        setup_users
        setup_seminars
        
        @old_seminar_count = Seminar.count
        @old_st_count = SeminarTeacher.count
    end
    
    def due_date_array
        [["06/05/2019","06/05/2019","06/05/2019","06/05/2019"],
         ["06/05/2019","06/05/2019","06/05/2019","06/05/2019"],
         ["06/05/2019","06/05/2019","06/05/2019","06/05/2019"],
         ["06/05/2019","06/05/2019","06/05/2019","06/05/2019"]]
    end
   
    test "edit seminar" do
        setup_objectives
        obj_array = [@objective_30, @objective_40, @objective_50, @own_assign, @assign_to_add]
        @objective_zero_priority = objectives(:objective_zero_priority)
        @os_0 = @seminar.objective_seminars.find_by(:objective => @objective_30)
        @os_1 = @seminar.objective_seminars.find_by(:objective => @objective_40)
        @os_2 = @seminar.objective_seminars.find_by(:objective => @objective_50)
        @os_3 = @seminar.objective_seminars.find_by(:objective => @own_assign)
        @os_2.update(:pretest => 1)
        @os_3.update(:pretest => 1)
        assert_equal 2, @os_2.priority
        assert_equal 2, @os_3.priority
        assert @seminar.objectives.include?(@objective_zero_priority)
        assert_not @seminar.objectives.include?(@assign_to_add)
        studToCheck = @seminar.students[11]
        assert_nil studToCheck.objective_students.find_by(:objective_id => @assign_to_add.id)
        
        capybara_login(@teacher_1)
        click_on("edit_seminar_#{@seminar.id}")
        
        obj_array.each do |obj|
            check("check_#{obj.id}")
        end
        uncheck("check_#{@objective_zero_priority.id}")
        click_on("Update This Class")
        
        @seminar.reload
        
        obj_array.each do |obj|
            assert @seminar.objectives.include?(obj)
        end
        assert_not @seminar.objectives.include?(@objective_zero_priority)
        assert @seminar.objectives.include?(@assign_to_add)
        assert @seminar.objectives.include?(@assign_to_add.preassigns.first)  
        @seminar.students.each do |student|
            assert_not_nil student.objective_students.find_by(:objective_id => @assign_to_add.id)
        end

        fill_in "Name", with: "Macho Taco Period"
        choose('8')
        check("pretest_on_#{@objective_30.id}")
        uncheck("pretest_on_#{@objective_50.id}")
        choose("#{@os_2.id}_3")
        choose("#{@os_3.id}_0")
        4.times do |n|
            4.times do |m|
                fill_in "seminar[checkpoint_due_dates][#{n}][#{m}]", with: due_date_array[n][m]
            end
        end
        
        click_on("Update This Class")
        
        @seminar.reload
        assert_equal "Macho Taco Period",  @seminar.name
        assert 8, @seminar.consultantThreshold

        @os_0.reload
        @os_1.reload
        @os_2.reload
        @os_3.reload
    
        assert_equal due_date_array, @seminar.checkpoint_due_dates
        
        assert_equal 1, @os_0.pretest
        assert_equal 0, @os_1.pretest
        assert_equal 0, @os_2.pretest
        assert_equal 1, @os_3.pretest

        assert_equal 3, @os_2.priority
        assert_equal 0, @os_3.priority
        
        assert_selector('h2', "Edit #{@seminar.name}")
    end
    
    test "delete seminar" do
        capybara_login(@teacher_1)
        click_on("edit_seminar_#{@seminar.id}")
        
        assert_no_selector('p', :id => "remove_#{@seminar.id}")
        assert_selector('p', :id => "delete_#{@seminar.id}")  #Counterpart.  This button should not exist if the class is shared.
        find("#delete_#{@seminar.id}").click
        click_on("confirm_#{@seminar.id}")
        
        assert_equal @old_seminar_count - 1, Seminar.count
    end
    
    test "no delete button for shared class" do
        capybara_login(@other_teacher)
        click_on("edit_seminar_#{@avcne_seminar.id}")
        
        assert_selector('p', :id => "remove_#{@avcne_seminar.id}")   #Counterpart.  This button should not exist if the class is not shared.
        assert_no_selector('p', :id => "delete_#{@avcne_seminar.id}")
    end
    
    test "remove seminar" do
        assert @teacher_1.seminars.include?(@avcne_seminar)
        assert @avcne_seminar.teachers.include?(@teacher_1)
        
        capybara_login(@teacher_1)
        click_on("edit_seminar_#{@avcne_seminar.id}")
        find("#remove_#{@avcne_seminar.id}").click
        find("#confirm_remove_#{@avcne_seminar.id}").click
        
        @teacher_1.reload
        assert_equal @old_st_count - 1, SeminarTeacher.count
        assert_not @teacher_1.seminars.include?(@avcne_seminar)
        assert_not @avcne_seminar.teachers.include?(@teacher_1)
    end
    
    test "some user can edit" do
        @avcne_seminar.teachers << @teacher_3
        @st_1 = @teacher_1.seminar_teachers.find_by(:seminar => @avcne_seminar)
        @st_2 = @other_teacher.seminar_teachers.find_by(:seminar => @avcne_seminar)
        @st_3 = @teacher_3.seminar_teachers.find_by(:seminar => @avcne_seminar)
        assert_not @st_1.can_edit
        assert @st_2.can_edit
        assert_not @st_3.can_edit
        
        capybara_login(@teacher_3)
        click_on("edit_seminar_#{@avcne_seminar.id}")
        find("#remove_#{@avcne_seminar.id}").click
        find("#confirm_remove_#{@avcne_seminar.id}").click
        
        @st_1.reload
        @st_2.reload
        assert_not @st_1.can_edit
        assert @st_2.can_edit
        
        click_on("Log out")
        
        capybara_login(@other_teacher)
        click_on("edit_seminar_#{@avcne_seminar.id}")
        find("#remove_#{@avcne_seminar.id}").click
        find("#confirm_remove_#{@avcne_seminar.id}").click
        
        @st_1.reload
        assert @st_1.can_edit
    end
end