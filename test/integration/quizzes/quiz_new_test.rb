require 'test_helper'

class NewQuizTest < ActionDispatch::IntegrationTest
    
    def setup
        setup_users
        setup_schools
        setup_seminars
        setup_labels
        setup_objectives
        setup_questions
        setup_scores
        
        give_a_key
        travel_to_open_time
    end
    
    def begin_quiz
        click_on("Quizzes")
        find("#teacher_granted_#{@objective_10.id}").click
    end

    def answer_question_correctly
        this_id = current_path[/\d+/].to_i
        @riposte = Riposte.find(this_id)
        @question = @riposte.question
        correct_answer = @question.correct_answers.first
        choose("choice_bubble_#{correct_answer}")
    end
    
    def answer_question_incorrectly
        this_id = current_path[/\d+/].to_i
        @riposte = Riposte.find(this_id)
        @question = @riposte.question
        incorrect_answer = (@question.correct_answers.first.to_i) + 1
        choose("choice_bubble_#{incorrect_answer}")
    end
    
    def assert_all_ripostes_graded
        # Ripostes have been marked as graded
        @quiz.ripostes.each do |riposte|
            assert_equal 1, riposte.graded
        end
    end
    
    def create_ripostes_for(quiz)
        3.times do |trip|
            quiz.ripostes.create(:question => Question.all[trip])
        end
    end
    
    def prepare_fill_in
        @fill_in_objective = Objective.find_by(:name => "fill_in Questions Only")
        set_specific_score(@student_2, @fill_in_objective, 4)
        @fill_in_objective.objective_students.find_by(:user => @student_2).update(:teacher_granted_keys => 2)
    end
    
    def prepare_select_many
        @sm_objective = objectives(:select_many_objective)
        set_specific_score(@student_2, @sm_objective, 4)
        @sm_objective.objective_students.find_by(:user => @student_2).update(:teacher_granted_keys => 2)
        @seminar.objectives << @sm_objective
    end
    
    test "setup quiz" do
        current_term = @seminar.term
        term_start_date = Date.strptime(@school.term_dates[current_term][0], "%m/%d/%Y")
        new_quiz = @student_2.quizzes.create(:objective => @objective_10, :origin => "teacher_granted", :total_score => 2, :updated_at => term_start_date + 2.days)
        create_ripostes_for(new_quiz)
        old_quiz_count = Quiz.count
        old_riposte_count = Riposte.count
        
        go_to_first_period
        begin_quiz
        @quiz = Quiz.last
        assert_equal @quiz.user, @student_2
        assert_equal @quiz.objective, @objective_10
        assert_equal old_quiz_count + 1, Quiz.count
        assert @quiz.old_stars >= 2
        
        new_riposte_count = @quiz.ripostes.count
        assert new_riposte_count > 0
        assert_equal old_riposte_count + new_riposte_count, Riposte.count
        # Ripostes should be created with the "graded" value set to nil
        last_riposte = @quiz.ripostes.last
        assert_equal @student_2, last_riposte.user
        assert_nil last_riposte.graded
    end
    
    test "blank mc" do
        go_to_first_period
        begin_quiz
        
        @quiz = Quiz.last
        @riposte = @quiz.ripostes[0]
        assert_equal 1, @quiz.progress
        
        click_on "Next Question"
        
        assert_text "Question: 2"
        
        @riposte.reload
        assert_equal 0, @riposte.tally
        assert_equal ["blank"], @riposte.stud_answer
        assert_nil @riposte.graded      # Riposte graded should be set back to nil with a blank answer
    end
    
    test "fill in answer left blank" do
        prepare_fill_in
        setup_labels
    
        go_to_first_period
        
        click_on("Quizzes")
        find("#teacher_granted_#{@fill_in_objective.id}").click
        
        @quiz = Quiz.last
        @riposte = @quiz.ripostes[0]
        
        # Skip entering an answer
        click_on "Next Question"
        
        @riposte.reload
        assert_equal 0, @riposte.tally
        assert_equal ["blank"], @riposte.stud_answer
        assert_nil @riposte.graded      # Riposte graded should be set back to nil with a blank answer
        
        quest_count = @quiz.ripostes.count - 1
        quest_count.times do
            fill_in "riposte[stud_answer]", with: "ofcourse"
            click_on "Next Question"
        end
        submit_quiz
        
        @quiz.reload
        assert_equal 9, @quiz.total_score
        assert @quiz.points_still_to_grade == 0
        assert_not @seminar.reload.grading_needed
    end
    
    test "take multiple choice quiz" do
        setup_consultancies
        go_to_first_period
        begin_quiz
        
        # General stuff to check for across different quiz types
        # This next line also needs to be replaced soon.
        assert_no_text("Your Scores in All Objectives")
        @quiz = Quiz.last
        assert @quiz.ripostes.count > 0
        assert_nil @quiz.total_score
        
        # Take this quiz randomly
        @quiz.ripostes.each do |riposte|
            assert riposte.tally.blank?
            assert_nil riposte.tally
        end
        answer_quiz_randomly
        
        assert_no_selector("h4", :text => "Correct Responses")
        assert_no_selector("p",:text => "Some correct answers left out")
        
        submit_quiz
        
        assert_selector("h4", :text => "Correct Responses")
        
        # Replace this with the new line that checks to see if a student is on her profile page
        # assert_text("Your Scores in All Objectives")
        @quiz.reload
        assert_equal 0, @quiz.points_still_to_grade   # Counterpart to the quiz that has teacher-graded questions
        assert_not_nil @quiz.total_score
        @quiz.ripostes.each do |riposte|
            assert_not_nil riposte.tally
        end
        assert @student_2.quizzes.include?(@quiz)
        
        assert_all_ripostes_graded
        assert_not @seminar.reload.grading_needed   #Counterpart to the quiz that has teacher-graded questions
    end
    
    test "take select many quiz" do
        prepare_select_many
        
        go_to_first_period
        click_on("Quizzes")
        find("#teacher_granted_#{@sm_objective.id}").click
        
        # Choose two of three correct answers, and add one wrong choice
        check("check_box_0")
        check("check_box_1")
        check("check_box_2")
        click_on "Next Question"
        submit_quiz
        
        @quiz = Quiz.last
        assert_equal 7, @quiz.total_score
        assert_equal 0, @quiz.points_still_to_grade
        assert_all_ripostes_graded
        
        riposte = @quiz.ripostes.first
        assert_equal 67, riposte.tally
        assert riposte.stud_answer.include?("0")
        assert riposte.stud_answer.include?("1")
        assert riposte.stud_answer.include?("2")
        assert_not riposte.stud_answer.include?("3")
        
        assert_selector("p",:text => "Some correct answers left out")
    end

    test "select many all correct" do
        prepare_select_many
        
        go_to_first_period
        click_on("Quizzes")
        find("#teacher_granted_#{@sm_objective.id}").click
        
        # Choose all correct answers
        check("check_box_0")
        check("check_box_2")
        check("check_box_3")
        click_on "Next Question"
        submit_quiz
        
        @quiz = Quiz.last
        assert_equal 10, @quiz.total_score
        assert_equal 0, @quiz.points_still_to_grade
        assert_all_ripostes_graded
        
        riposte = @quiz.ripostes.first
        assert_equal 100, riposte.tally
        
        assert_no_selector("p",:text => "Some correct answers left out")
    end
    
    test "take fill in quiz" do
        prepare_fill_in
        
        go_to_first_period
        
        click_on("Quizzes")
        find("#teacher_granted_#{@fill_in_objective.id}").click
        @quiz = Quiz.last
        fill_in "riposte[stud_answer]", with: "Yes"
        click_on "Next Question"
        @quiz.reload
        assert_equal 2, @quiz.progress
        fill_in "riposte[stud_answer]", with: "No"
        click_on "Next Question"
        fill_in "riposte[stud_answer]", with: "yes"
        click_on "Next Question"
        fill_in "riposte[stud_answer]", with: "yes!"
        click_on "Next Question"
        fill_in "riposte[stud_answer]", with: "ofcourse"
        click_on "Next Question"
        fill_in "riposte[stud_answer]", with: "ofco urse"
        click_on "Next Question"
        @quiz.reload
        assert_equal 7, @quiz.progress
        fill_in "riposte[stud_answer]", with: "course of"
        click_on "Next Question"
        submit_quiz
        
        assert_no_selector("p",:text => "Some correct answers left out")
        
        @quiz.reload
        assert_equal 6, @quiz.total_score
        assert @student_2.quizzes.include?(@quiz)
        assert_all_ripostes_graded
        assert_not @seminar.reload.grading_needed
        assert_no_selector("h3", :text => "Your teacher will grade this question.")  #Counterpart to teacher-graded questions.
    end

    test "take interval quiz" do
        interval_objective = objectives(:interval_objective)
        set_specific_score(@student_2, interval_objective, 4)
        interval_objective.objective_students.find_by(:user => @student_2).update(:teacher_granted_keys => 2)
        @seminar.objectives << interval_objective
        
        go_to_first_period
        
        click_on("Quizzes")
        find("#teacher_granted_#{interval_objective.id}").click
        
        # Answer the first question correct, but the second question wrong.
        fill_in "riposte[stud_answer]", with: 3.14
        click_on "Next Question"
        fill_in "riposte[stud_answer]", with: 5.1
        click_on "Next Question"
        
        assert_no_selector("p",:text => "Some correct answers left out")
        
        @quiz = Quiz.last
        assert_equal 0, @quiz.points_still_to_grade
        assert_all_ripostes_graded
        
        riposte_1 = @quiz.ripostes.first
        riposte_2 = @quiz.ripostes.second
        assert_equal 2, riposte_1.tally
        assert_equal 0, riposte_2.tally
    end

    test "interval with infinity" do
        interval_objective = objectives(:interval_objective)
        set_specific_score(@student_2, interval_objective, 4)
        interval_objective.objective_students.find_by(:user => @student_2).update(:teacher_granted_keys => 2)
        @seminar.objectives << interval_objective
        
        interval_label = labels(:interval_label)
        q_1 = interval_label.questions.first
        q_2 = interval_label.questions.second
        a = Float::INFINITY
        b = -1*a
        q_1.update(:correct_answers => [9, a])
        q_2.update(:correct_answers => [b, 9])
        
        go_to_first_period
        
        click_on("Quizzes")
        find("#teacher_granted_#{interval_objective.id}").click
        
        # Answer the first question wrong, but the second question correct.
        fill_in "riposte[stud_answer]", with: 3.14
        click_on "Next Question"
        fill_in "riposte[stud_answer]", with: 3.14
        click_on "Next Question"
        submit_quiz
        
        @quiz = Quiz.last
        assert_equal 0, @quiz.points_still_to_grade
        assert_all_ripostes_graded
        
        riposte_1 = @quiz.ripostes.first
        riposte_2 = @quiz.ripostes.second
        assert_equal 2, riposte_1.tally
        assert_equal 0, riposte_2.tally
    end


    test "quiz with teacher graded question" do
        @tg_objective_1 = objectives(:teacher_graded_objective_1)
        @tg_objective_2 = objectives(:teacher_graded_objective_2)
        @seminar.objectives << @tg_objective_1
        @seminar.objectives << @tg_objective_2
        
        #Give keys for the quizzes that students are about to take.
        # Student_2 gets keys for two different quizzes.  Student_3 only needs keys for the first quiz.
        ObjectiveStudent.find_by(:objective => @tg_objective_1, :user => @student_2).update(:teacher_granted_keys => 2)
        ObjectiveStudent.find_by(:objective => @tg_objective_2, :user => @student_2).update(:teacher_granted_keys => 2)
        obj_stud_2_1 = ObjectiveStudent.find_by(:objective => @tg_objective_1, :user => @student_3)
        obj_stud_2_1.update(:teacher_granted_keys => 2)
        
        # TEACHER DOESN'T HAVE ANY QUESTIONS TO GRADE RIGHT NOW
        assert_not @seminar.grading_needed
        
        capybara_login(@teacher_1)
        find("#quiz_grading_seminar_#{@seminar.id}").click
        assert_text("All quizzes in this class are fully graded.")
        
        logout

        ###  FIRST STUDENT TAKES QUIZ FOR OBJECTIVE 1
        go_to_first_period
        click_on("Quizzes")
        find("#teacher_granted_#{@tg_objective_1.id}").click
        @quiz_1_0 = Quiz.last
        one_wrong = false

        @quiz_1_0.ripostes.count.times do
            teacher_graded_tags = all('#teacher_graded_tag')
            if teacher_graded_tags.present?
                fill_in "riposte[stud_answer]", with: "Yesiree Bob"
            else
                # Answer one question wrong,
                # for testing out the display of the possible scores
                if !one_wrong
                    answer_question_incorrectly
                    one_wrong = true
                else
                    answer_question_correctly
                end
            end
            click_on "Next Question"
        end
        submit_quiz
        
        new_time = @quiz_1_0.created_at - 1.hour
        @quiz_1_0.update(:created_at => new_time) # This fixes an error that the test caused by creating all of the quizzes at the exact same time.
        @quiz_1_0.reload
        quiz_1_ripostes = @quiz_1_0.ripostes.select{|x| x.question.label.grade_type == "teacher"}
        riposte_0 = quiz_1_ripostes[0]
        riposte_1 = quiz_1_ripostes[1]
        assert @quiz_1_0.points_still_to_grade > 0
        assert_equal 5, @quiz_1_0.total_score
        assert_equal ["Yesiree Bob"], riposte_0.stud_answer
        assert @quiz_1_0.needs_grading
        assert @seminar.reload.grading_needed
        
        assert_selector('h3', :text => "Your final score will be at least 5 stars.")
        assert_selector('h3', :text => "The highest you could earn is 9 stars.")
        assert_selector("h4", :text => "Your teacher will grade this question.")
        assert_selector("h4", :text => "We will show a sample answer after you use your last key for this quiz.")
        assert_no_selector("li", :text => "A sample answer to show")
        assert_text("Yesiree Bob")
        
        ###  FIRST STUDENT TRIES OBJECTIVE 1 QUIZ A SECOND TIME
        
        click_on("Back to Your Class Page")
        click_on("Quizzes")
        find("#teacher_granted_#{@tg_objective_1.id}").click
        @quiz_1_1 = Quiz.last
        assert_equal @quiz_1_0.ripostes.count, @quiz_1_1.ripostes.count
        
        # On the second try, include the already-answered riposte
        assert @quiz_1_1.ripostes.include?(riposte_0)
        assert @quiz_1_1.ripostes.include?(riposte_1)
        
        @quiz_1_1.ripostes.count.times do
            teacher_graded_tags = all('#teacher_graded_tag')
            answer_question_correctly if !teacher_graded_tags.present?
            click_on "Next Question"
        end
        submit_quiz
        
        @quiz_1_1.reload
        riposte_0.reload
        riposte_1.reload
        assert_equal ["Yesiree Bob"], riposte_0.stud_answer
        
        assert_no_selector("h4", :text => "We will show a sample answer after you use your last key for this quiz.")
        assert_selector("li", :text => "A sample answer to show")

        ###  FIRST STUDENT TAKES QUIZ FOR OBJECTIVE 2
        click_on("Back to Your Class Page")
        click_on("Quizzes")
        find("#teacher_granted_#{@tg_objective_2.id}").click
        @quiz_2 = Quiz.last
        2.times do 
            fill_in "riposte[stud_answer]", with: "Yes"
            click_on "Next Question"
        end
        submit_quiz
        
        assert_equal 0, @quiz_2.reload.total_score
        
        logout
        
        # SECOND STUDENT TAKES QUIZ FOR OBJECTIVE 1
        # Scores 100% on computer-graded questions, which takes the second key.
        capybara_login(@student_3)
        click_on('1st Period')
        click_on("Quizzes")
        find("#teacher_granted_#{@tg_objective_1.id}").click
        @quiz_3 = Quiz.last
        @quiz_3.ripostes.count.times do
            teacher_graded_tags = all('#teacher_graded_tag')
            if teacher_graded_tags.present?
                fill_in "riposte[stud_answer]", with: "Yes"
            else
                answer_question_correctly
            end
            click_on "Next Question"
        end
        submit_quiz
        
        assert_equal 6, @quiz_3.reload.total_score
        assert_equal 0, obj_stud_2_1.reload.teacher_granted_keys
        
        logout
        
        # TEACHER GRADES THOSE QUESTIONS
        capybara_login(@teacher_1)
        assert_no_selector("span", :id => "fully_graded_#{@seminar.id}")
        find("#quiz_grading_seminar_#{@seminar.id}").click
        assert_no_text("All quizzes in this class are fully graded.")
        
        quiz_2_ripostes = @quiz_2.ripostes.select{|x| x.question.label.grade_type == "teacher"}
        riposte_2 = quiz_2_ripostes[0]
        riposte_3 = quiz_2_ripostes[1]
        quiz_3_ripostes = @quiz_3.ripostes.select{|x| x.question.label.grade_type == "teacher"}
        riposte_4 = quiz_3_ripostes[0]
        riposte_5 = quiz_3_ripostes[1]
        
        assert_equal 0, riposte_0.graded
        assert_equal 0, riposte_2.graded
        [@quiz_1_0, @quiz_1_1,@quiz_2,@quiz_3].each do |this_quiz|
            assert this_quiz.needs_grading
        end
        
        # Need to bring this one back after I fix the teacher view.
        fill_in "score_for_#{riposte_0.id}", with: 0
        fill_in "score_for_#{riposte_1.id}", with: 10
        # Score_2 left blank for testing
        # This question should still be marked ungraded.
        fill_in "score_for_#{riposte_3.id}", with: 10
        fill_in "score_for_#{riposte_4.id}", with: 5
        fill_in "score_for_#{riposte_5.id}", with: 10
        click_on("Submit These Scores")
        
        assert_equal 1, riposte_0.reload.graded  # Should be marked graded now
        assert_equal 1, riposte_1.reload.graded
        assert_equal 0, riposte_2.reload.graded  # Still not graded
        assert_equal 7, @quiz_1_0.reload.total_score
        assert_equal 8, @quiz_1_1.reload.total_score
        assert_equal 5, @quiz_2.reload.total_score
        assert_equal 9, @quiz_3.reload.total_score
        assert_not @quiz_1_0.needs_grading
        assert_not @quiz_1_1.needs_grading
        assert @quiz_2.needs_grading
        assert_not @quiz_3.needs_grading
        assert @seminar.reload.grading_needed
        
        # Go back and grade that last quiz.
        assert_text("Teacher Since:")
        assert_no_selector("span", :id => "fully_graded_#{@seminar.id}")
        find("#quiz_grading_seminar_#{@seminar.id}").click
        
        fill_in "score_for_#{riposte_2.id}", with: 5
        click_on("Submit These Scores")
        
        assert_equal 8, @quiz_2.reload.total_score
        assert_not @seminar.reload.grading_needed
        
        assert_text("Teacher Since:")
        find("#quiz_grading_seminar_#{@seminar.id}").click
        assert_text("All quizzes in this class are fully graded.")
    end

    test "jump to mc" do
        setup_consultancies
        go_to_first_period
        begin_quiz
        
        # Take this quiz mostly randomly
        @quiz = Quiz.last
        riposte_1 = @quiz.ripostes.order(:position).first
        riposte_2 = @quiz.ripostes.order(:position).second
        
        # No "Finish Quiz" button on the first time through
        assert_no_selector("a", :text => "Finish Quiz")
        
        # Get first question right
        answer_question_correctly
        click_on("Next Question")
        
        # Get second question wrong
        answer_question_incorrectly
        click_on("Next Question")
        
        # Answer rest of quiz randomly.
        8.times do
            assert_no_selector("input", :id => "finish_quiz")
            choose("choice_bubble_1")
            click_on("Next Question")
        end
        
        # First question right, second wrong
        assert_equal 1, riposte_1.reload.tally
        assert_equal 0, riposte_2.reload.tally
        assert_selector("a", :text => "Submit for grading")
        
        # Jump back to first question.
        click_on("jump_to_#{riposte_1.id}")
        assert_text(riposte_1.question.prompt)
        click_on("Next Question")
        
        # First Answer is still correct (Earlier answer was auto-filled)
        assert_equal 1, riposte_1.reload.tally
        
        assert_text(riposte_2.question.prompt)
        assert_no_text(riposte_1.question.prompt)
        
        answer_question_correctly
        assert_selector("input", :id => "finish_quiz")
        click_on("Finish Quiz")
        
        # Second question is answered correctly now.
        assert_equal 1, riposte_2.reload.tally
        assert_selector("a", :text => "Submit for grading")
    end

    test "jump to select many" do
        prepare_select_many
        
        go_to_first_period
        click_on("Quizzes")
        find("#teacher_granted_#{@sm_objective.id}").click
        
        @quiz = Quiz.last
        riposte_1 = @quiz.ripostes.order(:position).first
        
        # Choose two of three correct answers, and add one wrong choice
        check("check_box_0")
        check("check_box_1")
        check("check_box_2")
        click_on "Next Question"
        
        riposte_1.reload
        assert riposte_1.stud_answer.include?("0")
        assert riposte_1.stud_answer.include?("1")
        assert riposte_1.stud_answer.include?("2")
        assert_equal 3, riposte_1.stud_answer.length
        
        # Jump back to question.  # Answer was pre-filled
        click_on("jump_to_#{riposte_1.id}")
        click_on("Next Question")
        riposte_1.reload
        assert riposte_1.stud_answer.include?("0")
        assert riposte_1.stud_answer.include?("1")
        assert riposte_1.stud_answer.include?("2")
        assert_equal 3, riposte_1.stud_answer.length
        
        # Jump again and change
        click_on("jump_to_#{riposte_1.id}")
        uncheck("check_box_2")
        click_on("Next Question")
        riposte_1.reload
        assert riposte_1.stud_answer.include?("0")
        assert riposte_1.stud_answer.include?("1")
        assert_equal 2, riposte_1.stud_answer.length
        
    end
    
    test "take keys for 100 percent" do
        # Counterpart is that the program does NOT take keys if student scores less.
        # That test is in "improving points"
        @test_obj_stud.update(:dc_keys => 2)
        setup_consultancies
        
        go_to_first_period
        begin_quiz
        
        10.times do
            answer_question_correctly
            click_on("Next Question")
        end
        submit_quiz
        
        @quiz = Quiz.last
        assert_equal 10, @quiz.total_score
        @test_obj_stud.reload
        assert_equal 0, @test_obj_stud.teacher_granted_keys
        assert_equal 0, @test_obj_stud.dc_keys
    end
    
    test "improving points" do
        @test_obj_stud.update(:points_all_time => 1, :points_this_term => 1, :teacher_granted_keys => 2)
        set_specific_score(@test_obj_stud.user, @test_obj_stud.objective, 1)
       
        # Set up old_stud_need_count
        # This is to check that students_needed is updated upon passing a quiz       
        this_obj_sem = ObjectiveSeminar.find_by(:seminar => @seminar, :objective => @objective_10)
        this_obj_sem.students_needed_refresh
        old_stud_need_count = this_obj_sem.students_needed
        assert old_stud_need_count > 0
        
        # First try on quiz student scores 3 stars. An improvement of 2 stars.
        go_to_first_period
        begin_quiz
        3.times do
            answer_question_correctly
            click_on("Next Question")
        end
        7.times do
            answer_question_incorrectly
            click_on("Next Question")
        end
        submit_quiz
        
        @test_obj_stud.reload
        assert_equal 3, @test_obj_stud.points_all_time
        assert_equal 3, @test_obj_stud.points_this_term
        assert_equal 1, @test_obj_stud.teacher_granted_keys
        assert_nil @test_obj_stud.pretest_score
        assert_equal old_stud_need_count, this_obj_sem.students_needed
        
        # Second try on quiz student scores 8 stars. An improvement of 5 stars.
        click_on("Try this quiz again")
        9.times do
            answer_question_correctly
            click_on("Next Question")
        end
        1.times do
            answer_question_incorrectly
            click_on("Next Question")
        end
        submit_quiz
        
        @test_obj_stud.reload
        assert_equal 9, @test_obj_stud.points_all_time
        assert_equal 9, @test_obj_stud.points_this_term
        assert_equal old_stud_need_count - 1, this_obj_sem.reload.students_needed
    end
    
    test "quizzed better last term" do
        # Student takes a quiz, but does worse than he did in a previous term.  The points_all_time does not lower.  Points_this_term receives the new value.
        new_quiz = Quiz.create(:user => @student_2, :objective => @objective_10, :origin => "teacher_granted", :total_score => 8)
        create_ripostes_for(new_quiz)
        @test_obj_stud.update(:teacher_granted_keys => 2, :points_this_term => nil, :points_all_time => 8)
        
        go_to_first_period
        begin_quiz
        5.times do
            answer_question_correctly
            click_on("Next Question")
        end
        5.times do
            answer_question_incorrectly
            click_on("Next Question")
        end
        submit_quiz
        
        @test_obj_stud.reload
        assert_equal 8, @test_obj_stud.points_all_time
        assert_equal 5, @test_obj_stud.points_this_term
    end
    
    test "quizzed better this term" do
        # Counterpart to "quizzed_better_last_term".  Student improves a score from a previous term.  The new score affects both "points_all_time" and "points_this_term"
        set_specific_score(@student_2, @objective_10, 8)
        @test_obj_stud.update(:teacher_granted_keys => 2, :points_all_time => 8, :points_this_term => 8)
        new_quiz = @student_2.quizzes.create(:objective => @objective_10, :total_score => 8, :origin => "teacher_granted")
        create_ripostes_for(new_quiz)
        
        go_to_first_period
        begin_quiz
        5.times do
            answer_question_correctly
            click_on("Next Question")
        end
        5.times do
            answer_question_incorrectly
            click_on("Next Question")
        end
        
        @test_obj_stud.reload
        assert_equal 8, @test_obj_stud.points_all_time
        assert_equal 8, @test_obj_stud.points_this_term
    end
    
    test "pretest" do
        @test_obj_stud.update(:teacher_granted_keys => 0, :pretest_keys => 2, :points_all_time => nil, :points_this_term => nil)
        @first_mainassign = @objective_10.mainassigns.first
        @mainassign_os = @student_2.objective_students.find_by(:objective => @first_mainassign)
        @mainassign_os.update(:teacher_granted_keys => 0, :pretest_keys => 2, :points_all_time => nil, :points_this_term => nil)
        
        go_to_first_period
        click_on("Quizzes")
        find("#pretest_#{@objective_10.id}").click
        
        # 1 times do
        answer_question_correctly
        click_on("Next Question")

        9.times do
            answer_question_incorrectly
            click_on("Next Question")
        end
        submit_quiz
        
        # Doesn't take the keys yet, because student still has another try
        @test_obj_stud.reload
        
        assert_equal 1, @test_obj_stud.pretest_keys
        assert_equal 1, @test_obj_stud.pretest_score
        assert_equal 1, @test_obj_stud.points_all_time
        assert_nil @test_obj_stud.points_this_term
        assert_equal 2, @mainassign_os.reload.pretest_keys  
        
        click_on("Try this quiz again")
        3.times do
            answer_question_correctly
            click_on("Next Question")
        end
        7.times do
            answer_question_incorrectly
            click_on("Next Question")
        end
        submit_quiz
        
        # Now it takes the pretest keys for the post-requisites to spare the student the struggle of taking a pre-test that she is doomed to fail.
        @test_obj_stud.reload
        assert_equal 0, @test_obj_stud.pretest_keys
        assert_equal 3, @test_obj_stud.pretest_score
        assert_equal 3, @test_obj_stud.points_all_time
        assert_nil      @test_obj_stud.points_this_term
        assert_equal 0, @mainassign_os.reload.pretest_keys   
    end

    test "previous question" do
        @test_obj_stud.update(:dc_keys => 2)
        setup_consultancies
        
        go_to_first_period
        begin_quiz
        
        this_id = current_path[/\d+/].to_i
        this_riposte = Riposte.find(this_id)
        assert_equal 1, this_riposte.position
        answer_question_correctly
        assert_no_selector("input", :id => "previous_question")
        click_on("Next Question")
        
        this_id = current_path[/\d+/].to_i
        this_riposte = Riposte.find(this_id)
        assert_equal 2, this_riposte.position
        answer_question_correctly
        assert_selector("input", :id => "previous_question")
        click_on("Previous Question")
        
        this_id = current_path[/\d+/].to_i
        this_riposte = Riposte.find(this_id)
        assert_equal 1, this_riposte.position
        
        @quiz = Quiz.last
        riposte_1 = @quiz.ripostes.order(:position).first
        riposte_2 = @quiz.ripostes.order(:position).second
        assert_equal 1, riposte_1.tally
        assert_equal 1, riposte_2.tally
    end
    
    test "set ready upon passing" do
        other_preassign = Objective.create(:name => "Other Preassign")
        mainassign_1 = Objective.create(:name => "Mainassign 1")
        mainassign_2 = Objective.create(:name => "Mainassign 2")
       
        mainassign_1.preassigns << @objective_10
        mainassign_2.preassigns << @objective_10
        mainassign_2.preassigns << other_preassign
        os_1 = ObjectiveStudent.create(:user => @student_2, :objective => mainassign_1, :ready => false)
        os_2 = ObjectiveStudent.create(:user => @student_2, :objective => mainassign_2, :ready => false)
        ObjectiveStudent.create(:user => @student_2, :objective => other_preassign, :points_all_time => 2)
        
        @test_obj_stud.update(:teacher_granted_keys => 2)
       
        go_to_first_period
        begin_quiz
        
        10.times do
            answer_question_correctly
            click_on("Next Question")
        end
        submit_quiz
        
        assert os_1.reload.ready
        assert_not os_2.reload.ready
    end

    test "delete oldest upon fifth try" do
        should_count = [1,2,3,4,5,5,5,5]
        @test_obj_stud.update(:teacher_granted_keys => 2)
        
        go_to_first_period
        
        8.times do |trip|
            begin_quiz
            10.times do
                answer_question_incorrectly
                click_on "Next Question"
            end
            submit_quiz
            click_on("Back to Your Class Page")
            @test_obj_stud.reload.update(:teacher_granted_keys => 2)
            
            these_quizzes = Quiz.where(:user => @test_obj_stud.user, :objective => @test_obj_stud.objective)
            assert_equal should_count[trip], these_quizzes.count
        end
    end

    test "delete quiz with no ripostes" do
        this_obj = @test_obj_stud.objective
        this_user = @test_obj_stud.user
        q1 = Quiz.create(:user => this_user, :objective => this_obj)
        q2 = Quiz.create(:user => this_user, :objective => this_obj)
        3.times do
            q2.ripostes.create(:question => Question.first)
        end
        
        assert_equal 2, Quiz.where(:user => this_user, :objective => this_obj).count
        
        go_to_first_period
        click_on("Quizzes")
        
        assert_equal 1, Quiz.where(:user => this_user, :objective => this_obj).count

    end
    
    
end
