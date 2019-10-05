require 'test_helper'

class ConsultanciesShowTest < ActionDispatch::IntegrationTest
    
    include DeskConsultants
    include ConsultanciesHelper
    include AddStudentStuff
    
    def setup
        setup_users
        setup_schools
        setup_seminars
        setup_scores
        setup_objectives
        
        @consultancy = @seminar.consultancies.create # Most tests rely on one consultancy already existing.
        @seminar.seminar_students.update_all(:created_at => "2017-07-16 03:10:54")
        @cThresh = @seminar.consultantThreshold
        @objective_zero_priority = objectives(:objective_zero_priority)
        
        @student_1 = users(:student_1)
        @student_2 = users(:student_2)
        @student_3 = users(:student_3)
        @student_4 = users(:student_4)
        @student_5 = users(:student_5)
        @student_6 = users(:student_6)
        @student_7 = users(:student_7)
        @student_8 = users(:student_8)
        @student_9 = users(:student_9)
        @student_10 = users(:student_10)
        @student_46 = users(:student_46)
        
        @ss_1 = SeminarStudent.find_by(:seminar_id => @seminar.id, :user_id => @student_1.id)
        @ss_2 = SeminarStudent.find_by(:seminar_id => @seminar.id, :user_id => @student_2.id)
        @ss_3 = SeminarStudent.find_by(:seminar_id => @seminar.id, :user_id => @student_3.id)
        @ss_4 = SeminarStudent.find_by(:seminar_id => @seminar.id, :user_id => @student_4.id)
        @ss_5 = SeminarStudent.find_by(:seminar_id => @seminar.id, :user_id => @student_5.id)
        @ss_6 = SeminarStudent.find_by(:seminar_id => @seminar.id, :user_id => @student_6.id)
        @ss_7 = SeminarStudent.find_by(:seminar_id => @seminar.id, :user_id => @student_7.id)
        @ss_8 = SeminarStudent.find_by(:seminar_id => @seminar.id, :user_id => @student_8.id)
        @ss_9 = SeminarStudent.find_by(:seminar_id => @seminar.id, :user_id => @student_9.id)
        @ss_10 = SeminarStudent.find_by(:seminar_id => @seminar.id, :user_id => @student_10.id)
        @ss_46 = SeminarStudent.find_by(:seminar_id => @seminar.id, :user_id => @student_46.id)
        
        set_date_3 = Date.today - 100.days
        set_date_4 = Date.today - 120.days
        @seminar.seminar_students.update_all(:created_at => set_date_3)
        @ss_8.update(:created_at => set_date_4)
        
        # Scores
        set_all_scores(:user, @student_10, 10)
        set_all_scores(:user, @student_5, 10)
        set_all_scores(:user, @student_8, 2)
        set_specific_score(@student_9, @objective_10, 2)
        set_specific_score(@student_9, @objective_20, 2)
            
        # Requests
        @ss_5.update(:pref_request => 0)
        @ss_6.update(:learn_request => @objective_50.id)
        @ss_7.update(:teach_request => @objective_20.id, :pref_request => 2)
        @ss_9.update(:learn_request => @objective_20.id)
        @ss_10.update(:learn_request => @objective_40.id)
        @ss_46.update(:teach_request => @objective_zero_priority.id)
        
        # Ensure all requests are for subjects where the student is qualified
        SeminarStudent.all.each do |ss|
            this_tr = ss.teach_request
            if this_tr
                ss.update(:teach_request => nil) if ss.user.score_on(this_tr) < 7
            end
        end
            
        # Priorities
        @own_assign.objective_seminars.find_by(:seminar_id => @seminar.id).update(:priority => 1)
        @objective_zero_priority.objective_seminars.find_by(:seminar_id => @seminar.id).update(:priority => 0) # To test that student who requested this doesn't get a group.
            
        @cThresh = @seminar.consultantThreshold
    end
    
    def method_setup
        @cThresh = @seminar.consultantThreshold
        @consultancy = Consultancy.create(:seminar => @seminar)
        @students = setup_present_students
        @rank_objectives_by_need = @seminar.rank_objectives_by_need
        @rank_by_consulting = setup_rank_by_consulting
        refresh_all_obj_sems(@seminar)
        @need_hash = setup_need_hash
        @prof_list = setup_prof_list 
    end
    
    def contrived_setup
        @seminar = Seminar.create(:name => "Contrived Seminar")
        @seminar.teachers << @teacher_1
        @c_obj_1 = @seminar.objectives.create(:name => "Contrived Already Mastered Objective")
        @c_obj_2 = @seminar.objectives.create(:name => "Contrived Pre-Objective")
        @c_obj_3 = @seminar.objectives.create(:name => "Contrived Main-Objective")
        @c_obj_4 = @seminar.objectives.create(:name => "Learn Request for the Lone Student")
        @c_obj_5 = @seminar.objectives.create(:name => "Option for stud with no learn_request")
        @c_obj_3.preassigns << @c_obj_2
        @c_stud_1 = Student.create(:first_name => "A", :last_name => "B")
        @c_stud_2 = Student.create(:first_name => "C", :last_name => "D")
        @c_stud_3 = Student.create(:first_name => "E", :last_name => "F")
        @c_stud_4 = Student.create(:first_name => "G", :last_name => "H")
        @c_stud_5 = Student.create(:first_name => "I", :last_name => "J")
        @c_stud_6 = Student.create(:first_name => "K", :last_name => "L")
        @c_stud_7 = Student.create(:first_name => "M", :last_name => "N")
        @c_stud_8 = Student.create(:first_name => "O", :last_name => "P")
        @c_stud_9 = Student.create(:first_name => "Q", :last_name => "R")
        @c_stud_10 = Student.create(:first_name => "S", :last_name => "T")
        
        Student.all.each do |student|
            Objective.all.each do |objective|
                student.objective_students.find_or_create_by(:objective => objective)
                student.quizzes.create(:objective => objective, :total_score => 2, :origin => "teacher_granted")
            end
        end
        @seminar.students << @c_stud_1
        @seminar.students << @c_stud_2
        @seminar.students << @c_stud_3
        @seminar.students << @c_stud_4
        @seminar.students << @c_stud_5
        @seminar.students << @c_stud_6
        @seminar.students << @c_stud_7
        @seminar.students << @c_stud_8
        @seminar.students << @c_stud_9
        @seminar.students << @c_stud_10
    end
    
    def test_all_consultants
        @consultancy.teams.each do |team|
            if team.consultant.present?
                assert team.consultant.score_on(team.objective) >= 6
            end
        end
    end
    
    def test_all_apprentices
        @consultancy.teams.each do |team|
            team.users.each do |member|
                unless member == team.consultant
                    assert member.score_on(team.objective) <= 6
                end
            end
        end
    end
    
    test "show consultancy" do
        capybara_login(@teacher_1)
        click_on("consultancy_#{@seminar.id}")
        @consultancy = @seminar.consultancies.order(:created_at).last
        assert_text(show_consultancy_headline(@consultancy))
    end
    
    test "show first consultancy" do
        @seminar.consultancies.destroy_all
        capybara_login(@teacher_1)
        click_on("consultancy_#{@seminar.id}")
        assert_text("Mark Attendance Before Creating Desk-Consultants Groups")
    end
    
    test "preview then permanent" do
        capybara_login(@teacher_1)
        click_on("consultancy_#{@seminar.id}")
        click_on("#{new_consultancy_button_text}")
        assert_text("Mark Attendance Before Creating Desk-Consultants Groups")
        refresh_all_obj_sems(@seminar)
        click_on("Create Desk Consultants Groups")
        
        # Check Preview Values
        @consultancy = @seminar.consultancies.last
        assert_equal "preview", @consultancy.duration
        team_1 = @consultancy.teams.first
        stud_to_check = team_1.users.detect{|x| x != team_1.consultant}
        this_obj_stud = ObjectiveStudent.find_by(:user => stud_to_check, :objective => team_1.objective)
        this_obj_stud.update(:points_this_term => 2) # To ensure that points_this_term is not 10.  If it were, then no keys would be given.
        assert_equal 0, this_obj_stud.dc_keys
        first_consultant = @consultancy.teams.first.consultant
        first_consultant_ss = SeminarStudent.find_by(:user => first_consultant, :seminar => @seminar)
        assert_not_equal Date.today, first_consultant_ss.last_consultant_day
        
        # Views for Preview
        assert_text(show_consultancy_headline(@consultancy))
        assert_selector('h5', :text => "Save this Arrangement and Give Quiz Keys to Students")
        click_on("Save this Arrangement and Give Quiz Keys to Students")
        
        # Reload and Check Permanent Values
        # Check that students have been given keys
        @consultancy.reload
        this_obj_stud.reload
        first_consultant_ss.reload
        assert_equal 2, this_obj_stud.dc_keys
        assert_equal "permanent", @consultancy.duration
        assert_equal Date.today, first_consultant_ss.last_consultant_day
        
        # View for Permanent
        assert_text(show_consultancy_headline(@consultancy))
        assert_no_selector('h4', :text => "Save this Arrangement and Give Quiz Keys to Students")
    end
    
    test "delete consultancy from show page" do
        old_consultancy_count = Consultancy.count
        
        capybara_login(@teacher_1)
        click_on("consultancy_#{@seminar.id}")
        find("#delete_#{@consultancy.id}").click
        click_on("confirm_#{@consultancy.id}")
        
        assert_text("All Arrangements")
        
        assert_equal old_consultancy_count - 1, Consultancy.count
    end
    
    test "setup_present_students" do
        @ss_2.update(:present => false)
        @ss_3.update(:present => true)
        @students = setup_present_students
        assert @students.include?(@student_1)
        assert_not @students.include?(@student_2)
    end
    
    test "rank by consulting" do
        set_date = Date.today - 80.days
        set_date_2 = Date.today - 10.days
        set_date_3 = Date.today - 5.days
        
        @student_41 = @seminar.students.create(:first_name => "Marko", :last_name => "Zivkovic", :type => "Student", :password_digest => "password")
        @ss_41 = SeminarStudent.find_by(:user => @student_41, :seminar => @seminar)
        
        @ss_1.update(:pref_request => 0)
        @ss_2.update(:pref_request => 1)
        @ss_3.update(:pref_request => -1)
        @ss_1.update(:last_consultant_day => set_date)
        @ss_2.update(:last_consultant_day => set_date_2)
        @ss_3.update(:last_consultant_day => set_date_3)
        @seminar.seminar_students.each do |ss|
            ss.reload
        end
        
        assert_equal set_date, @ss_1.last_consultant_day
        assert_equal set_date_2, @ss_2.last_consultant_day
        assert_equal set_date_3, @ss_3.last_consultant_day
        assert_equal Date.today, @ss_41.last_consultant_day
        
        @students = setup_present_students
        @rank_by_consulting = setup_rank_by_consulting

        assert_equal @student_41, @rank_by_consulting[-1]
        assert_equal @student_3, @rank_by_consulting[-2]
        assert_equal @student_2, @rank_by_consulting[-3]
    end
    
    test "rank objectives by need" do
        @objective_40.objective_seminars.find_by(:seminar_id => @seminar.id).update(:priority => 5)
        @rank_objectives_by_need = @seminar.rank_objectives_by_need
        assert_equal @objective_40, @rank_objectives_by_need[0]
        
        @seminar.seminar_students.find_by(:user => @student_4).update(:learn_request => @objective_30.id)
        @objective_30.objective_seminars.find_by(:seminar_id => @seminar.id).update(:priority => 5)
        @objective_50.objective_seminars.find_by(:seminar_id => @seminar.id).update(:priority => 0)
        @seminar.seminar_students.find_by(:user => @student_5).update(:learn_request => @objective_20.id)
        @seminar.reload
        
        @rank_objectives_by_need = @seminar.rank_objectives_by_need
        assert_equal @objective_30, @rank_objectives_by_need[0]
        assert_equal @objective_40, @rank_objectives_by_need[1]
        assert_equal @objective_20, @rank_objectives_by_need[2]
        assert_not @rank_objectives_by_need.include?(@objective_50)
    end
    
    test "prof list" do
        @students = setup_present_students
        @prof_list = setup_prof_list
        @prof_list.each_with_index do |stud, index|
            assert stud.quiz_stars_all_time(@seminar) <= @prof_list[index+1].quiz_stars_all_time(@seminar) if index < @prof_list.count - 1
        end
        assert @prof_list.first.quiz_stars_all_time(@seminar) < @prof_list.last.quiz_stars_all_time(@seminar)
    end
    
    test "choose consultants" do
        method_setup
        rbc_0 = @rank_by_consulting[0]
        rbc_1 = @rank_by_consulting[1]
        rbc_2 = @rank_by_consulting[2]
        rbc_3 = @rank_by_consulting[3]
        rbc_last = @rank_by_consulting[-1]
        
        # Make sure there is need for some consultants
        these_obj_studs = @seminar.obj_studs_for_seminar
        12.times do |n|
            these_obj_studs[n].update(:points_all_time => 3)
        end
        
        # Last student is the only one qualified for a high-priority objective
        @objective_40.objective_seminars.find_by(:seminar_id => @seminar.id).update(:priority => 5)
        ObjectiveStudent.where(:objective => @objective_40).update_all(:points_all_time => 0)
        @objective_50.objective_seminars.find_by(:seminar_id => @seminar.id).update(:priority => 5)
        ObjectiveStudent.where(:objective => @objective_50).update_all(:points_all_time => 0)
        set_specific_score(rbc_last, @objective_40, 7)
        set_specific_score(rbc_3, @objective_50, 7)
        
        # Highest student in rank_by_consulting has a teach_request to check for
        requested_objective = @seminar.objectives.detect{|x| x.id != @objective_40.id && x.id != @objective_50.id}
        rbc_0_ss = SeminarStudent.find_by(:user => rbc_0, :seminar => @seminar)
        rbc_0_ss.update(:teach_request => requested_objective.id)
        set_specific_score(rbc_0, requested_objective, 7)
        
        # Second-highest student is not qualified in anything
        ObjectiveStudent.where(:user => rbc_1).update_all(:points_all_time => 4)
        
        # No teams before choose_consultants
        assert_equal 0, @consultancy.teams.count
        choose_consultants
        
        #Several teams exist
        assert @consultancy.teams.count > 1
        
        #Only consultants are placed so far
        @consultancy.users.each do |stud|
            assert_equal stud, stud.teams.find_by(:consultancy => @consultancy).consultant
        end
        
        # Priority #5 assignments are included first
        assert_equal @objective_40, rbc_last.teams.find_by(:consultancy => @consultancy).objective
        assert_equal 1, @consultancy.teams.where(:objective => @objective_40).count 
        assert_equal @objective_50, rbc_3.teams.find_by(:consultancy => @consultancy).objective
        assert_equal 1, @consultancy.teams.where(:objective => @objective_50).count
        
        # First student in rank_by_consulting receives her teach_request
        rbc_0_ss.reload
        assert_equal Objective.find(rbc_0_ss.teach_request),
            @consultancy.teams.find_by(:consultant => rbc_0).objective
        
        # Second student in rank_by_consulting gets skipped because she's unqualified
        assert_not @consultancy.users.include?(rbc_1)
        assert @consultancy.users.include?(rbc_2)

        test_all_consultants
    end
    
    test "deprioritize consultants who already have keys" do
        method_setup
        top_choice_consultant = @rank_by_consulting[0]
        second_choice_consultant = @rank_by_consulting[1]
        other_students = @seminar.students.select{|x| x != top_choice_consultant && x != second_choice_consultant}.take(3)
        
        top_choice_consultant.seminar_students.find_by(:seminar => @seminar).update(:teach_request => nil)
        @objective_40.objective_seminars.find_by(:seminar_id => @seminar.id).update(:priority => 5)
        other_students.each do |stud|
            set_specific_score(stud, @objective_40, 0)
        end
        set_specific_score(top_choice_consultant, @objective_40, 8)
        @objective_40.objective_students.find_by(:user => top_choice_consultant).update(:pretest_keys => 2)
        set_specific_score(second_choice_consultant, @objective_40, 8)
        
        choose_consultants
        
        assert_equal 0, @consultancy.teams.where(:consultant => top_choice_consultant, :objective => @objective_40).count
        assert_equal 1, @consultancy.teams.where(:consultant => second_choice_consultant, :objective => @objective_40).count
    end
    
    test "deprioritize consultants with 100 score" do
        method_setup
        top_choice_consultant = @rank_by_consulting[0]
        second_choice_consultant = @rank_by_consulting[1]
        
        @objective_40.objective_seminars.find_by(:seminar_id => @seminar.id).update(:priority => 5)
        @rank_by_consulting[2..4].each do |stud|
            set_specific_score(stud, @objective_40, 0)
        end
        @rank_by_consulting[5..@rank_by_consulting.count].each do |stud|
            set_specific_score(stud, @objective_40, 7)
        end
        set_specific_score(top_choice_consultant, @objective_40, 10)
        set_specific_score(second_choice_consultant, @objective_40, 8)
        
        choose_consultants
        
        assert_equal 0, @consultancy.teams.where(:consultant => top_choice_consultant, :objective => @objective_40).count
        assert_equal 1, @consultancy.teams.where(:consultant => second_choice_consultant, :objective => @objective_40).count
    end
    
    test "but assign 100 score consultant if needed" do
        method_setup
        top_choice_consultant = @rank_by_consulting[0]
        second_choice_consultant = @rank_by_consulting[1]
        
        @objective_40.objective_seminars.find_by(:seminar_id => @seminar.id).update(:priority => 5)
        @rank_by_consulting[2..@rank_by_consulting.count].each do |stud|
            set_specific_score(stud, @objective_40, 0)
        end
        set_specific_score(top_choice_consultant, @objective_40, 10)
        set_specific_score(second_choice_consultant, @objective_40, 8)
        
        choose_consultants
        
        assert_equal 1, @consultancy.teams.where(:consultant => top_choice_consultant, :objective => @objective_40).count
        assert_equal 1, @consultancy.teams.where(:consultant => second_choice_consultant, :objective => @objective_40).count
    end
    
    test "team has room" do
        c1 = Consultancy.create(:seminar => @seminar)
        t1 = c1.teams.create(:consultant => @student_1, :objective => @objective_10)
        t1.users << @student_1
        
        t2 = c1.teams.create(:consultant => @student_2, :objective => @objective_10)
        t2.users << @student_2
        
        t3 = c1.teams.create(:consultant => @student_3, :objective => @objective_20)
        t3.users << @student_3
        
        # True if all teams are empty
        assert t1.has_room
        assert t2.has_room
        assert t3.has_room
        
        # True if all smaller teams are studying different objectives
        t1.users << @student_4
        t2.users << @student_5
        assert t1.has_room
        assert t2.has_room
        assert t3.has_room
        
        # False if one team with the same objective has fewer members
        t1.users << @student_6
        assert_not t1.has_room
        assert t2.has_room
        
        # True if all teams are equal
        t2.users << @student_7
        assert t1.has_room
        assert t2.has_room
        
        # False if team has over three members
        t1.users << @student_8
        t2.users << @student_9
        assert_not t1.has_room
        assert_not t2.has_room
    end
    
    test "place apprentices by request" do
        @objective_20.objective_seminars.find_by(:seminar => @seminar).update(:priority => 5)
        set_specific_score(@student_1, @objective_20, 8)
        
        request_obj = Objective.find(@ss_6.learn_request)
        request_obj.objective_seminars.find_by(:seminar => @seminar).update(:priority => 5)
        set_specific_score(@student_2, request_obj, 8)
        
        method_setup
        choose_consultants  
        test_all_consultants  # This is tested earlier, but I also wanted to test consultants with a less-contrived setup.
        place_apprentices_by_requests
        test_all_apprentices
        
        # Students who had a request available received their request.
        assert request_obj, @student_6.teams.find_by(:consultancy => @consultancy).objective.id
    end
    
    test "find placement" do
        contrived_setup
        
        set_specific_score(@c_stud_4, @c_obj_1, 9)
        set_specific_score(@c_stud_4, @c_obj_2, 2)
        set_specific_score(@c_stud_4, @c_obj_3, 2)
        
        set_specific_score(@c_stud_9, @c_obj_1, 2)
        set_specific_score(@c_stud_9, @c_obj_2, 2)
        set_specific_score(@c_stud_9, @c_obj_3, 2)
        
        set_specific_score(@c_stud_10, @c_obj_1, 9)
        set_specific_score(@c_stud_10, @c_obj_2, 9)
        set_specific_score(@c_stud_10, @c_obj_3, 2)
        
        t1 = @consultancy.teams.create(:consultant => @c_stud_1, :objective => @c_obj_1) # Student_4 scored too high on this objective
        t1.users << @c_stud_1
        # Pre-Objective isn't offered
        t2 = @consultancy.teams.create(:consultant => @c_stud_2, :objective => @c_obj_3) # Student_4 isn't ready for this objective
        t2.users << @c_stud_2
        t3 = @consultancy.teams.create(:consultant => @c_stud_3, :objective => @c_obj_2) # Student_4 could join this team, but it doesn't have room
        t3.users << @c_stud_3
        t3.users << @c_stud_5
        t3.users << @c_stud_6
        t3.users << @c_stud_7
        
        @students = setup_present_students 
        @need_hash = setup_need_hash
        assert_nil find_placement(@c_stud_4,7)
        
        assert_equal t1, find_placement(@c_stud_9,7)
        
        assert_equal t2, find_placement(@c_stud_10,7)
        
        # Now make a team available for @c_obj_2
        # Also adds student to that team
        t4 = @consultancy.teams.create(:consultant => @c_stud_8, :objective => @c_obj_2) 
        t4.users << @c_stud_8
        
        assert_equal 1, t4.users.count
        assert_equal t4, find_placement(@c_stud_4, 7)
        assert_equal 2, t4.users.count
        assert t4.users.include?(@c_stud_4)
        test_all_apprentices
    end
    
    test "place apprentices by mastery" do
        method_setup
        choose_consultants
        #place_apprentices_by_requests
        
        # The method places some students
        old_count = @consultancy.users.count
        place_apprentices_by_mastery
        assert @consultancy.users.count > old_count
        
        # Unplaced students are proficent everywhere there's room
        unplaced_so_far = @students.select{|x| need_placement(x)}
        assert unplaced_so_far.count > 0   # Even with random scores, student_5 should still be unplaced
        assert_equal @consultancy.users.count + unplaced_so_far.count, @students.count
        teams_with_room = @consultancy.teams.select{|x| x.has_room}
        unplaced_so_far.each do |stud|
            teams_with_room.each do |team|
                obj_stud = stud.objective_students.find_by(:objective => team.objective)
                assert !obj_stud.ready || !obj_stud.obj_willing?(@cThresh)
            end
        end
        
        # All apprentices are non-proficient, but ready for the team's objective
        @consultancy.teams.each do |team|
            team.users.reject{|x| x == team.consultant}.each do |stud|
                assert stud.objective_students.find_by(:objective => team.objective).obj_ready_and_willing?(@cThresh)
            end
        end
        
        # No student placed more than once
        @seminar.students.each do |student|
            assert student.teams.where(:consultancy => @consultancy).count < 2
        end
        test_all_apprentices
    end
    
    test "check for lone students" do
        contrived_setup
        
        t1 = @consultancy.teams.create(:consultant => @c_stud_1, :objective => @c_obj_1)  # Home for the first student, who is placed in an existing group
        t1.users << @c_stud_1
        t1.users << @c_stud_4
        t2 = @consultancy.teams.create(:consultant => @c_stud_2, :objective => @c_obj_1)  # Home for the second student, who starts a new group with her learn_request
        t2.users << @c_stud_2
        t3 = @consultancy.teams.create(:consultant => @c_stud_3, :objective => @c_obj_2)  # Home for the fourth student, who starts a new group with her first learn_option
        t3.users << @c_stud_3
        
        # Singleton teams are deleted
        assert Team.all.select{|x| x.users.count == 1}.count > 1
        check_for_lone_students
        assert_equal 0, Team.all.select{|x| x.users.count == 1}.count
        test_all_apprentices
    end
    
    test "new place for lone students" do
        contrived_setup
        
        set_specific_score(@c_stud_10, @c_obj_1, 2)
        
        set_specific_score(@c_stud_9, @c_obj_1, 9)
        set_specific_score(@c_stud_9, @c_obj_2, 9)
        set_specific_score(@c_stud_9, @c_obj_3, 9)
        set_specific_score(@c_stud_9, @c_obj_4, 6)
        set_specific_score(@c_stud_9, @c_obj_5, 5)
        
        @c_stud_9.seminar_students.find_by(:seminar => @seminar).update(:learn_request => @c_obj_4.id)
        
        set_specific_score(@c_stud_8, @c_obj_1, 9)
        set_specific_score(@c_stud_8, @c_obj_2, 9)
        
        set_specific_score(@c_stud_7, @c_obj_1, 7)
        set_specific_score(@c_stud_7, @c_obj_2, 7)
        set_specific_score(@c_stud_7, @c_obj_3, 7)
        set_specific_score(@c_stud_7, @c_obj_4, 7)
        set_specific_score(@c_stud_7, @c_obj_5, 0)
        
        set_specific_score(@c_stud_6, @c_obj_1, 10)
        set_specific_score(@c_stud_6, @c_obj_2, 10)
        set_specific_score(@c_stud_6, @c_obj_3, 10)
        set_specific_score(@c_stud_6, @c_obj_4, 10)
        set_specific_score(@c_stud_6, @c_obj_5, 10)
        
        method_setup
        
        t1 = @consultancy.teams.create(:consultant => @c_stud_1, :objective => @c_obj_1)  # Home for the first student, who is placed in an existing group
        t1.users << @c_stud_1
        t1.users << @c_stud_4
        t2 = @consultancy.teams.create(:consultant => @c_stud_2, :objective => @c_obj_1)  # Home for the second student, who starts a new group with her learn_request
        t2.users << @c_stud_2
        t2.users << @c_stud_5
        t3 = @consultancy.teams.create(:consultant => @c_stud_3, :objective => @c_obj_2)  # Home for the fourth student, who starts a new group with her first learn_option
        t3.users << @c_stud_3
        
        assert_equal 3, @consultancy.teams.count
        new_place_for_lone_students
        @consultancy.reload
        
        # One student is placed in an existing group
        assert @consultancy.users.include?(@c_stud_10)
        
        # Another student receives her learn_request
        assert @consultancy.teams.count > 3
        t4 =  @c_stud_9.teams.find_by(:consultancy => @consultancy)
        assert_equal @c_obj_4, t4.objective 
        
        # Third student is placed in that newly-created group
        assert t4.users.include?(@c_stud_8)
        
        # Fourth student starts a new group with her first learn option (Because she has no learn request.)
        this_team = @c_stud_7.teams.find_by(:consultancy => @consultancy)
        learn_opt_1 = @c_stud_7.learn_options(@consultancy.seminar)[0]
        assert_equal learn_opt_1, this_team.objective

        # Last student is still unplaced
        assert_not @consultancy.users.include?(@c_stud_6)
    end

    test "are some unplaced" do
        @student_10.seminar_students.find_by(:seminar => @seminar).update(:learn_request => nil)
        
        method_setup
        choose_consultants
        place_apprentices_by_requests
        place_apprentices_by_mastery
        check_for_lone_students
        new_place_for_lone_students
        are_some_unplaced
        
        assert_equal 1, @consultancy.teams.where(:bracket => 1).count
        unplaced_team = @consultancy.teams.find_by(:bracket => 1)
    
        assert unplaced_team.users.include?(@student_5)
        assert unplaced_team.users.include?(@student_10)
    end
    
    test "destroy if date already" do
        consult_count = Consultancy.count
        
        Consultancy.create(:seminar => @seminar)
        assert_equal consult_count + 1, Consultancy.count
        
        capybara_login(@teacher_1)
        click_on("consultancy_#{@seminar.id}")
        click_on("#{new_consultancy_button_text}")
        refresh_all_obj_sems(@seminar)
        click_on("Create Desk Consultants Groups")
        assert_equal consult_count + 1, Consultancy.count
    end
    
    test "destroy oldest upon tenth" do
        @seminar.consultancies.create(:created_at => "2017-07-15 03:10:54")
        @seminar.consultancies.create(:created_at => "2017-07-14 03:10:54")
        @seminar.consultancies.create(:created_at => "2017-07-13 03:10:54")
        @seminar.consultancies.create(:created_at => "2017-07-12 03:10:54")
        @seminar.consultancies.create(:created_at => "2017-07-11 03:10:54")
        @seminar.consultancies.create(:created_at => "2017-07-10 03:10:54")
        @seminar.consultancies.create(:created_at => "2017-07-09 03:10:54")
        @seminar.consultancies.create(:created_at => "2017-07-08 03:10:54")
        @seminar.consultancies.create(:created_at => "2017-07-07 03:10:54")
        
        refresh_all_obj_sems(@seminar)
        assert_equal 10, @seminar.consultancies.count
        
        capybara_login(@teacher_1)
        click_on("consultancy_#{@seminar.id}")
        click_on("#{new_consultancy_button_text}")
        click_on("Create Desk Consultants Groups")
        
        @seminar.reload
        assert_equal 10, @seminar.consultancies.count
    end
end
