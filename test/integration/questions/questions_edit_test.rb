require 'test_helper'

class QuestionsEditTest < ActionDispatch::IntegrationTest
    
    def setup
        setup_users
        setup_schools
        setup_labels
        setup_questions
        setup_pictures
        @new_prompt = ["Where do you park the car?"]
        @new_choice = [["Bill", "Nye", "The Science Guy", 
            "Please Consider the Following", "Sodium", "1111"]]
    end
    
    def on_show_page
        assert_text("You may not make any edits because it was created by another teacher.") 
    end
    
    def not_on_show_page
       assert_no_text("You may not make any edits because it was created by another teacher.")
    end
    
    def go_to_all_questions
        click_on("View/Create Content")
        click_on('All Questions')
    end
    
    def goto_mc_question
        capybara_login(@teacher_1)
        go_to_all_questions
        click_on(@user_q.short_prompt)
    end
    
    test "edit other teacher question" do
        capybara_login(@teacher_1)
        go_to_all_questions
        click_on(@other_q_pub.short_prompt)
        
        on_show_page
        assert_no_selector('textarea', :id => "prompt", :visible => true)
        assert_no_selector('input', :id => "answer_1_edit", :visible => true)
        assert_no_selector('input', :id => "question_0_is_correct_3", :visible => true)
    end
    
    test "edit admin question" do
        capybara_login(@teacher_1)
        go_to_all_questions
        
        search_for(@admin_q.prompt)
        click_on(@admin_q.short_prompt)
        
        on_show_page
        assert_no_selector('textarea', :id => "prompt", :visible => true)
        assert_no_selector('input', :id => "answer_1_edit", :visible => true)
        assert_no_selector('input', :id => "question_0_is_correct_3", :visible => true)
    end
    
    test "edit multiple choice question" do
        assert_not_equal @user_q.picture, @user_p
        assert_not @user_q.correct_answers.include?("3")
        assert_equal "private", @user_q.extent
        assert_equal @user_l, @user_q.label
        @user_q.update(:shuffle => false)

        goto_mc_question
        not_on_show_page
        assert_no_selector('input', :id => "style_multiple-choice") # Counterpart is in the questions_new_test
        assert_selector('input', :id => "question_0_is_correct_3", :visible => true)
        
        fill_prompt(0)
        fill_choice(0,0)
        choose('question_0_is_correct_3')
        choose("questions_0_extent_public")
        choose("label_#{@admin_l.id}")
        choose("question_0_picture_#{@user_p.id}")
        check("question_0_shuffle")
        click_on("save_changes_2")
        
        @user_q.reload
        assert_equal @new_prompt[0], @user_q.prompt
        assert_equal ["Bill", "1", "2", "3", "4", "5"], @user_q.choices
        assert_equal ["3"], @user_q.correct_answers
        assert_equal "public", @user_q.extent
        assert_equal @admin_l, @user_q.label
        assert_equal @user_q.picture, @user_p
        assert @user_q.shuffle
        
        assert_selector('h2', :text => "All Questions")
    end
    
    test "edit select many question" do
        @select_many_q = questions(:select_many_question)
        @select_many_l = labels(:select_many_label)
        assert_equal ["0","1","2","3","4","5"], @select_many_q.choices
        assert_equal ["0", "2", "3"], @select_many_q.correct_answers
        assert_equal "public", @select_many_q.extent
        assert_equal @select_many_l, @select_many_q.label
        @select_many_q.update(:shuffle => false)
        
        capybara_login(@teacher_1)
        go_to_all_questions
        search_for(@select_many_q.prompt)
        click_on(@select_many_q.short_prompt)
        
        fill_prompt(0)
        fill_choice(0,0)
        fill_in "question_0_choice_5", with: ""
        uncheck('question_0_is_correct_2')
        check('question_0_is_correct_4')
        check('question_0_is_correct_5') # Mark it right, but leave the space blank
        check("question_0_shuffle")
        click_on("save_changes_2")
        
        @select_many_q.reload
        assert_equal @new_prompt[0], @select_many_q.prompt
        assert_equal ["Bill","1","2","3","4"], @select_many_q.choices  # Blank choice has been removed
        assert_equal ["Bill", "3", "4"], @select_many_q.correct_answers # Blank choice is excluded
        assert_equal "public", @select_many_q.extent  # Default extent is left
        assert @select_many_q.shuffle
        
        assert_selector('h2', :text => "All Questions")
    end
    
    test "default answer choice" do
        @user_q.update(:correct_answers => ["2"], :picture => nil, :shuffle => false)
        
        capybara_login(@teacher_1)
        go_to_all_questions
        click_on(@user_q.short_prompt)
        click_on("save_changes_2")
        
        @user_q.reload
        assert_equal ["2"], @user_q.correct_answers
        assert_not @user_q.shuffle
    end
    
    test "edit fill in question" do  
        # This test also checks that the default label and extent stays the same
        
        @fill_q = Question.where(:style => "fill_in").first
        @fill_q.update(:user => @teacher_1, :extent => "public")
        new_array = @fill_q.correct_answers
        new_array.push("Test if one choice left alone")
        @fill_q.update(:correct_answers => new_array)
        old_label = @fill_q.label
        
        capybara_login(@teacher_1)
        go_to_all_questions
        search_for(@fill_q.prompt)
        click_on(@fill_q.short_prompt)
        
        fill_prompt(0)
        fill_choice(0,0)
        fill_choice(0,1)
        click_on("save_changes_2")
        
        @fill_q.reload
        assert_equal @new_prompt[0], @fill_q.prompt
        assert @fill_q.correct_answers.include?(@new_choice[0][0])
        assert @fill_q.correct_answers.include?(@new_choice[0][1])
        assert @fill_q.correct_answers.include?("Of Course")
        assert @fill_q.correct_answers.include?("Test if one choice left alone")
        assert_equal old_label, @fill_q.label
        assert_equal "public", @fill_q.extent
        
        assert_selector('h2', :text => "All Questions")
    end
    
    test "invalid question edit" do
        goto_mc_question
        fill_in "prompt_0", with: ""
        click_on("save_changes_2")
        
        assert_selector('h2', :text => "Edit Question")
        assert_selector('div', :id => "error_explanation")
        assert_selector('li', :text => "Prompt can't be blank")
    end
    
    test "delete a question" do
        old_question_count = Question.count
        
        goto_mc_question
        find("#delete_#{@user_q.id}").click
        click_on("confirm_#{@user_q.id}")
        
        assert_equal old_question_count - 1, Question.count
    end
end
