require 'test_helper'

class SeminarTeachersInviteTest < ActionDispatch::IntegrationTest
    
    include UsersHelper
    
    def setup
        setup_users
        setup_schools
        setup_seminars
        @old_st_count = SeminarTeacher.count
    end
    
    def go_to_invite_screen
        go_to_seminar
        click_on("Shared Teachers")
    end
    
    def send_the_invite
        find("#invite_teacher_#{@other_teacher.id}").click
    end
    
    def set_new_seminar_teacher
        @st_2 = SeminarTeacher.find_by(:seminar => @seminar, :user => @other_teacher)
    end
    
    def send_another_invite
        find("#home_link_top").click
        click_on("Your profile")
        click_on("seminar_#{@seminar_2.id}")
        click_on("Shared Teachers")
        find("#invite_teacher_#{@other_teacher.id}").click
        @st_3 = SeminarTeacher.find_by(:seminar => @seminar_2, :user => @other_teacher)
    end
    
    test "send invites" do
        assert @teacher_1.school.teachers.include?(@other_teacher)
        assert @teacher_1.seminar_teachers.find_by(:seminar => @seminar).can_edit
        assert_not SeminarTeacher.find_by(:seminar => @seminar, :user => @other_teacher)
        
        capybara_login(@teacher_1)
        go_to_invite_screen
        
        # Buttons don't appear for a teacher to invite herself
        assert_selector('a', :id => "invite_teacher_#{@other_teacher.id}")
        assert_no_selector('a', :id => "invite_teacher_#{@teacher_1.id}")
        
        send_the_invite
        set_new_seminar_teacher
        
        assert_selector('a', :id => "give_edit_privileges_#{@other_teacher.id}")
        assert_no_selector('a', :id => "give_edit_privileges_#{@teacher_1.id}")
    
        # Can't invite unverified teacher
        assert_no_selector('a', :id => "invite_teacher_#{@unverified_teacher.id}")
        
        assert_equal @old_st_count + 1, SeminarTeacher.count
        assert_not @st_2.can_edit
        assert_not @st_2.accepted
    end
    
    test "invite and accept" do
        capybara_login(@teacher_1)
        go_to_invite_screen
        send_the_invite
        set_new_seminar_teacher
        click_on("Log out")
        
        capybara_login(@other_teacher)
        assert_no_selector("a", :id => "scoresheet_seminar_#{@seminar.id}")
        find("#accept_invites").click
        click_on("accept_#{@st_2.id}")
        
        @st_2.reload
        assert @st_2.accepted
        assert_not @st_2.can_edit
        
        assert_text("Teacher Since:")
        assert_selector("a", :id => "scoresheet_seminar_#{@seminar.id}")
    end
    
    test "invite and decline" do
        capybara_login(@teacher_1)
        go_to_invite_screen
        send_the_invite
        set_new_seminar_teacher
        click_on("Log out")
        
        capybara_login(@other_teacher)
        assert_no_selector("a", :id => "scoresheet_seminar_#{@seminar.id}")
        find("#accept_invites").click
        click_on("decline_#{@st_2.id}")
        
        assert_not SeminarTeacher.find_by(:seminar => @seminar, :user => @other_teacher)
        assert_equal @old_st_count, SeminarTeacher.count
        assert_text("Teacher Since:")
        assert_no_selector("a", :id => "scoresheet_seminar_#{@seminar.id}")
    end
    
    test "more invites to accept" do
        capybara_login(@teacher_1)
        go_to_invite_screen
        send_the_invite
        set_new_seminar_teacher
        send_another_invite
        click_on("Log out")
        
        capybara_login(@other_teacher)
        find("#accept_invites").click
        click_on("accept_#{@st_2.id}")
        
        assert_no_text("Teacher Since:")
        assert_selector("h2", :text => "Accept Invitations")
        
        click_on("accept_#{@st_3.id}")
        
        assert_text("Teacher Since:")
        assert_no_selector("h2", :text => "Accept Invitations")
    end
    
    test "more invites to decline" do
        capybara_login(@teacher_1)
        go_to_invite_screen
        send_the_invite
        set_new_seminar_teacher
        send_another_invite
        click_on("Log out")
        
        capybara_login(@other_teacher)
        find("#accept_invites").click
        click_on("decline_#{@st_2.id}")
        
        assert_no_text("Teacher Since:")
        assert_selector("h2", :text => "Accept Invitations")
        
        click_on("decline_#{@st_3.id}")
        
        assert_text("Teacher Since:")
        assert_no_selector("h2", :text => "Accept Invitations")
    end
    
    test "cannot invite without edit privileges" do
        @teacher_3.update(:verified => 1)
        
        capybara_login(@teacher_1)
        click_on("seminar_#{@avcne_seminar.id}")
        click_on("Shared Teachers")
        assert_no_selector('a', :id => "invite_teacher_#{@teacher_3.id}")
    end
    
    test "give edit privileges" do
        @st_2 = SeminarTeacher.create(:user => @other_teacher, :seminar => @seminar)
        assert_equal false, @st_2.can_edit
        
        capybara_login(@teacher_1)
        go_to_seminar
        click_on("Shared Teachers")
        click_on("give_edit_privileges_#{@other_teacher.id}")
        
        @st_2.reload
        assert @st_2.can_edit
        
        click_on("stop_edit_privileges_#{@other_teacher.id}")
        
        @st_2.reload
        assert_not @st_2.can_edit
    end
    
    test "make owner" do
        @st_2 = SeminarTeacher.create(:user => @other_teacher, :seminar => @seminar)
        assert_not @st_2.can_edit
        assert_equal @teacher_1, @seminar.owner
        
        capybara_login(@teacher_1)
        go_to_seminar
        click_on("Shared Teachers")
        
        click_on("make_owner_#{@other_teacher.id}")
        
        @seminar.reload
        @st_2.reload
        assert_equal @other_teacher, @seminar.owner
        assert @st_2.can_edit
    end
    
    test "remove teacher" do
        @st_2 = SeminarTeacher.create(:user => @other_teacher, :seminar => @seminar)
        @st_3 = SeminarTeacher.create(:user => @teacher_3, :seminar => @seminar, :can_edit => true)
        assert @seminar.teachers.include?(@other_teacher)
        
        capybara_login(@teacher_3)  #Log in as second teacher to test appearance of removal button.
        go_to_seminar
        click_on("Shared Teachers")
        
        assert_selector('a', :id => "remove_teacher_#{@other_teacher.id}")
        assert_no_selector('a', :id => "remove_teacher_#{@teacher_1.id}")
        assert_selector('span', :id => "owner_#{@teacher_1.id}")
        
        click_on("remove_teacher_#{@other_teacher.id}")
        
        assert_selector('h2', :text => "Edit #{@seminar.name}")
        assert_not @seminar.teachers.include?(@other_teacher)
    end
    
end