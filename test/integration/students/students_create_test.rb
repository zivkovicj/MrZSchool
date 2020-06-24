require 'test_helper'

class StudentsNewTest < ActionDispatch::IntegrationTest
    
    def setup
        setup_users
        setup_seminars
        setup_schools
        setup_scores
        @old_stud_count = Student.count
    end
    
    test 'create new students' do
        assert_equal 1, @teacher_1.verified
        assert_not_nil @teacher_1.school
        assignment_count = @seminar.objectives.count
        old_ss_count = SeminarStudent.count
        old_score_count = ObjectiveStudent.count
        
        # Setup old_students_needed to count that it's updated upon adding new students
        first_obj = @seminar.objectives.first
        this_obj_sem = ObjectiveSeminar.find_by(:objective => first_obj, :seminar => @seminar)
        this_obj_sem.students_needed_refresh
        old_students_needed = this_obj_sem.students_needed
        
        go_to_create_student_view
        
        fill_in ("first_name_1"), :with => "Phil"
        fill_in ("last_name_1"), :with => "Labonte"
        
        fill_in ("first_name_2"), :with => "Other_kid"
        fill_in ("last_name_2"), :with => "Burgaboot"
        fill_in ("user_number_2"), :with => "5"
        find("#school_year_2").select("7")
        
        fill_in ("first_name_3"), :with => "Ed"
        fill_in ("last_name_3"), :with => ""
        
        fill_in ("first_name_5"), :with => "Kid"
        fill_in ("last_name_5"), :with => "with Password"
        fill_in ("password_5"), :with => "Bean Sprouts"
        find("#school_year_5").select("P")
        
        fill_in ("first_name_6"), :with => "Chick"
        fill_in ("last_name_6"), :with => "with Username"
        fill_in ("username_6"), :with => "My_Username"  #Caps that should be downcased
        
        fill_in ("first_name_7"), :with => "Dude"
        fill_in ("last_name_7"), :with => "with Email"
        fill_in ("email_7"), :with => "dude@email.com"
        
        click_on("Create these student accounts")
        
        assert_equal @old_stud_count+5, Student.count
        assert_equal old_score_count + (assignment_count*5), ObjectiveStudent.count
        assert_equal old_ss_count + 5, SeminarStudent.count
        
        first_new_student = Student.find_by(:last_name => "Labonte")
        thisId = first_new_student.id
        assert_equal thisId, first_new_student.user_number
        assert_equal "pl#{thisId}", first_new_student.username 
        assert first_new_student.authenticate(first_new_student.username)
        assert_equal "", first_new_student.email
        assert_equal first_new_student.created_at, first_new_student.last_login
        assert_equal @teacher_1.school, first_new_student.school
        assert_equal 0, first_new_student.school_admin

        @new_ss = SeminarStudent.find_by(:seminar_id => @seminar.id, :user => first_new_student)
        assert_equal 0, @new_ss.pref_request
        assert_equal true, @new_ss.present
        assert_equal [0,0,0,0], @new_ss.stars_used_toward_grade
        assert_equal Date.today, @new_ss.last_consultant_day
        
        @pretest_obj = @seminar.objective_seminars.where(:pretest => 1).last.objective
        assert_not_nil @pretest_obj
        @new_os = first_new_student.objective_students.find_by(:objective => @pretest_obj)
        newest_obj_stud = first_new_student.objective_students.last
        assert_nil newest_obj_stud.points_this_term
        assert_equal 9, first_new_student.school_year  #Chosen as 9 by default
        assert_equal 1, first_new_student.verified
        
        second_new_student = Student.find_by(:last_name => "Burgaboot")
        assert @seminar.students.include?(second_new_student)
        assert_equal "Other_kid", second_new_student.first_name
        assert_equal "Burgaboot", second_new_student.last_name
        assert_equal 5, second_new_student.user_number
        assert_equal second_new_student.username, "ob5"
        assert second_new_student.authenticate("ob5")
        assert_equal 8, second_new_student.school_year  #Data value of 7 corresponds with 8th grade.
        
        third_new_student = Student.find_by(:last_name => "with Password")
        assert third_new_student.authenticate("Bean Sprouts")
        assert_equal 0, third_new_student.school_year
        
        fourth_new_student = Student.find_by(:last_name => "with Username")
        assert_equal "my_username", fourth_new_student.username
        
        fifth_new_student = Student.find_by(:last_name => "with Email")
        assert_equal "dude@email.com", fifth_new_student.email
    
        assert_text("#{@seminar.name}")
        assert_text("Current Term Scores")
        assert_equal old_students_needed + 5, this_obj_sem.reload.students_needed
    end
    
    test "username already taken" do
        @student_1.update!(:username => "nabwaffle49")
        
        go_to_create_student_view
        
        fill_in ("first_name_1"), :with => "Kid"
        fill_in ("last_name_1"), :with => "Stealing Username"
        fill_in ("username_1"), :with => "nabwaffle49"
        click_on("Create these student accounts")
        
        this_student = Student.find_by(:last_name => "Stealing Username")
        id_num = this_student.id
        assert_equal "ks#{id_num}", this_student.username
    end
    
    test "user_number too long" do
        go_to_create_student_view
        
        fill_in ("first_name_1"), :with => "Kid"
        fill_in ("last_name_1"), :with => "with Too-Long Username"
        fill_in ("user_number_1"), :with => 2000000001
        click_on("Create these student accounts")
        
        this_student = Student.find_by(:last_name => "with Too-Long Username")
        id_num = this_student.id
        assert_equal id_num, this_student.id
    end
    
    test "make_username" do
        go_to_create_student_view
        
        fill_in ("first_name_1"), :with => "Abigail"
        fill_in ("last_name_1"), :with => "Barnes"
        fill_in ("user_number_1"), :with => 5
        
        fill_in ("first_name_2"), :with => "Abigail"
        fill_in ("last_name_2"), :with => "Barnes"
        fill_in ("user_number_2"), :with => 5
        
        fill_in ("first_name_3"), :with => "Abigail"
        fill_in ("last_name_3"), :with => "Barnes"
        fill_in ("user_number_3"), :with => 5
        
        fill_in ("first_name_4"), :with => "Abigail"
        fill_in ("last_name_4"), :with => "Barnes"
        fill_in ("user_number_4"), :with => 5
        
        fill_in ("first_name_5"), :with => "Abigail"
        fill_in ("last_name_5"), :with => "Barnes"
        fill_in ("user_number_5"), :with => 5
        
        click_on("Create these student accounts")
        
        assert_equal @old_stud_count + 5, Student.count
        
        stud_1 = Student.all[-5]
        assert_equal "ab5", stud_1.username
        
        stud_2 = Student.all[-4]
        assert_equal "abigailb5", stud_2.username
        
        stud_3 = Student.all[-3]
        assert_equal "abarnes5", stud_3.username
        
        stud_4 = Student.all[-2]
        assert_equal "abigailbarnes5", stud_4.username
        
    end
    
end
