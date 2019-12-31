require 'test_helper'

class ObjectivesFormTest < ActionDispatch::IntegrationTest
    
    include BuildPreReqLists
    include ObjectivesHelper
    
    def setup
        setup_users
        @old_objective_count = Objective.count
    end
    
    def go_to_all_objectives
        click_on("View/Create Content")
        click_on('All Objectives')
    end
    
    def create_and_add_student(seminar)
        @new_student = Student.new(:first_name => "new", :last_name => "student")
        @new_student.save
        seminar.students << @new_student 
    end
    
    def go_to_objective_show_page(this_objective)
        click_on("View/Create Content")
        click_on('All Objectives')
        click_on(this_objective.full_name)
    end
    
    def assert_on_objective_show_page(this_objective)
        assert_selector('h2', :text => this_objective.name)
    end
    
    
    ##
    # BEGIN TESTS
    ##
    
    test "edit objective basic info" do 
        setup_objectives
        
        assert_equal "public", @assign_to_add.extent
        assert_equal topics(:integers), @assign_to_add.topic
        root_topic = topics(:roots)
        
        capybara_login(@teacher_1)
        go_to_objective_show_page(@assign_to_add)
        click_on "Basic Info"
        
        fill_in "name", with: "Bunsen Burritos"
        fill_in "objective[catchy_name]", with: "What, you want to be even catchier?"
        fill_in "objective[objective_number]", with: 950
        find("#private_objective").choose
        choose("topic_#{root_topic.id}")
        click_on "Save Changes"
        
        @assign_to_add.reload
        assert_equal "Bunsen Burritos", @assign_to_add.name
        assert_equal "What, you want to be even catchier?", @assign_to_add.catchy_name
        assert_equal 950, @assign_to_add.objective_number
        assert_equal "private", @assign_to_add.extent
        assert_equal root_topic, @assign_to_add.topic
        
        assert_on_objective_show_page(@assign_to_add)
    end
    
    test "default editing" do
        setup_objectives 
        
        assert_equal "add integers on a number line", @assign_to_add.name
        assert_equal "Seagulls", @assign_to_add.catchy_name
        assert_equal "public", @assign_to_add.extent
        assert_equal topics(:integers), @assign_to_add.topic
        assert_equal 960, @assign_to_add.objective_number
        
        capybara_login(@teacher_1)
        go_to_objective_show_page(@assign_to_add)
        click_on "Basic Info"
        
        click_on "Save Changes"
        
        @assign_to_add.reload
        assert_equal "add integers on a number line", @assign_to_add.name
        assert_equal "Seagulls", @assign_to_add.catchy_name
        assert_equal "public", @assign_to_add.extent
        assert_equal topics(:integers), @assign_to_add.topic
        assert_equal 960, @assign_to_add.objective_number
        assert_on_objective_show_page(@assign_to_add)
    end

    test "ensure objective_number" do
        setup_objectives
        assert_equal 960, @assign_to_add.objective_number
        
        capybara_login(@teacher_1)
        go_to_objective_show_page(@assign_to_add)
        click_on "Basic Info"
        
        fill_in "objective[objective_number]", with: ""
        click_on "Save Changes"
        
        @assign_to_add.reload
        assert_equal 99, @assign_to_add.objective_number
    end
    
    test "include files" do
        setup_objectives
        setup_worksheets
        
        assert @own_assign.worksheets.include?(@worksheet_1)
        assert_not @own_assign.worksheets.include?(@worksheet_2)
        assert_not @own_assign.worksheets.include?(@worksheet_3)
        
        capybara_login(@teacher_1)
        go_to_objective_show_page(@own_assign)
        click_on "Files"
        
        uncheck("check_#{@worksheet_1.id}")
        check("check_#{@worksheet_2.id}")
        check("check_#{@worksheet_3.id}")
        assert_selector("h3", :text => "Upload a New File")  #Counterpart.  This line shouldn't show up for students.
        click_on("Save Changes")
        
        assert_selector("h2", :text => @own_assign.name)
        
        assert_not @own_assign.worksheets.include?(@worksheet_1)
        assert @own_assign.worksheets.include?(@worksheet_2)
        assert @own_assign.worksheets.include?(@worksheet_3)
    end
    
    test "include files blank" do
        setup_objectives
        setup_worksheets
        
        assert @own_assign.worksheets.include?(@worksheet_1)
        
        capybara_login(@teacher_1)
        go_to_objective_show_page(@own_assign)
        click_on "Files"
        
        uncheck("check_#{@worksheet_1.id}")
        click_on("Save Changes")
        
        assert_selector("h2", :text => @own_assign.name)
        
        assert_not @own_assign.worksheets.include?(@worksheet_1)   
    end
    
    test "include labels and quantities" do
        setup_objectives
        setup_labels
        
        old_name = @own_assign.name    # To ensure that name isn't changed.  (That was happening with one version.)
        old_obj_num = @own_assign.objective_number # To ensure this isn't changed either.
        assert_not @own_assign.labels.include?(@user_l)
        assert_not @own_assign.labels.include?(@admin_l)
        @own_assign.labels << @other_l_pub
        old_label_objective_count = LabelObjective.count
        
        capybara_login(@teacher_1)
        go_to_objective_show_page(@own_assign)
        click_on "Labels"
        
        #assert_no_text("You are viewing the labels.  You may not edit them because this objective was created by another teacher.")
        
        # Changes on the labels screen
        check("check_#{@user_l.id}")
        check("check_#{@admin_l.id}")
        uncheck("check_#{@other_l_pub.id}")
        click_on("Save Changes")
        
        assert_selector('h2', :text => "Edit Quantities and Point Values")
        assert_selector('h2', :text => "for #{@own_assign.name}")
        
        @own_assign.reload
        assert_equal old_name, @own_assign.name
        assert_equal old_obj_num, @own_assign.objective_number
        assert @own_assign.labels.include?(@user_l)
        assert @own_assign.labels.include?(@admin_l)
        assert_not @own_assign.labels.include?(@other_l_pub)
        assert_equal old_label_objective_count + 1, LabelObjective.count
        
        # Changes on the quantities screen
        lab_obj_u = @own_assign.label_objectives.find_by(:label => @user_l)
        lab_obj_a = @own_assign.label_objectives.find_by(:label => @admin_l)
        assert_equal 1, lab_obj_u.quantity
        assert_equal 1, lab_obj_a.quantity
        assert_equal 1, lab_obj_u.point_value
        assert_equal 1, lab_obj_a.point_value
        
        select('2', :from => "syl_#{lab_obj_u.id}_quantity")
        select('3', :from => "syl_#{lab_obj_a.id}_quantity")
        select('4', :from => "syl_#{lab_obj_u.id}_point_value")
        select('5', :from => "syl_#{lab_obj_a.id}_point_value")
        
        # Counterparts to the test that blanks this quantity box if the label has no questions.
        assert_selector('select', :id => "syl_#{lab_obj_u.id}_quantity") 
        assert_no_text(no_questions_message)
        
        click_on "Update These Quantities"
        
        assert_equal 2, lab_obj_u.reload.quantity
        assert_equal 3, lab_obj_a.reload.quantity
        assert_equal 400, lab_obj_u.reload.point_value
        assert_equal 500, lab_obj_a.reload.point_value
    end
    
    test "include labels blank" do
        setup_labels
        setup_objectives
        
        @own_assign.labels << @other_l_pub
        old_label_objective_count = LabelObjective.count
        
        capybara_login(@teacher_1)
        go_to_objective_show_page(@own_assign)
        click_on "Labels"
        
        # Changes on the labels screen
        uncheck("check_#{@other_l_pub.id}")
        click_on("Save Changes")
        
        assert_selector('h2', :text => "Edit Quantities and Point Values")
        assert_selector('h2', :text => "for #{@own_assign.name}")
        assert_text(no_label_message)
        assert_no_text(quantity_instructions)
        
        @own_assign.reload
        assert_equal 0, @own_assign.labels.count
        assert_equal old_label_objective_count - 1, LabelObjective.count
    end
    
    test "include seminars" do
        setup_objectives
        
        old_objective_seminar_count = ObjectiveSeminar.count
        assert @own_assign.seminars.count > 0
        old_class = @own_assign.seminars.first
        classes_not_included = @teacher_1.seminars.where.not(:id => @own_assign.seminar_ids)
        first_class_to_add = classes_not_included[0]
        second_class_to_add = classes_not_included[1]
        preassign_to_add_to_seminar = @own_assign.preassigns.where.not(:id => first_class_to_add.objective_ids).first
        
        # Mark a student ready, in order to test students_needed
        # It should be greater than zero because of this student
        first_class_to_add.students << @student_3
        make_ready(@student_3, @own_assign)
        key_os = ObjectiveStudent.find_by(:user => @student_3, :objective => @own_assign)
        assert key_os.ready
        key_os.update(:points_all_time => 2)
        
        # Put a student in that class to ensure that ObjectiveStudents are created for that student
        # After the seminar is added to this objective
        create_and_add_student(first_class_to_add)
        assert_nil @new_student.objective_students.find_by(:objective => @own_assign)
        
        capybara_login(@teacher_1)
        go_to_objective_show_page(@own_assign)
        click_on "Included Classes"
        
        check(first_class_to_add.name)
        check(second_class_to_add.name)
        uncheck(old_class.name)
        click_on("Save Changes")
        
        @own_assign.reload
        first_class_to_add.reload
        assert @own_assign.seminars.include?(first_class_to_add)
        assert @own_assign.seminars.include?(second_class_to_add)
        assert_not @own_assign.seminars.include?(old_class)
        assert 2, @own_assign.objective_seminars.find_by(:seminar => first_class_to_add).priority
        assert @own_assign.objective_seminars.find_by(:seminar => first_class_to_add).students_needed > 0
        assert first_class_to_add.objectives.include?(preassign_to_add_to_seminar)
        assert_equal old_objective_seminar_count + 5, ObjectiveSeminar.count   # Two new classes, three new preassigns
        assert_not_nil @new_student.reload.objective_students.find_by(:objective => @own_assign)
    end
    
    test "include seminars blank" do
        setup_objectives
        
        old_objective_seminar_count = ObjectiveSeminar.count
        assert @own_assign.seminars.count > 0
        old_class = @own_assign.seminars.first
        
        capybara_login(@teacher_1)
        go_to_objective_show_page(@own_assign)
        click_on "Included Classes"
        
        uncheck(old_class.name)
        click_on("Save Changes")
        
        @own_assign.reload
        assert_equal 0, @own_assign.seminars.count
        assert_equal old_objective_seminar_count - 1, ObjectiveSeminar.count
    end
    
    test "pre reqs" do
        @remove_as_preassign = objectives(:objective_90)
        @sub_preassign = objectives(:objective_100)
        @preassign_to_add = objectives(:objective_110)
        @already_preassign_to_main = objectives(:objective_120)
        @already_preassign_to_super = objectives(:objective_130)
        @main_objective = objectives(:objective_140)
        @super_objective = objectives(:objective_150)
        
        old_precondition_count = Precondition.count
        
        assert @super_objective.preassigns.include?(@main_objective)
        assert @super_objective.preassigns.include?(@already_preassign_to_super) # To check that preassign isn't added twice.
        assert @main_objective.preassigns.include?(@already_preassign_to_main)
        assert @main_objective.preassigns.include?(@remove_as_preassign)
        assert_not @super_objective.preassigns.include?(@preassign_to_add)
        assert_not @super_objective.preassigns.include?(@sub_preassign)
        assert_not @main_objective.preassigns.include?(@preassign_to_add)
        assert_not @main_objective.preassigns.include?(@sub_preassign)
        assert_not @main_objective.preassigns.include?(@already_preassign_to_super)
        
        # Student info to check whether readiness is marked upon changing pre-reqs.
            # Both student are ready for main objective at the beginning, but student_3 should change to not ready because a
            #   pre-req was added that she hadn't passed.
        ObjectiveStudent.find_or_create_by(:user => @student_2, :objective => @preassign_to_add).update(:points_all_time => 7)
        ObjectiveStudent.find_or_create_by(:user => @student_2, :objective => @sub_preassign).update(:points_all_time => 7)
        ObjectiveStudent.find_or_create_by(:user => @student_2, :objective => @already_preassign_to_super).update(:points_all_time => 7)
        ObjectiveStudent.find_or_create_by(:user => @student_3, :objective => @preassign_to_add).update(:points_all_time => 2)
        @main_objective.preassigns.each do |preassign|
            ObjectiveStudent.find_or_create_by(:user => @student_2, :objective => preassign).set_points("manual", 9)
            ObjectiveStudent.find_or_create_by(:user => @student_3, :objective => preassign).set_points("manual", 9)
        end
        os_2 = ObjectiveStudent.find_or_create_by(:user => @student_2, :objective => @main_objective)
        os_2.set_ready
        assert os_2.ready
        os_3 = ObjectiveStudent.find_or_create_by(:user => @student_3, :objective => @main_objective)
        os_3.set_ready
        assert os_3.ready
        
            # Neither student_4 nor 5 is ready, but after deleting one pre-req, student 4 is now ready.
        ObjectiveStudent.find_or_create_by(:user => @student_4, :objective => @remove_as_preassign).update(:points_all_time => 2)
        ObjectiveStudent.find_or_create_by(:user => @student_4, :objective => @already_preassign_to_main).update(:points_all_time => 7)
        ObjectiveStudent.find_or_create_by(:user => @student_4, :objective => @already_preassign_to_super).update(:points_all_time => 7)
        ObjectiveStudent.find_or_create_by(:user => @student_4, :objective => @preassign_to_add).update(:points_all_time => 7)
        ObjectiveStudent.find_or_create_by(:user => @student_4, :objective => @sub_preassign).update(:points_all_time => 7)
        ObjectiveStudent.find_or_create_by(:user => @student_5, :objective => @remove_as_preassign).update(:points_all_time => 2)
        ObjectiveStudent.find_or_create_by(:user => @student_5, :objective => @already_preassign_to_super).update(:points_all_time => 2)
        
        os_4 = ObjectiveStudent.find_or_create_by(:user => @student_4, :objective => @main_objective)
        os_4.set_ready
        assert_not os_4.ready
        os_5 = ObjectiveStudent.find_or_create_by(:user => @student_5, :objective => @main_objective)
        os_5.set_ready
        assert_not os_5.ready
        
        # Establish a student to make sure that ObjectiveStudents are created for the new pre-reqs
        first_class = @main_objective.seminars.create(:name => "First Class")
        assert_not_nil first_class
        create_and_add_student(first_class)
        assert_nil @new_student.objective_students.find_by(:objective => @preassign_to_add)
        
        capybara_login(@teacher_1)
        go_to_all_objectives
        click_on(@main_objective.full_name)
        click_on("Pre Reqs")
        
        check("check_#{@preassign_to_add.id}")
        check("check_#{@already_preassign_to_super.id}")
        uncheck("check_#{@remove_as_preassign.id}")
        click_button("Save Changes")
        
        @main_objective.reload
        @super_objective.reload
        
        assert @main_objective.preassigns.include?(@already_preassign_to_super)
        assert @main_objective.preassigns.include?(@preassign_to_add)
        assert @main_objective.preassigns.include?(@sub_preassign)
        assert_not @main_objective.preassigns.include?(@remove_as_preassign)
        assert @super_objective.preassigns.include?(@preassign_to_add)
        assert @super_objective.preassigns.include?(@sub_preassign)
        assert @super_objective.preassigns.include?(@remove_as_preassign)
        assert_equal old_precondition_count + 4, Precondition.count   #To make sure that Preconditions were not created that would be redundant
        
        
        assert os_2.reload.ready        # Ready, and stayed
        assert_not os_3.reload.ready    # Ready, but lost readiness
        assert os_4.reload.ready        # Not ready, but became ready
        assert_not os_5.reload.ready    # Not ready, and stayed not ready
    end
    
    test "pre reqs blank" do
        @main_objective = objectives(:objective_140)
        @remove_as_preassign = objectives(:objective_90)
        @already_preassign_to_main = objectives(:objective_120)
        
        assert @main_objective.preassigns.include?(@remove_as_preassign)
        assert @main_objective.preassigns.include?(@already_preassign_to_main)
        assert_equal 2, @main_objective.preassigns.count
        
        capybara_login(@teacher_1)
        go_to_all_objectives
        click_on(@main_objective.full_name)
        click_on("Pre Reqs")
        
        uncheck("check_#{@remove_as_preassign.id}")
        uncheck("check_#{@already_preassign_to_main.id}")
        
        click_button("Save Changes")
        
        @main_objective.reload
        
        assert_equal 0, @main_objective.reload.preassigns.count 
    end

    test "pre req options 1" do
            # Mainassign doesn't appear as an option for a preassign
            # That would create an impossible loop.
        setup_objectives
        
        capybara_login(@admin_user)
        go_to_all_objectives
        click_on(@objective_40.full_name)
        click_on("Pre Reqs")
        
        assert_no_selector('input', :id => "check_#{@own_assign.id}")
        assert_selector('input', :id => "check_#{@objective_30.id}")
    end
    
    test "pre req options 2" do
        setup_objectives
        
        @super_objective = objectives(:objective_150)
            # But that mainassign SHOULD appear as an option for others
        capybara_login(@admin_user)
        go_to_all_objectives
        click_on(@super_objective.full_name)
        click_on("Pre Reqs")
        
        assert_selector('input', :id => "check_#{@own_assign.id}")
    end
        
    test "do not add prereq if seminar already has it" do
        setup_objectives
        setup_seminars
        
        @objective_80 = objectives(:objective_80)
        ObjectiveSeminar.create(:seminar_id => @seminar.id, :objective_id => @objective_80.id)
        old_os_count = ObjectiveSeminar.count
        assert @assign_to_add.preassigns.include?(@objective_80)
        
        capybara_login(@teacher_1)
        go_to_seminar
        click_on("Objectives")
        check("check_#{@assign_to_add.id}")
        click_on('Update This Class')

        assert_equal old_os_count + 1, ObjectiveSeminar.count
        assert_equal 1, ObjectiveSeminar.where(:seminar_id => @seminar.id, :objective_id => @objective_80.id).count
    end
    
    test "remove pre_req" do
        setup_objectives
        
        #@own_assign was chosen because it has two pre-requisites
        assert @own_assign.preassigns.include?(@objective_40)
        assert @objective_40.mainassigns.include?(@own_assign)
        assert @own_assign.preassigns.include?(@objective_50)
        assert @objective_50.mainassigns.include?(@own_assign)
        
        capybara_login(@own_assign.user)
        go_to_all_objectives
        click_on(@own_assign.full_name)
        click_on("Pre Reqs")
        
        uncheck("check_#{@objective_40.id}")
        click_on("Save Changes")
        
        @own_assign.reload
        assert_not @own_assign.preassigns.include?(@objective_40)
        assert_not @objective_40.mainassigns.include?(@own_assign)
        assert @own_assign.preassigns.include?(@objective_50)
        assert @objective_50.mainassigns.include?(@own_assign)
    end
    
    test "teacher views public objective" do
        setup_objectives
        setup_seminars
        
        assert @seminar.objectives.include?(@objective_20)
        capybara_login(@teacher_1)
        go_to_all_objectives
        click_on(@objective_20.full_name)
        
        click_on("Basic Info")
        assert_text("You are viewing the details of this objective. You may not make any edits because it was created by another teacher.")
        assert_no_selector('input', :id => "name", :visible => true)
        
        click_on(@objective_20.full_name)
        click_on("Pre Reqs")
        assert_selector('li', :text => @objective_20.preassigns.first.short_name)
    end
    
    test "empty name update" do
        setup_objectives
        old_name = @own_assign.name
        
        capybara_login(@teacher_1)
        go_to_all_objectives
        click_on(@own_assign.full_name)
        click_on("Basic Info")
        
        fill_in "name", with: ""
        click_on("Save Changes")
        
        @own_assign.reload
        assert_equal old_name, @own_assign.name
    end
    
    test "objective with label but not questions" do
        # Check that the message appears to let users know that a chosen label has no questions.
        setup_labels
        
        @new_label = Label.create(:name => "New Label", :extent => "public", :user => @teacher_1)
        
        capybara_login(@teacher_1)
        click_on("View/Create Content")
        click_on("New Objective")
        fill_in("name", :with => "Name")
        click_on("Create a New Objective")
        click_on("Labels")
        check("check_#{@new_label.id}")
        click_on("Save Changes")
        
        assert_no_text(no_label_message)
        assert_text(quantity_instructions)
        assert_text(no_questions_message)
        
        @lo = @new_label.label_objectives.find_by(:objective => Objective.last)
        assert_no_selector('select', :id => "syl_#{@lo.id}_quantity")
    end
    
    
end
