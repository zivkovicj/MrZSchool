require 'test_helper'

class StudentTest < ActiveSupport::TestCase
  def setup
    @student = Student.new(first_name: "Beef", last_name: "Stroganoff", 
          email: "user@example.com", 
          password: "foobar", password_confirmation: "foobar")
  end
  
  test "should be valid" do
    assert @student.valid?
  end
  
  test "first name should be present" do
    @student.first_name = "    "
    assert_not @student.valid?
  end
  
  test "last name should be present" do
    @student.last_name = "    "
    assert_not @student.valid?
  end
  
  test "first name should not be too long" do
    @student.first_name = "a" * 26
    assert_not @student.valid?
  end
  
  test "last name should not be too long" do
    @student.last_name = "a" * 26
    assert_not @student.valid?
  end

  test "email should not be too long" do
    @student.email = "a" * 244 + "@example.com"
    assert_not @student.valid?
  end
  
  test "email validation should accept valid addresses" do
    valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
                         first.last@foo.jp alice+bob@baz.cn]
    valid_addresses.each do |valid_address|
      @student.email = valid_address
      assert @student.valid?, "#{valid_address.inspect} should be valid"
    end
  end
    
  test "email validation should reject invalid addresses" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
                           foo@bar_baz.com foo@bar+baz.com]
    invalid_addresses.each do |invalid_address|
      @student.email = invalid_address
      assert_not @student.valid?, "#{invalid_address.inspect} should be invalid"
    end
  end

  test "email addresses should be unique" do
    duplicate_user = @student.dup
    duplicate_user.email = @student.email.upcase
    @student.save
    assert_not duplicate_user.valid?
  end
  
  test "uniqueness against a teacher" do
    @teacher = Teacher.first
    @student.email = @teacher.email
    assert_not @student.valid?
  end
  
  test "authenticated? should return false for a user with nil digest" do
    assert_not @student.authenticated?(:remember, '')
  end
  
  test "advance to next school year" do
    setup_users
    setup_seminars
    setup_scores
    
    @this_obj_stud = @student_2.objective_students.first
    @student_2.update(:school_year => 2)
    
    @student_2.advance_to_next_school_year
    
    @student_2.reload
    @this_obj_stud.reload
    assert_equal 3, @student_2.school_year
  end
  

end
