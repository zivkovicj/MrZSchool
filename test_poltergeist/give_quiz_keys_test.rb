require 'test_helper'

class GiveQuizKeysTest < ActionDispatch::IntegrationTest
    
    def setup
        setup_users
        setup_seminars
        setup_objectives
    end
    
    test "give quiz keys" do
        poltergeist_stuff
        setup_scores
        
        @test_os = @objective_10.objective_students.find_by(:user => @student_2)
        @test_os.update(:teacher_granted_keys => 2, :points => 2)
        mainassign_os = @objective_20.objective_students.find_by(:user => @student_2)

        capybara_login(@teacher_1)
        click_on("scoresheet_#{@seminar.id}")
        click_on(@student_2.last_name_first)
        
        assert_no_selector('div', :id => "not_ready_#{@test_os.id}")
        assert_selector('div', :id => "not_ready_#{mainassign_os.id}")
        
        this_holder = ".key_holder_#{@test_os.id}"
        within(this_holder) do
            assert_selector('img', :count => 2) 
        end
    
        find(".add_key_2_#{@test_os.id}").click
        
        within(this_holder) do
            assert_selector('img', :count => 4) 
        end
        
        sleep(1)
        @test_os.reload
        assert_equal 4, @test_os.teacher_granted_keys
        
        find(".add_key_1_#{@test_os.id}").click
        
        within(this_holder) do
            assert_selector('img', :count => 5) 
        end
        
        sleep(1)
        @test_os.reload
        assert_equal 5, @test_os.teacher_granted_keys
        
        find(this_holder).click
        
        within(this_holder) do
            assert_selector('img', :count => 4) 
        end
        
        assert_selector('div', :count => 4)
        
        @test_os.reload
        assert_equal 4, @test_os.teacher_granted_keys
    end
    
end