require 'test_helper'

class ObjectivesControllerTest < ActionDispatch::IntegrationTest
  
  def setup
    setup_users
    setup_schools
    setup_seminars
    setup_objectives()
    setup_scores()

  end

  test "objectives index test" do
    log_in_as(@teacher_1)
    get objectives_path
    assert_template 'objectives/index'
  end
  
  test "objectives index as non-admin" do
    log_in_as(@teacher_1)
    get objectives_path
    # Should test that admin gets delete links for publics
    # Non-admin doesn't get those links.
  end
  
  test "edit with permission"do
    log_in_as(@objective_20.user)
    
    patch objective_path(@objective_20), params: { objective: { name:  "Burgersauce",
                                          seminar_id: @seminar.id } }
                                          
    @objective_20.reload
    assert_equal "Burgersauce", @objective_20.name
  end
  
  test "edit as non admin" do
    old_name = @objective_20.name
    
    log_in_as(@teacher_1)
    patch objective_path(@objective_20), params: { objective: { name:  "Burgersauce",
                                          seminar_id: @seminar.id } }
                                          
    @objective_20.reload
    assert_equal old_name, @objective_20.name
  end
  
  test "edit without login" do
    old_name = @objective_20.name
    
    log_in_as(@teacher_1)
    patch objective_path(@objective_20), params: { objective: { name:  "Burgersauce",
                                          seminar_id: @seminar.id } }
                                          
    @objective_20.reload
    assert_equal old_name, @objective_20.name
  end

  test "wrong user can't delete" do
    log_in_as @other_teacher
    assert_no_difference 'Objective.count' do
      delete objective_path(@objective_40)
    end
  end
  

end
