require 'test_helper'

class StudentsSearchTest < ActionDispatch::IntegrationTest

  def setup
    setup_users
    @last_student = Student.last
    setup_schools
    setup_seminars
    setup_seminars
  end
  
  def go_to_student_search
    capybara_login(@teacher_1)
    click_on("seminar_#{@seminar.id}")
    click_on("Basic Info")
    click_on("Add an Existing Student")
  end
  
  test 'searching' do
    go_to_student_search
    
    assert_no_text(@student_1.last_name_first)
    fill_in "search_field", with: @student_1.user_number
    click_button('Search')
    assert_text(@student_1.last_name_first)
    
    fill_in "search_field", with: @student_2.user_number
    click_button('Search')
    assert_text(@student_2.last_name_first)
    assert_no_text(@student_1.last_name_first)
    
    fill_in "search_field", with: @student_1.last_name
    choose('Last name')
    click_button('Search')
    assert_text(@student_1.last_name_first)
    
    fill_in "search_field", with: 758
    click_button('Search')
    assert_text("Nothing found for that search")
    assert_no_text(@student_1.last_name_first)
    
    fill_in "search_field", with: @student_2.first_name
    choose('First name')
    click_button('Search')
    assert_text(@student_2.last_name_first)
    
    fill_in "search_field", with: @student_1.email
    choose('E-mail')
    click_button('Search')
    assert_text(@student_1.last_name_first)
    
    fill_in "search_field", with: @student_2.user_number
    choose('Student number')
    click_button('Search')
    assert_text(@student_2.last_name_first)
    assert_text("Already registered for this class")
    
    fill_in "search_field", with: @other_school_student.user_number
    choose('Student number')
    click_button('Search')
    assert_no_text(@other_school_student.last_name_first)
    
    assert_not_equal @teacher_1, @student_90.sponsor    # Student sponsored by another teacher
    fill_in "search_field", with: @student_90.user_number
    choose('Student number')
    click_button('Search')
    assert_text(@student_90.last_name_first)
  end
  
  
  test 'add student to class' do
    setup_objectives
    setup_scores
    
    first_objective = @seminar.objectives.first
    stud_to_add = Student.all.detect{|x| @seminar.students.include?(x) == false}
    
    #Setup before adding student
    old_ss_count = SeminarStudent.count
    old_score_count = ObjectiveStudent.count
    stud_objective_count = stud_to_add.objective_students.count
    new_objective_count = @seminar.objectives.where.not(:id => stud_to_add.objective_ids).count  #Objectives in the new seminar that student didn't have yet.
    assert new_objective_count > 0
      
      # ObjectiveSeminar to test that students_needed is updated
      this_obj_sem = ObjectiveSeminar.find_by(:objective => first_objective, :seminar => @seminar)
      this_obj_sem.students_needed_refresh
      old_studs_need_count = this_obj_sem.students_needed
    
    # Search for and add the student
    go_to_student_search
    assert_no_text(@student_1.last_name_first)
    fill_in "search_field", with: stud_to_add.user_number
    click_button('Search')
    assert_text(stud_to_add.last_name_first)
    click_button('Add to this class')
    
    #After adding student
    @new_ss = SeminarStudent.last
    @new_student = Student.find(@new_ss.user_id)
    assert_equal @new_student, stud_to_add
    assert_equal 0, @new_ss.pref_request
    assert_equal true, @new_ss.present
    assert_equal old_ss_count + 1, SeminarStudent.count
    assert_equal @teacher_1, @new_student.sponsor
    assert_equal Date.today, @new_ss.last_consultant_day
    
    @seminar.reload
    stud_to_add.reload
    assert @seminar.students.include?(stud_to_add)
    assert_equal stud_objective_count + new_objective_count, stud_to_add.objectives.count
    assert_equal old_score_count + new_objective_count, ObjectiveStudent.count
    assert_equal 1, stud_to_add.objective_students.where(:objective => first_objective).count  #Don't add another copy of the same objective_student
    
    # students_needed has been updated for obj_sem
    assert_equal old_studs_need_count + 1, this_obj_sem.reload.students_needed
  end
  
  test "cant find unverified student" do
    # The counterpart is in the "searching" test
    @last_student = Student.last
    @last_student.update(:verified => 0)
  
    go_to_student_search
    
    fill_in "search_field", with: @last_student.user_number
    click_button('Search')
    assert_no_text(@last_student.last_name_first)
  end
  
  test "unverified teacher can only find sponsored students" do
    @last_student = Student.last
    @unverified_teacher_class = seminars(:unverified_teacher_class)
    @last_student.update(:sponsor => @unverified_teacher)
    
    capybara_login(@unverified_teacher)
    
    assert @unverified_teacher.school.students.include?(@student_1)
    click_on("seminar_#{@unverified_teacher_class.id}")
    click_on("Basic Info")
    click_on("Add an Existing Student")
    
    fill_in "search_field", with: @student_1.user_number
    click_button('Search')
    assert_no_text(@student_1.last_name_first)
    
    fill_in "search_field", with: @last_student.user_number
    click_button('Search')
    assert_text(@last_student.last_name_first)
  end
  
end
