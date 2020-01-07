class RipostesController < ApplicationController
    
    def edit
        @riposte = Riposte.find(params[:id])
        @question = @riposte.question
    end
    
    def update
        @riposte = Riposte.find(params[:id])
        @question = @riposte.question
        @quiz = @riposte.quizzes.order(:created_at).last
        
        if @quiz.total_score == nil
            next_riposte_num = @riposte.position + 1
            
            perc = 0
            if @question.label.grade_type == "computer"
                is_graded = 1
                if params[:riposte].nil? || params[:riposte][:stud_answer].blank?
                    stud_answer = ["blank"]
                    is_graded = nil
                else
                    stud_answer = []
                    if @question.style == "fill_in"
                        stud_answer = [params[:riposte][:stud_answer]]
                        correct_poss = 2
                        correct_array = @question.correct_answers.map{|e| e.downcase.gsub(/\s+/, "").gsub(/[()]/, "")}
                        backend_answer = stud_answer.map{|e| e.downcase.gsub(/\s+/, "").gsub(/[()]/, "")}
                    else
                        params[:riposte][:stud_answer].each do |this_answer|
                            stud_answer << @question.choices[this_answer.to_i]
                        end
                        correct_array = @question.correct_answers
                        backend_answer = stud_answer
                        correct_poss = backend_answer.length + correct_array.length
                    end
                    correct_count = 2 * (backend_answer & correct_array).length
                    perc = (@riposte.poss * correct_count.to_f / correct_poss.to_f).round
                end
            else
                is_graded = 0
                stud_answer = [params[:riposte][:stud_answer]]
            end
        
            @riposte.update(:stud_answer => stud_answer, :tally => perc, :graded => is_graded)
            @quiz.update(:progress => next_riposte_num)
            
            if @riposte == @quiz.ripostes.order(:position).last
                @student = @quiz.user
                @objective = @quiz.objective
                @this_obj_stud = @student.objective_students.find_by(:objective => @objective)
                @quiz.set_total_score
                take_post_req_keys
                redirect_to quiz_path(@quiz)
            else
                next_riposte = @quiz.ripostes.find_by(:position => next_riposte_num)
                redirect_to  edit_riposte_path(next_riposte)
            end
        else
            redirect_to quiz_path(@quiz)
        end
    end
    
    # Erase this after using
    def update_quantities
        if params[:syl]
            params[:syl].each do |key, value|
                @lo = LabelObjective.find(key)
                @lo.update(:quantity => value[:quantity], :point_value => value[:point_value])
            end
        end
        redirect_to current_user
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
        
        def take_post_req_keys
            if @this_obj_stud.total_keys == 0 && !@this_obj_stud.passed
                @objective.mainassigns.each do |mainassign|
                    this_mainassign = mainassign.objective_students.find_by(:user => @student)
                    this_mainassign.update(:pretest_keys => 0) if this_mainassign
                end
            end
        end
    
end
