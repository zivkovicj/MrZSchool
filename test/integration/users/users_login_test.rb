require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest
  
  def setup
    setup_users
    setup_schools
  end
  
  test "login/out as admin" do
    get login_path
    post login_path, params: { session: { username:    @admin_user.email,
                                          password: 'password' } }
    assert is_logged_in?
    assert_redirected_to @admin_user
    follow_redirect!
    assert_template 'admins/show'
    assert_select "a[href=?]", login_path, count: 0
    assert_select "a[href=?]", logout_path
    
    delete logout_path
    assert_not is_logged_in?
    assert_redirected_to login_url
    follow_redirect!
    assert_select "a[href=?]", login_path
    assert_select "a[href=?]", logout_path,      count: 0
    assert_select "a[href=?]", admin_path(@admin_user), count: 0
  end
  
  test "login/out as teacher" do
    get login_path
    post login_path, params: { session: { username:    @teacher_1.email,
                                          password: 'password' } }
    assert is_logged_in?
    assert_redirected_to @teacher_1
    follow_redirect!
    assert_template 'teachers/show'
    assert_select "a[href=?]", login_path, count: 0
    assert_select "a[href=?]", logout_path
    
    delete logout_path
    assert_not is_logged_in?
    assert_redirected_to login_url
    follow_redirect!
    assert_select "a[href=?]", login_path
    assert_select "a[href=?]", logout_path,      count: 0
    assert_select "a[href=?]", teacher_path(@teacher_1), count: 0
  end
  
  test "login/out as student" do
    get login_path
    post login_path, params: { session: { username:    @student_1.username,
                                          password: 'password' } }
    assert is_logged_in?
    assert_redirected_to @student_1
    follow_redirect!
    assert_template 'students/show'
    assert_select "a[href=?]", login_path, count: 0
    assert_select "a[href=?]", logout_path
    
    delete logout_path
    assert_not is_logged_in?
    assert_redirected_to login_url
    follow_redirect!
    assert_select "a[href=?]", login_path
    assert_select "a[href=?]", logout_path,      count: 0
    assert_select "a[href=?]", student_path(@student_1), count: 0
  end
  
  test "invalid password" do
    get login_path
    post login_path, params: { session: { username:    @teacher_1.email,
                                          password: 'beer pong' } }
    assert_not is_logged_in?
    assert_template 'sessions/new'
    assert_select "a[href=?]", login_path
    assert_select "a[href=?]", logout_path, count: 0
    assert_select "a[href=?]", teacher_path(@teacher_1), count: 0
  end
  
  test "login with remembering" do
    log_in_as(@teacher_1, remember_me: '1')
    assert_not_nil cookies['remember_token']
  end
  
  test "login without remembering" do
    log_in_as(@teacher_1, remember_me: '0')
    assert_nil cookies['remember_token']
  end
end
