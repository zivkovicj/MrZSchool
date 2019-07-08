require 'test_helper'

class SeminarsIndexTest < ActionDispatch::IntegrationTest

  def setup
    setup_users
    setup_schools
    setup_seminars
  end

  test "Redirect for non-admin" do
    log_in_as(@teacher_1)
    get seminars_path
    assert_redirected_to login_url
  end
  
  test "seminars back button" do
      capybara_login(@admin_user)
      click_on("Seminars")
      assert_selector("h2", :text => "All Classes")
      assert_not_on_admin_page
      click_on("back_button")
      assert_on_admin_page
  end
  
  test "delete seminar" do
    old_sem_count = Seminar.count
    first_obj = @seminar.objectives.first
    first_obj_sem_count = first_obj.seminars.count
    setup_consultancies
    consultancy_count = @seminar.consultancies.count
    assert_not_equal 0, consultancy_count
    this_user = @seminar.teachers.first
    this_user_seminar_count = this_user.seminars.count
    
    capybara_login(@admin_user)
    click_on("Seminars Index")
    fill_in "search_field", with: @seminar.name
    click_on("Search")
    find("#delete_#{@seminar.id}").click
    click_on("confirm_#{@seminar.id}")
    
    first_obj.reload
    this_user.reload
    assert_equal old_sem_count - 1, Seminar.count
    assert_equal first_obj_sem_count - 1, first_obj.seminars.count
    assert_equal this_user_seminar_count - 1, this_user.seminars.count
  end
end