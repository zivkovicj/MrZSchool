require 'test_helper'

class QuestionsNewTest < ActionDispatch::IntegrationTest

    def setup
        setup_users
        setup_schools
        setup_labels
        setup_pictures
        
        @new_choice = [["Blubber", "Scoober Doofus", "Hardunkinchud @ Aliciousness", 
            "{The Player formerly known as Mousecop}", "Red Grange", "1073514"],
            ["Yep.","Nope."],
            ["Nep.","Yope."],
            ["Meep","Yeep","Bleep","Creep"],
            ["Boop","Doop","Goop","Shoop","Stoop"]]
        @new_prompt = ["How many Scoobers can a Scoober Doof?",
            "Are there two questions?",
            "Are there three?",
            "Are there four?",
            "Surely there can't be five!"]
            
        @old_question_count = Question.count
    end
    
    def go_to_new_questions
        click_on("View/Create Content")
        click_on("Create New Questions")
    end
        

    test "create multiple choice questions" do
        capybara_login(@teacher_1)
        go_to_new_questions
        
        assert_selector('input', :id => "style_multiple-choice") # Counterpart to a line in the questions_edit_test
        assert_selector('input', :id => "label_#{@admin_l.id}")
        assert_selector('input', :id => "label_#{@user_l.id}")
        assert_selector('input', :id => "label_#{@other_l_pub.id}")
        assert_no_selector('input', :id => "label_#{@other_l_priv.id}")
        choose("label_#{@user_l.id}")
        
        click_on("Create Some Questions")
        @new_prompt.each_with_index do |prompt, index|
            fill_prompt(index)
        end
        
        @new_choice.each_with_index do |array, index|
            array.each_with_index do |blap, index_2|
                fill_choice(index, index_2)
            end
        end
        choose("question_0_whichIsCorrect_2")
        choose("question_1_whichIsCorrect_0")
        choose("question_0_picture_#{@user_p.id}")
        choose("question_0_picture_nil")
        choose("question_1_picture_#{@user_p.id}")
        assert_no_selector("question_1_picture_#{@admin_p.id}")
        click_on("Create These Questions")
        
        assert_equal @old_question_count + 5, Question.count
        Question.all[-5..-1].each_with_index do |question, index|
            assert_equal @new_prompt[index], question.prompt
            assert_equal "public", question.extent
            assert_equal "multiple-choice", question.style
            assert_equal @teacher_1, question.user
            assert_equal @user_l, question.label
            assert @user_l.questions.include?(question)
        end
        
        @new_question = Question.all[-5]
        assert @new_question.correct_answers.include?(@new_choice[0][2])
        6.times do |n|
            assert_equal @new_choice[0][n], @new_question.read_attribute("choice_#{n}")
            assert_not @new_question.correct_answers.include?(@new_choice[0][n]) if n != 2
        end
        assert @new_question.picture.blank?
        assert_equal "computer", @new_question.grade_type  # Not selected, but should be computer-graded by default
        
        @new_question_2 = Question.all[-4]
        assert_equal "Are there two questions?", @new_question_2.prompt
        assert_equal @new_choice[1][0], @new_question_2.choice_0
        assert_equal @new_choice[1][1], @new_question_2.choice_1
        assert @new_question_2.correct_answers.include?(@new_choice[1][0])
        assert_not @new_question_2.correct_answers.include?(@new_choice[1][1])
        assert_equal @user_p, @new_question_2.picture
        
        # Need to assert redirection soon
    end
    
    test "create computer graded fill in questions" do
        capybara_login(@teacher_1)
        go_to_new_questions
        
        choose("style_fill-in")
        choose("grade_type_computer")
        choose("label_#{@user_l.id}")
        click_on("Create Some Questions")
        
        assert_no_selector("h4", :text => "This question needs to be graded by a person. ")
        assert_selector("h4", :text => "A student may enter any of the answers below to earn credit.")
        fill_prompt(0)
        fill_choice(0,0)
        fill_choice(0,1)
        fill_prompt(1)
        fill_choice(1,0)
        fill_choice(1,1)
        click_on("Create These Questions")
        
        assert_equal @old_question_count + 2, Question.count
        @new_question = Question.all[-2]
        assert_equal @teacher_1, @new_question.user
        assert_equal "public", @new_question.extent
        assert_equal "fill-in", @new_question.style
        assert_equal @user_l, @new_question.label
        @user_l.questions.include?(@new_question)
        assert_equal @new_prompt[0], @new_question.prompt
        assert @new_question.correct_answers.include?(@new_choice[0][0])
        assert @new_question.correct_answers.include?(@new_choice[0][1])
        assert_not @new_question.correct_answers.include?("")
        assert_equal 2, @new_question.correct_answers.length
        assert_equal "computer", @new_question.grade_type
        
        @new_question_2 = Question.all[-1]
        assert_equal @teacher_1, @new_question_2.user
        assert_equal "public", @new_question_2.extent
        assert_equal "fill-in", @new_question_2.style
        assert_equal @user_l, @new_question_2.label
        @user_l.questions.include?(@new_question_2)
        assert_equal @new_prompt[1], @new_question_2.prompt
        assert @new_question_2.correct_answers.include?(@new_choice[1][0])
        assert @new_question_2.correct_answers.include?(@new_choice[1][1])
        assert @new_question_2.correct_answers.length == 2
    end
    
    test "create teacher graded fill in questions" do
        capybara_login(@teacher_1)
        go_to_new_questions
        
        choose("style_fill-in")
        choose("grade_type_teacher")
        choose("label_#{@user_l.id}")
        click_on("Create Some Questions")
        
        assert_selector("h4", :text => "This question needs to be graded by a person. ")
        assert_no_selector("h4", :text => "A student may enter any of the answers below to earn credit.")
        fill_in "prompt_0", with: "Prompt for teacher-graded question"
        fill_in "question_0_choice_0", with: "Your answer should be good."
        click_on("Create These Questions")
        
        assert_equal @old_question_count + 1, Question.count
        @new_question = Question.all[-1]
        assert_equal @teacher_1, @new_question.user
        assert_equal "public", @new_question.extent
        assert_equal "fill-in", @new_question.style
        assert_equal @user_l, @new_question.label
        assert_equal "Prompt for teacher-graded question", @new_question.prompt
        assert @new_question.correct_answers.include?("Your answer should be good.")
        assert_equal 1, @new_question.correct_answers.length
        assert_equal "teacher", @new_question.grade_type
    end
    
    test "dont create with empty prompt" do
        capybara_login(@teacher_1)
        go_to_new_questions
        click_on("Create Some Questions")
        
        fill_prompt(0)
        fill_prompt(2)
        click_on("Create These Questions")
        
        assert_equal @old_question_count + 2, Question.count
    end
    
    test "all prompts empty" do
        capybara_login(@teacher_1)
        go_to_new_questions
        click_on("Create Some Questions")
        
        click_on("Create These Questions")
        
        assert_equal @old_question_count, Question.count
        
        assert_selector('p', :text => "Teacher Since:")
    end
    
    test "default correct and label" do
        capybara_login(@teacher_1)
        
        go_to_new_questions
        click_on("Create Some Questions")
        fill_prompt(0)
        fill_choice(0,0)
        click_on("Create These Questions")
        
        @new_question = Question.last
        assert_equal @unlabeled_l, @new_question.label
        assert @new_question.correct_answers.include?(@new_choice[0][0])
        assert_equal "Second Choice", @new_question.choice_1
    end
    
end