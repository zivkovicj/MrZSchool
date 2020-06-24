require 'test_helper'

class SeminarTest < ActiveSupport::TestCase

  def setup
    setup_users
    @test_seminar = @teacher_1.seminars.create(:name => "1st Period")
  end

  test "should be valid" do
    assert @test_seminar.valid?
  end
  
  test "name should be present" do
    @test_seminar.name = "   "
    assert_not @test_seminar.valid?
  end

  test "name should be less than 40 characters" do
    @test_seminar.name = "a" * 41
    assert_not @test_seminar.valid?
  end
  
  test "obj studs for seminar" do
    setup_objectives
    setup_seminars
    
    other_seminar_objective = Objective.all.detect{|x| @seminar.objectives.include?(x) == false}
    assert_not_nil other_seminar_objective
    other_seminar_student = Student.all.detect{|x| @seminar.students.include?(x) == false}
    assert_not_nil other_seminar_student
    
    correct_obj_stud = @student_2.objective_students.find_or_create_by(:objective => @objective_10)
    wrong_1 = other_seminar_student.objective_students.find_or_create_by(:objective => @objective_10)
    wrong_2 = other_seminar_objective.objective_students.find_or_create_by(:user => @student_2)
    
    these_obj_studs = @seminar.obj_studs_for_seminar
    assert these_obj_studs.include?(correct_obj_stud)
    assert_not these_obj_studs.include?(wrong_1)
    assert_not these_obj_studs.include?(wrong_2)
    
  end
  
  
  
end
