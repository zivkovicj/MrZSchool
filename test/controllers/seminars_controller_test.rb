require 'test_helper'

class SeminarsControllerTest < ActionDispatch::IntegrationTest
  
  
  def setup
    setup_users
    setup_schools
    setup_seminars
    setup_scores
  end
  
  test "seminars index test" do
    log_in_as(@admin_user)
    get seminars_path
    assert_template 'seminars/index'
  end
  
  test "seminars index as non-admin" do
    log_in_as(@teacher_1)
    get seminars_path
    assert_redirected_to login_url
  end
  
  test "should redirect destroy when not logged in" do
    assert_no_difference 'Seminar.count' do
      delete seminar_path(@seminar)
    end
    assert_redirected_to login_url
  end
  
  test "should redirect destroy when logged in as wrong user" do
    log_in_as @other_teacher
    assert_no_difference 'Seminar.count' do
      delete seminar_path(@seminar)
    end
    assert_redirected_to login_url
  end
  
  test "should delete when logged in" do
  # Also checks that objectives and seminar_students are automatically deleted.
    log_in_as @teacher_1
    oldAssignCount = ObjectiveSeminar.count
    thisClassAssigns = @seminar.objectives.count
    assert_operator thisClassAssigns, :>, 0
    old_ss_count = SeminarStudent.count
    this_class_ss = @seminar.seminar_students.count
    assert_operator this_class_ss, :>, 0
    assert_difference 'Seminar.count', -1 do
      delete seminar_path(@seminar)
    end
    assert_equal oldAssignCount - thisClassAssigns, ObjectiveSeminar.count
    assert_equal old_ss_count - this_class_ss, SeminarStudent.count
    assert_redirected_to @teacher_1
  end
  
  test "delete seminar_students upon deleting class" do
    log_in_as @teacher_1
    num_ss = -1 * @seminar.seminar_students.count
    assert_difference 'SeminarStudent.count', num_ss do
      delete seminar_path(@seminar)  
    end
  end
  
  test "should redirect create when not logged in" do
    assert_no_difference 'Seminar.count' do
      post '/seminars/', params: { seminar: { name: "2nd period",  consultantThreshold: 7, school_year: 9} }
    end
  end
  
end
