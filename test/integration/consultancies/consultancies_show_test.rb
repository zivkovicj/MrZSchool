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
        @objective_zero_priority = objectives(:objective_zero_priority)
        
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
        
        # Set a score to nil to make sure that isn't causing errors
        stud_to_nil = @seminar.students[rand(@seminar.students.count)]
        obj_to_nil = @seminar.objectives[rand(@seminar.objectives.count)]
        ObjectiveStudent.find_by(:objective => obj_to_nil, :user => stud_to_nil).update(:points_all_time => nil)
        
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
        set_priority(@own_assign, 1)
        set_priority(@objective_zero_priority, 0)  # To test that student who requested this doesn't get a group.
        
        
    end
    
    def setup_before_rbc
        @sem_studs_hash = setup_sem_studs_hash
        @rank_by_consulting = setup_rank_by_consulting
        @unplaced_students = @rank_by_consulting.dup
        @teams = []
        @unplaced_team = {:consultant_id => nil, :objective_id => nil, :bracket => 1, :user_ids => []}
    end
    
    def setup_after_rbc
        refresh_all_objective_seminars_for_testing
        @obj_sems = setup_obj_sems_hash
        @need_hash = setup_need_hash
        @objectives = get_objectives
        @need_hash = setup_need_hash
        @score_hash = setup_score_hash
    end
    
    def set_priority(obj, priority)
        ObjectiveSeminar.find_by(:objective => obj, :seminar => @seminar).update(:priority => priority)
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
    
    def all_consultants_are_qualified
        @teams.each do |team|
            consultant = team[:consultant_id]
            if consultant.present?
                this_score = @score_hash.detect{|x|
                    x[:obj] == team[:objective_id] &&
                    x[:user] == consultant
                }
                assert this_score[:points] >= 4
            end
        end
    end
    
    def test_all_apprentices
        @consultancy.teams.each do |team|
            team.users.each do |member|
                unless member == team.consultant
                    assert member.score_on(team.objective) <= 4
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
    
    test "rank by consulting" do
        #Tests that students are placed in order by last consultant day.  And also that absent students are not included.
        
        @ss_5.update(:present => true)
        @ss_6.update(:present => false)
        
        set_date = Date.today - 80.days
        set_date_2 = Date.today - 20.days
        other_days = Date.today - 40.days
        
        SeminarStudent.all.update_all(:last_consultant_day => other_days)
        
        @student_41 = @seminar.students.create(:first_name => "Marko", :last_name => "Zivkovic", :type => "Student", :password_digest => "password")
        @ss_41 = SeminarStudent.find_by(:user => @student_41, :seminar => @seminar)
        assert_equal Date.today, @ss_41.last_consultant_day
        
        @ss_1.update(:last_consultant_day => set_date)
        @ss_2.update(:last_consultant_day => set_date_2)
        @seminar.seminar_students.each do |ss|
            ss.reload
        end
        
        @sem_studs_hash = setup_sem_studs_hash
        @rank_by_consulting = setup_rank_by_consulting
        
        assert @rank_by_consulting.include?(@student_5.id)
        assert_not @rank_by_consulting.include?(@student_6.id)

        assert_equal @student_1.id, @rank_by_consulting[0]
        assert_equal @student_41.id, @rank_by_consulting[-1]
        assert_equal @student_2.id, @rank_by_consulting[-2]
    end
    
    test "rank objectives" do
        # Objectives should be sorted by priority
        set_priority(@objective_40, 5)
        set_priority(@objective_50, 0)
        
        @obj_sems = setup_obj_sems_hash
        @objectives = get_objectives
        
        assert_equal @objective_40.id, @objectives[0]
        assert_not @objectives.include?(@objective_50.id)
    end
    
    test "choose consultants" do
        setup_before_rbc
        
        @rbc_0 = @rank_by_consulting[0]
        @rbc_1 = @rank_by_consulting[1]
        @rbc_2 = @rank_by_consulting[2]
        @rbc_3 = @rank_by_consulting[3]
        @rbc_last = @rank_by_consulting[-1]
        @rbc_0_stud = Student.find(@rbc_0)
        this_stud_3 = Student.find(@rbc_3)
        @rbc_last_stud = Student.find(@rbc_last)
        
        # Make sure there is need for some consultants
        these_obj_studs = @seminar.obj_studs_for_seminar
        12.times do |n|
            these_obj_studs[n].update(:points_all_time => 3)
        end
        
        # Last student is the only one qualified for a high-priority objective
        set_priority(@objective_40, 5)
        set_priority(@objective_50, 5)
        ObjectiveStudent.where(:objective => @objective_40).update_all(:points_all_time => 0)
        ObjectiveStudent.where(:objective => @objective_50).update_all(:points_all_time => 0)
        set_specific_score(@rbc_last_stud, @objective_40, 7)
        set_specific_score(this_stud_3, @objective_50, 7)
        
        # Highest student in rank_by_consulting has a teach_request to check for
        requested_objective = @seminar.objectives.detect{|x| x.id != @objective_40.id && x.id != @objective_50.id}
        @rbc_0_ss = SeminarStudent.find_by(:user => @rbc_0, :seminar => @seminar)
        @rbc_0_ss.update(:teach_request => requested_objective.id)
        set_specific_score(@rbc_0_stud, requested_objective, 7)
        
        # Second-highest student is not qualified in anything
        ObjectiveStudent.where(:user => @rbc_1).update_all(:points_all_time => 4)
        
        #Update students needed after scores have been set.
        setup_after_rbc
        
        # No teams before choose_consultants
        assert_equal 0, @teams.count
        
        # Choose Consultants
        choose_consultants
        
        #Several teams exist
        assert @teams.count > 1
        
        #Only consultants are placed so far
        @teams.each do |team|
            assert_equal 1, team[:user_ids].count
            assert_equal team[:consultant_id], team[:user_ids][0]
        end
        
        # Priority #5 assignments are included first
        # And only with a qualified consultant
        rbc_last_stud_team = @teams.detect{|x| x[:consultant_id] == @rbc_last_stud.id}
        assert_not_equal [], rbc_last_stud_team
        assert_equal @objective_40.id, rbc_last_stud_team[:objective_id]
        these_teams = @teams.select{|x| x[:objective_id] == @objective_40.id}
        assert_equal 1, these_teams.count
        
        rbc_3_stud_team = @teams.detect{|x| x[:consultant_id] == this_stud_3.id}
        assert_not_equal [], rbc_3_stud_team
        assert_equal @objective_50.id, rbc_3_stud_team[:objective_id]
        these_teams = @teams.select{|x| x[:objective_id] == @objective_50.id}
        assert_equal 1, these_teams.count
        
        # First student in rank_by_consulting receives her teach_request
        assert_equal requested_objective.id,
            @teams.detect{|x| x[:consultant_id] == @rbc_0}[:objective_id]
        
        # Second student in rank_by_consulting gets skipped because she's unqualified
        assert_not @teams.any? {|x| x[:user_ids].include?(@rbc_1)}
        assert @teams.any? {|x| x[:user_ids].include?(@rbc_2)}
        
        all_consultants_are_qualified
    end

    # BEST CONSULTANTS SERIES OF TESTS
    # Tests the list ordering for a priority 5 objective

    def best_consultants_setup
        setup_before_rbc
        @rbc_0 = @rank_by_consulting[0]
        @rbc_1 = @rank_by_consulting[1]
        @rbc_2 = @rank_by_consulting[2]
        @rbc_3 = @rank_by_consulting[3]
        @rbc_0_stud = Student.find(@rbc_0)
        @rbc_1_stud = Student.find(@rbc_1)
        @rbc_2_stud = Student.find(@rbc_2)
        @rbc_3_stud = Student.find(@rbc_3)
        
        # Set all students unqualified to begin with
        ObjectiveStudent.where(:objective => @objective_40).update_all(:points_all_time => 3)
        
        # Stud_0 already has keys
        ObjectiveStudent.find_by(:objective => @objective_40, :user => @rbc_0_stud).update(:points_all_time => 7, :teacher_granted_keys => 2)
        
        # Stud_1 scored 10
        ObjectiveStudent.find_by(:objective => @objective_40, :user => @rbc_1_stud).update(:points_all_time => 10)
        
        # Stud_2 scored 9
        ObjectiveStudent.find_by(:objective => @objective_40, :user => @rbc_2_stud).update(:points_all_time => 9)
        
        # Stud_3 should normally be first choice
        ObjectiveStudent.find_by(:objective => @objective_40, :user => @rbc_3_stud).update(:points_all_time => 7)
        
        # Make sure these students have no teach_request
        [@rbc_0_stud, @rbc_1_stud, @rbc_2_stud, @rbc_3_stud].each do |stud|
            SeminarStudent.find_by(:seminar => @seminar, :user => stud).update(:teach_request => nil)
        end
        
        # Set @objective_40 to priority 5
        set_priority(@objective_40, 5)
    end
        
    test "best consultants 1" do
        best_consultants_setup
        
        setup_after_rbc
        choose_consultants
        
        # Stud_3 is chosen first
        assert_equal [@rbc_3, @rbc_2, @rbc_1, @rbc_0],
            @teams[0..3].map{|x| x[:consultant_id]}
    end

    test "best consultants 2" do
        best_consultants_setup
        
        # Give keys to Stud_3
        [@rbc_3_stud].each do |stud|
            ObjectiveStudent.find_by(:objective => @objective_40, :user => stud).update(:teacher_granted_keys => 2)
        end
        
        setup_after_rbc
        choose_consultants
        
        # Stud_2 is chosen first
        assert_equal [@rbc_2, @rbc_1, @rbc_0, @rbc_3],
            @teams[0..3].map{|x| x[:consultant_id]}
    end

    test "best consultants 3" do
        best_consultants_setup
        
        # Give keys to Stud_2 and Stud_3
        [@rbc_2_stud, @rbc_3_stud].each do |stud|
            ObjectiveStudent.find_by(:objective => @objective_40, :user => stud).update(:teacher_granted_keys => 2)
        end
        
        setup_after_rbc
        choose_consultants
        
        # Stud_1 is chosen first
        # Stud_3 is chosen first
        assert_equal [@rbc_1, @rbc_0, @rbc_2, @rbc_3],
            @teams[0..3].map{|x| x[:consultant_id]}
    end

    test "best consultants 4" do
        best_consultants_setup
        
        # Give keys to Stud_1, Stud_2, and Stud_3
        [@rbc_1_stud, @rbc_2_stud, @rbc_3_stud].each do |stud|
            ObjectiveStudent.find_by(:objective => @objective_40, :user => stud).update(:teacher_granted_keys => 2)
        end
        
        setup_after_rbc
        choose_consultants
        
        # Stud_0 is chosen first
        # Stud_3 is chosen first
        assert_equal [@rbc_0, @rbc_1, @rbc_2, @rbc_3],
            @teams[0..3].map{|x| x[:consultant_id]}
    end

    test "best consultants rbc" do
        # If all scores are ideal and no keys are present, first choice is rbc_0
        best_consultants_setup
        
        [@rbc_0_stud, @rbc_1_stud, @rbc_2_stud, @rbc_3_stud].each do |stud|
            ObjectiveStudent.find_by(:objective => @objective_40, :user => stud).update(:teacher_granted_keys => 0, :points_all_time => 7)
        end
        
        setup_after_rbc
        choose_consultants
        
        # Stud_0 is chosen first
        assert_equal [@rbc_0, @rbc_1, @rbc_2, @rbc_3],
            @teams[0..3].map{|x| x[:consultant_id]}
    end

    test "number of groups" do
        # Only make one group for an objective if that's all the class needs
        @this_obj = @seminar.objectives.detect{|x| x.preassigns.count == 0}
        
        set_priority(@this_obj, 5)
        
        # Set all to qualified except three
        first_three_studs = @seminar.students[0..2]
        other_studs = @seminar.students - first_three_studs
        ObjectiveStudent.where(:objective => @this_obj, :user => other_studs).update_all(:points_all_time => 7)
        ObjectiveStudent.where(:objective => @this_obj, :user => first_three_studs).update_all(:points_all_time => 3)
        refresh_all_objective_seminars_for_testing
        
        setup_before_rbc
        setup_after_rbc
        choose_consultants
        
        assert_equal 1, @teams.select{|x| x[:objective_id] == @this_obj.id}.count
    end

    test "number of groups part 2" do
        # Make two groups for an objective if the class needs
        @this_obj = @seminar.objectives.detect{|x| x.preassigns.count == 0}
        
        set_priority(@this_obj, 5)
        
        # Set all to qualified except three
        first_eight_studs = @seminar.students[0..7]
        other_studs = @seminar.students - first_eight_studs
        ObjectiveStudent.where(:objective => @this_obj, :user => other_studs).update_all(:points_all_time => 7)
        ObjectiveStudent.where(:objective => @this_obj, :user => first_eight_studs).update_all(:points_all_time => 3)
        refresh_all_objective_seminars_for_testing
        
        setup_before_rbc
        setup_after_rbc
        choose_consultants
        
        assert_equal 2, @teams.select{|x| x[:objective_id] == @this_obj.id}.count
    end

    test "regular priority topic with keys" do
        # If an objective is regular priority, but the only qualified student already has keys, then skip that objective
        
        setup_before_rbc
        
        ObjectiveStudent.where(:objective => @objective_40, :user => @seminar.students).update_all(:points_all_time => 0)
        @rbc_0 = @rank_by_consulting[0]
        @rbc_0_stud = Student.find(@rbc_0)
        @rbc_0_stud.objective_students.update_all(:points_all_time => 0)
        ObjectiveStudent.find_by(:objective => @objective_40, :user => @rbc_0_stud).update(:points_all_time => 7, :dc_keys => 2)
        setup_after_rbc
        choose_consultants
        
        assert_equal 0, @teams.select{|x| x[:objective_id] == @objective_40.id}.count
    end

    test "regular priority topic without keys" do
        # Counterpart to 'regular priority topic with keys'
        # Take away the keys, and that objective is included
        
        setup_before_rbc
        
        ObjectiveStudent.where(:objective => @objective_40, :user => @seminar.students).update_all(:points_all_time => 0)
        @rbc_0 = @rank_by_consulting[0]
        @rbc_0_stud = Student.find(@rbc_0)
        @rbc_0_stud.objective_students.update_all(:points_all_time => 0)
        ObjectiveStudent.find_by(:objective => @objective_40, :user => @rbc_0_stud).update(:points_all_time => 7, :dc_keys => 0)
        setup_after_rbc
        choose_consultants
        
        assert_equal 1, @teams.select{|x| x[:objective_id] == @objective_40.id}.count
    end

    test "place apprentices by request" do
        request_obj = Objective.find(@ss_6.learn_request)
        assert_not_nil request_obj
        set_priority(request_obj, 5)
        ObjectiveStudent.find_by(:objective => request_obj, :user => @student_2).update(:points_all_time => 7, :teacher_granted_keys => 0, :pretest_keys => 0, :dc_keys => 0)
        
        # Make sure @student_6 doesn't get picked as consultant
        @student_6.objective_students.update_all(:points_all_time => 0)
        make_ready(@student_6, request_obj)
        
        setup_before_rbc
        setup_after_rbc
        choose_consultants
        
        all_consultants_are_qualified  # This is tested earlier, but I also wanted to test consultants with a less-contrived setup.
        place_apprentices_by_requests
        test_all_apprentices
        
        # Students who had a request available received their request.
        assert_equal request_obj.id, @teams.detect{|x| x[:user_ids].include?(@student_6.id)}[:objective_id]
    end

    test "no request if already keys" do
        # But if the student already has keys, she doesn't get her request
        
        request_obj = Objective.find(@ss_6.learn_request)
        assert_not_nil request_obj
        set_priority(request_obj, 5)
        ObjectiveStudent.find_by(:objective => request_obj, :user => @student_2).update(:points_all_time => 7, :teacher_granted_keys => 0, :pretest_keys => 0, :dc_keys => 0)
        ObjectiveStudent.find_by(:objective => request_obj, :user => @student_6).update(:dc_keys => 2)
        
        # Make sure @student_6 doesn't get picked as consultant
        @student_6.objective_students.update_all(:points_all_time => 0)
        make_ready(@student_6, request_obj)
        
        setup_before_rbc
        setup_after_rbc
        choose_consultants
        
        all_consultants_are_qualified  # This is tested earlier, but I also wanted to test consultants with a less-contrived setup.
        place_apprentices_by_requests
        test_all_apprentices
        
        # Students didn't receive request because she had keys
        assert_nil @teams.detect{|x| x[:user_ids].include?(@student_6.id)}
    end

    test "place apprentices by mastery" do
        setup_before_rbc
        setup_after_rbc
        choose_consultants
        place_apprentices_by_requests
        
        # The method places some students
        old_full_team_count = @teams.select{|x| x[:user_ids].count > 1}.count
        
        # Here's the main function for this test
        place_apprentices_by_mastery
        
        # All apprentices are non-proficient, but ready for the team's objective
        # it could also be that student's learn request
        @teams.each do |team|
            team[:user_ids].reject{|x| x == team[:consultant_id]}.each do |stud|
                this_obj_stud = ObjectiveStudent.find_by(:objective => team[:objective_id], :user_id => stud)
                this_stud_fits = this_obj_stud.points_all_time.to_i < 6 || this_obj_stud.user.seminar_students.find_by(:seminar => @seminar).learn_request == team[:objective_id]
                assert this_stud_fits
            end
        end
        
        # Assert that more teams have been created
        assert @teams.select{|x| x[:user_ids].count > 1}.count > old_full_team_count
        
        # Even with random scores, student_5 should still be unplaced
        assert @unplaced_students.count > 0
        
        # Unplaced students are proficent everywhere there's room
        teams_with_room = @teams.select{|x| x[:user_ids].count < 4}
        @unplaced_students.each do |stud|
            teams_with_room.each do |team|
                obj_stud = ObjectiveStudent.find_by(:objective => team[:objective_id], :user_id => stud)
                assert !obj_stud.ready || obj_stud.points_all_time.to_i > 5
            end
        end
        
        # No teams have more than four members
        @teams.each do |team|
            assert team[:user_ids].count <= 4
        end
        
        # No student placed more than once
        @seminar.students.each do |student|
            teams_with_stud = @teams.select{|x| x[:user_ids].include?(student.id)}
            assert teams_with_stud.count < 2
        end
    end

    test "check for lone students" do
        obj_id = Objective.first.id
        
        stud_id_0 = Student.all[0].id
        team_1 = {:consultant=> stud_id_0, :obj=> obj_id, :user_ids=> [stud_id_0]}
        
        stud_id_1 = Student.all[1].id
        stud_id_2 = Student.all[2].id
        team_2 = {:consultant=> stud_id_1, :obj=> obj_id, :user_ids=> [stud_id_1, stud_id_2]}
        
        stud_id_3 = Student.all[3].id
        @unplaced_students = [stud_id_3]
        
        @teams = [team_1, team_2]
        
        # Main function for this test
        check_for_lone_students
        
        # Unplaced Students grows, but teams shrinks
        assert_equal [stud_id_3, stud_id_0], @unplaced_students
        assert_equal [team_2], @teams
    end

    # Home for the second student, who starts a new group with her learn_request
    # Home for the fourth student, who starts a new group with her first learn_option

    # One student is placed in an existing group
    # Another student receives her learn_request
    # Third student is placed in that newly-created group
    # Fourth student starts a new group with her first learn option (Because she has no learn request.)
    # Last student is still unplaced

    test "new place for lone students" do
        # Also checks the are_some_unplaced method
        
        # Student_11 is ready for @objective_40
        this_obj_stud = ObjectiveStudent.find_by(:objective => @objective_40, :user => @student_11)
        this_obj_stud.update(:points_all_time => 0, :teacher_granted_keys => 0, :dc_keys => 0, :pretest_keys => 0, :ready => true)
        
        # Student_12 has passed all objectives used so far.
        set_specific_score(@student_12, @objective_40, 9)
        set_specific_score(@student_12, @objective_50, 3)
        SeminarStudent.find_by(:seminar => @seminar, :user => @student_12).update(:learn_request => @objective_50.id)
        
        # Student_13 has passed all except Student_12's request
        set_specific_score(@student_13, @objective_40, 9)
        set_specific_score(@student_13, @objective_50, 3)
        
        # Student_14 has passed those and has no request
        set_specific_score(@student_14, @objective_40, 9)
        set_specific_score(@student_14, @objective_50, 9)
            # Set priority to 5 to make it appear first for student_14
        ObjectiveSeminar.find_by(:objective => @own_assign, :seminar => @seminar).update(:priority => 5)
        SeminarStudent.find_by(:seminar => @seminar, :user => @student_14).update(:learn_request => nil)
        ObjectiveStudent.find_by(:objective => @own_assign, :user => @student_14).update(:points_all_time => 0, :teacher_granted_keys => 0, :dc_keys => 0, :pretest_keys => 0)
        
        # Student_15 has keys in everything
        ObjectiveStudent.where(:user => @student_15).update_all(:teacher_granted_keys => 2)
        
        # Student_16 has passed all but @own_assign
        set_specific_score(@student_16, @objective_40, 9)
        set_specific_score(@student_16, @objective_50, 9)
        SeminarStudent.find_by(:seminar => @seminar, :user => @student_16).update(:learn_request => nil)
        ObjectiveStudent.find_by(:objective => @own_assign, :user => @student_16).update(:points_all_time => 0, :teacher_granted_keys => 0, :dc_keys => 0, :pretest_keys => 0, :ready => true)
        
        setup_before_rbc
        setup_after_rbc
        
        # Home for the first student, who is placed in an existing group
        # We're assuming student was removed from a singleton group in the last round.
        team_0 = {:consultant_id => @student_1.id, :objective_id => @objective_40.id, :user_ids => [@student_1.id, @student_2.id]}
        
        # Assemble the teams and the unplaced Students
        @teams = [team_0]
        @unplaced_students = [@student_16.id, @student_15.id, @student_14.id, @student_13.id, @student_12.id, @student_11.id]
        
        new_place_for_lone_students
        
        # Student_11 has been placed into an existing group
        assert_equal [@student_1.id, @student_2.id, @student_11.id], @teams[0][:user_ids]
        
        # Student_12 started a new group with her learn_request
        # Student_13 is placed into Student_12's group
        team_1 = {:consultant_id => nil, :objective_id => @objective_50.id, :user_ids => [@student_12.id, @student_13.id]}
        assert_equal team_1, @teams[1]
        
        # Student_14 starts a new group with her highest learn_option
        # Student_16 is placed into this group
        team_2 = {:consultant_id => nil, :objective_id => @own_assign.id, :user_ids => [@student_14.id, @student_16.id]}
        assert_equal team_2, @teams[2]
        
        # Student_15 is still unplaced
        team_3 = {:consultant_id => nil, :objective_id => nil, :bracket => 1, :user_ids => [@student_15.id]}
        assert_equal team_3, @unplaced_team
    end

    test "create consultancy" do
        old_consultancy_count = Consultancy.count
        old_team_count = Team.count
        
        setup_before_rbc
        
        team_0 = {:consultant_id => @student_1.id, :objective_id => @objective_40.id, :user_ids => [@student_1.id, @student_2.id, @student_3.id]}
        team_1 = {:consultant_id => @student_4.id, :objective_id => @objective_50.id, :user_ids => [@student_4.id, @student_5.id]}
        team_2 = {:consultant_id => nil, :objective_id => @own_assign.id, :user_ids => [@student_6.id, @student_7.id]}
        team_3 = {:consultant_id => @student_8.id, :objective_id => @objective_40.id, :user_ids => [@student_8.id]}
        @unplaced_team = {:consultant_id => nil, :objective_id => nil, :bracket => 1, :user_ids => [@student_9.id, @student_10.id]}
        @teams = [team_0, team_1, team_2, team_3]
        
        create_consultancy
        
        assert_equal old_consultancy_count + 1, Consultancy.count
        assert_equal old_team_count + 5, Team.count
        
        new_consultancy = Consultancy.order(:created_at).last
        assert_equal @seminar, new_consultancy.seminar
        assert_equal "preview", new_consultancy.duration
        
        last_team = Team.order(:created_at).last
        
        assert_equal new_consultancy, last_team.consultancy
        assert new_consultancy.teams.include?(last_team)
        assert_nil last_team.consultant
        assert_nil last_team.objective
        assert_equal 1, last_team.bracket
        
        team_neg_2 = Team.order(:created_at)[-2]
        assert_equal new_consultancy, team_neg_2.consultancy
        assert new_consultancy.teams.include?(team_neg_2)
        assert_equal @student_8, team_neg_2.consultant
        assert_equal @objective_40, team_neg_2.objective
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
