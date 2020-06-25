class RipostesController < ApplicationController
    
    def edit
        @riposte = Riposte.find(params[:id])
        @quiz = @riposte.quizzes.order(:created_at).last
        @question = @riposte.question
    end
    
    def update
        @riposte = Riposte.find(params[:id])
        @question = @riposte.question
        @quiz = @riposte.quizzes.order(:created_at).last
        
        if @quiz.total_score == nil
            @perc = 0
            @stud_answer = []
            next_riposte_num = @riposte.position + 1
            if @question.label.grade_type == "computer"
                is_graded = 1
                if params[:riposte].nil? || params[:riposte][:stud_answer].blank?
                    @stud_answer = ["blank"]
                    is_graded = nil
                else
                    computer_grades_question
                end
            else
                is_graded = 0
                @stud_answer = [params[:riposte][:stud_answer]]
            end
        
            @riposte.update(:stud_answer => @stud_answer, :tally => @perc, :graded => is_graded)
            @quiz.update(:progress => next_riposte_num)
            
            if params[:commit] == "Previous Question"
                prev_riposte_num = @riposte.position - 1
                prev_riposte = @quiz.ripostes.find_by(:position => prev_riposte_num)
                redirect_to edit_riposte_path(prev_riposte)
            elsif @riposte == @quiz.ripostes.order(:position).last || params[:commit] == "Finish Quiz"
                redirect_to quiz_path(@quiz, :finished => false)
            else
                next_riposte = @quiz.ripostes.find_by(:position => next_riposte_num)
                redirect_to  edit_riposte_path(next_riposte)
            end
        else
            redirect_to quiz_path(@quiz)
        end
    end

    
    def teacher_grading
        if params[:ripostes]
            params[:ripostes].each do |key, value|
                @riposte = Riposte.find(key)
                new_tally = ((value.to_i/10.to_f)*@riposte.poss).round
                graded_now = value.present? ? 1 : 0  # If the value is blank, leave the riposte marked ungraded
                @riposte.update(:tally => new_tally, :graded => graded_now)
                @riposte.quizzes.each do |quiz|
                    quiz.set_total_score
                end
            end
        end
        
        redirect_to current_user
    end

    private
    
        def computer_grades_question
            correct_poss = 2
            if @question.style == "fill_in"
                @stud_answer = [params[:riposte][:stud_answer]]
                correct_array = @question.correct_answers.map{|e| e.downcase.gsub(/\s+/, "").gsub(/[()]/, "")}
                backend_answer = @stud_answer.map{|e| e.downcase.gsub(/\s+/, "").gsub(/[()]/, "")}
            elsif @question.style == "interval"
                @stud_answer = [params[:riposte][:stud_answer].to_f]
                low_answer = @question.correct_answers[0].to_f
                high_answer = @question.correct_answers[1].to_f
                backend_answer = @stud_answer
                correct_array = []
                correct_array = @stud_answer if @stud_answer[0].between?(low_answer,high_answer)
            else
                @stud_answer = []
                params[:riposte][:stud_answer].each do |this_answer|
                    @stud_answer << @question.choices[this_answer.to_i]
                end
                correct_array = @question.correct_answers
                backend_answer = @stud_answer
                correct_poss = backend_answer.length + correct_array.length
            end
            correct_count = 2 * (backend_answer & correct_array).length
            @perc = (@riposte.poss * correct_count.to_f / correct_poss.to_f).round
        end
    

    
end
