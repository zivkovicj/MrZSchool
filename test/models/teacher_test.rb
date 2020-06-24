require 'test_helper'

class TeacherTest < ActiveSupport::TestCase
  def setup
    @teacher = Teacher.new(first_name: "Beef", last_name: "Stroganoff", 
          email: "user@example.com", 
          password: "foobar", password_confirmation: "foobar")
  end
  
  
  
  test "should be valid" do
    assert @teacher.valid?
  end
  
  test "first name should be present" do
    @teacher.first_name = "    "
    assert_not @teacher.valid?
  end
  
  test "last name should be present" do
    @teacher.last_name = "    "
    assert_not @teacher.valid?
  end
  
  test "email should be present" do
    @teacher.email = "     "
    assert_not @teacher.valid?
  end
  
  test "first name should not be too long" do
    @teacher.first_name = "a" * 26
    assert_not @teacher.valid?
  end
  
  test "last name should not be too long" do
    @teacher.last_name = "a" * 26
    assert_not @teacher.valid?
  end

  test "email should not be too long" do
    @teacher.email = "a" * 244 + "@example.com"
    assert_not @teacher.valid?
  end
  
  test "email validation should accept valid addresses" do
    valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
                         first.last@foo.jp alice+bob@baz.cn]
    valid_addresses.each do |valid_address|
      @teacher.email = valid_address
      assert @teacher.valid?, "#{valid_address.inspect} should be valid"
    end
  end
    
  test "email validation should reject invalid addresses" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
                           foo@bar_baz.com foo@bar+baz.com]
    invalid_addresses.each do |invalid_address|
      @teacher.email = invalid_address
      assert_not @teacher.valid?, "#{invalid_address.inspect} should be invalid"
    end
  end

  test "email addresses should be unique" do
    duplicate_user = @teacher.dup
    duplicate_user.email = @teacher.email.upcase
    @teacher.save
    assert_not duplicate_user.valid?
  end
  
  test "password should be present (nonblank)" do
    @teacher.password = @teacher.password_confirmation = " " * 6
    assert_not @teacher.valid?
  end

  test "password should have a minimum length" do
    @teacher.password = @teacher.password_confirmation = "a" * 5
    assert_not @teacher.valid?
  end
  
  test "authenticated? should return false for a user with nil digest" do
    assert_not @teacher.authenticated?(:remember, '')
  end
  
  test "associated seminars should be destroyed" do
    @teacher.save
    @teacher.seminars.create(name: "1st period")
    assert_difference 'Seminar.count', -1 do
      @teacher.destroy
    end
  end
  
  test "seminars I can edit" do
    setup_users
    setup_seminars
    
    sem_teach_1 = SeminarTeacher.where(:user => @teacher_1, :seminar => @seminar)
    sem_teach_2 = SeminarTeacher.where(:user => @teacher_1, :seminar => @seminar_2)
    sem_teach_1.update(:can_edit => true)
    sem_teach_2.update(:can_edit => false)
    
    these_sems = @teacher_1.seminars_i_can_edit
    assert these_sems.include?(@seminar)
    assert_not these_sems.include?(@seminar_2)
  end
  
end
