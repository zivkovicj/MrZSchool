require 'test_helper'

class QuizzesAvailableTest < ActionDispatch::IntegrationTest

    def setup
        setup_users
        setup_schools
        setup_labels
        setup_seminars
        setup_objectives
        setup_questions
        setup_scores
        setup_goals
        
        @test_os = @objective_10.objective_students.find_by(:user => @student_2)
    end
    
    def begin_quiz(which_key)
        click_on("Quizzes")
        find("##{which_key}_#{@objective_10.id}").click
    end
    
    test "has no keys" do
        go_to_first_period
        click_on("Quizzes")
        
        assert_selector("h3", :text => "You have used all of your quiz keys")
        assert_no_selector("h2", :text => "Quizzes are Closed Right Now")
        assert_no_selector('a', :id => "teacher_granted_#{@objective_10.id}")
    end
    
    def try_quiz_twice(which_key)
        @test_os.update(:teacher_granted_keys => 0, :pretest_keys => 0, :dc_keys => 0)
        set_specific_score(@test_os.user, @test_os.objective, 0)
        
        @test_os.update(:"#{which_key}_keys" => 2)
        old_quiz_count = Quiz.count
        
        go_to_first_period
        begin_quiz(which_key)
        
        assert_text("Question: 1")
        
        answer_quiz_randomly
        click_on("Try this quiz again")
        
        assert_equal 0, @test_os.reload.read_attribute(:"#{which_key}_keys")
        @quiz = Quiz.last
        assert_equal which_key, @quiz.origin
        
        answer_quiz_randomly
        
        assert_equal old_quiz_count + 2, Quiz.count
        assert_no_text("Try this quiz again")
    end
    
    test "teacher keys" do
        # Capybara can find the key link named teacher keys
        
        travel_to_open_time
        make_ready(@student_2, @objective_10)
        try_quiz_twice("teacher_granted")
    end
    
    test "pretest keys" do
        travel_to_open_time
        make_ready(@student_2, @objective_10)
        try_quiz_twice("pretest")
    end
    
    test "quiz without questions" do
        travel_to_open_time
        @bad_objective = Objective.create(:name => "Bad Objective", :topic => Topic.first, :catchy_name => "Bad Objective")
        @bad_objective.objective_seminars.create(:seminar => @seminar, :pretest => 1)
        @bad_objective.objective_students.find_by(:user => @student_2).update(:teacher_granted_keys => 2)
        make_ready(@student_2, @bad_objective)
        
        go_to_first_period
        click_on("Quizzes")
        click_on(@bad_objective.catchy_name)
        
        assert_no_text("Question: 1")
    end
    
    test "quiz with questions" do
        travel_to_open_time
        make_ready(@student_2, @objective_10)
        @test_os.update(:teacher_granted_keys => 2)
        set_specific_score(@test_os.user, @test_os.objective, 4)
        set_specific_score(@student_2, @objective_10, 2)
        
        go_to_first_period
        begin_quiz("teacher_granted")
        
        assert_text("Question: 1")
    end
    
    test "unfinished quizzes" do
        travel_to_open_time
        
        @seminar.objective_seminars.update_all(:pretest => 0)
        make_ready(@student_2, @objective_10)
        @seminar.objective_seminars.find_by(:objective => @objective_10).update(:pretest => 1)
        @student_2.objective_students.find_by(:objective => @objective_10).update(:pretest_keys => 2)
        set_specific_score(@student_2, @objective_10, 0)
       
        go_to_first_period
        click_on("Quizzes")
        assert_no_text("Unfinished Quizzes")
        assert_text("Pretest Objectives")
        find("#pretest_#{@objective_10.id}").click
       
        3.times do |n|
            assert_text("Question: #{n+1}")
            choose("choice_bubble_1")
            click_on("Next Question")
        end
       
        logout
       
        go_to_first_period
        click_on("Quizzes")
        assert_text("Unfinished Quizzes")
        assert_no_text("Pretest Objectives")
        click_link("#{@objective_10.name}") # This time the first link should go to the unfinished quiz
        assert_text("Question: 4")                      # A little redundant with the next line, but this assertion is the most important one
       
        7.times do |n|
            assert_text("Question: #{n+4}")
            choose("choice_bubble_1")
            click_on("Next Question")
        end
       
       assert_text("Previous score this term")
    end
    
    test "not ready for pretest" do
        travel_to_open_time
        
        @test_os.update(:pretest_keys => 2)
        set_specific_score(@test_os.user, @objective_10, 2)
        assert @objective_20.preassigns.include?(@objective_10)
        main_assign_os = @objective_20.objective_students.find_by(:user => @student_2)
        main_assign_os.set_ready
        main_assign_os.update(:pretest_keys => 2)
        
        go_to_first_period
        click_on("Quizzes")
        
        assert_no_selector('a', :id => "pretest_#{@objective_20.id}")
    end

    test "not ready doesnt matter for nonpretest" do
        travel_to_open_time
        
        @test_os.update(:teacher_granted_keys => 2)
        set_specific_score(@test_os.user, @objective_10, 2)
        assert @objective_20.preassigns.include?(@objective_10)
        main_assign_os = @objective_20.objective_students.find_by(:user => @student_2)
        main_assign_os.set_ready
        main_assign_os.update(:teacher_granted_keys => 2)
        
        go_to_first_period
        click_on("Quizzes")
        
        assert_selector('a', :id => "teacher_granted_#{@objective_20.id}")
    end
    
    test "yes ready for pretest" do
        travel_to_open_time
        
        main_assign_os = @objective_20.objective_students.find_by(:user => @student_2)
        main_assign_os.update(:pretest_keys => 2)
        make_ready(@student_2, @objective_20)
        
        go_to_first_period
        click_on("Quizzes")
        
        assert_selector('a', :id => "pretest_#{@objective_20.id}")
    end



    test "lock in evening" do
        travel_to Time.zone.local(2019, 12, 07, 0, 15, 44)
        give_a_key
        
        go_to_first_period
        click_on("Quizzes")
        
        # Attempt quiz on Friday, but too late.
        # Quiz is not open.
        assert_equal "Friday", Date.today.strftime("%A")
        assert_equal "17:15", Time.now.strftime("%k:%M")
        
        assert_selector("h2", :text => "Quizzes are Closed Right Now")
        assert_no_selector("a", :id => "teacher_granted_#{@objective_10.id}")
    end

    test "dont lock in afternoon" do
        travel_to_open_time
        give_a_key
        
        go_to_first_period
        click_on("Quizzes")
        
        # Attempt quiz during open window.
        # Quiz is available.
        assert_equal "Friday", Date.today.strftime("%A")
        assert_equal "16:45", Time.now.strftime("%k:%M")
        
        assert_no_selector("h2", :text => "Quizzes are Closed Right Now")
        assert_selector("a", :id => "teacher_granted_#{@objective_10.id}")
    end

    test "lock on saturday" do
        travel_to Time.zone.local(2019, 12, 07, 23, 45, 44)
        give_a_key
        
        go_to_first_period
        click_on("Quizzes")
        
        # Try to take quiz early enough, but on Saturday.
        # Quiz is not open
        assert_equal "Saturday", Date.today.strftime("%A")
        assert_equal "16:45", Time.now.strftime("%k:%M")
        
        assert_selector("h2", :text => "Quizzes are Closed Right Now")
        assert_no_selector("a", :id => "teacher_granted_#{@objective_10.id}")
    end

    test "teacher override" do
        # Teacher allows student to quiz after hours
        travel_to Time.zone.local(2019, 12, 07, 0, 15, 44)
        give_a_key
        
        go_to_first_period
        click_on("Quizzes")
        
        fill_in "password", :with => "password"
        click_on("Enter")
        
        assert_no_selector("h2", :text => "Quizzes are Closed Right Now")
        assert_selector("a", :id => "teacher_granted_#{@objective_10.id}")
    end

    test "teacher override wrong password" do
        # Teacher allows student to quiz after hours
        travel_to Time.zone.local(2019, 12, 07, 0, 15, 44)
        give_a_key
        
        go_to_first_period
        click_on("Quizzes")
        
        fill_in "password", :with => "picklerick"
        click_on("Enter")
        
        assert_selector("h2", :text => "Quizzes are Closed Right Now")
        assert_no_selector("a", :id => "teacher_granted_#{@objective_10.id}")
    end
        
    
end
