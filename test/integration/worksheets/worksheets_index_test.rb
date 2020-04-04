require 'test_helper'

class WorksheetsIndexTest < ActionDispatch::IntegrationTest

    def setup
        setup_users
        setup_worksheets
        
        @worksheet_1.update(:extent => "private", :user => @admin_user)
        @worksheet_2.update(:extent => "public", :user => @admin_user)
        @worksheet_3.update(:extent => "private", :user => @teacher_1)
    end

    test "files index for admin" do
        # Admin can see all files
        # And also delete buttons
    
        capybara_login(@admin_user)
        click_on("Home")
        click_on("Materials")
    
        assert_selector("td", :text => "#{@worksheet_1.name}")
        assert_selector("td", :text => "#{@worksheet_2.name}")
        assert_selector("td", :text => "#{@worksheet_3.name}")
        assert_selector("h5", :id => "delete_#{@worksheet_1.id}")
        assert_selector("h5", :id => "delete_#{@worksheet_2.id}")
        assert_selector("h5", :id => "delete_#{@worksheet_3.id}")
        
        # Individual page leads to edit instead of show
        click_on("#{@worksheet_2.name}")
        assert_selector("input", :id => "worksheet_name")
        assert_selector("input", :id => "download_#{@worksheet_2.id}")
        
        # Back button goes to index, then Admin Page
        click_on("All Files")
        assert_selector("h2", :text => "All Files")
        click_on("Admin Page")
        assert_on_admin_page
    end

    test "files index for non login" do
        # Somebody who browsed to the files index but didn't log in
        
        visit('/')
        click_on('Materials')
        
        # They cannot see files that are marked as extent => false
        # And they cannot see the delete buttons
        assert_no_selector("td", :text => "#{@worksheet_1.name}")
        assert_selector("td", :text => "#{@worksheet_2.name}")
        assert_no_selector("td", :text => "#{@worksheet_3.name}")
        assert_no_selector("h5", :id => "delete_#{@worksheet_1.id}")
        assert_no_selector("h5", :id => "delete_#{@worksheet_2.id}")
        assert_no_selector("h5", :id => "delete_#{@worksheet_3.id}")
        
        # On Index Page
        assert_selector("h2", :text => "All Files")
        assert_no_selector("h2", :text => @worksheet_2.name)
        
        # Go to individual page
        click_on("#{@worksheet_2.name}")
        assert_no_selector("h2", :text => @worksheet_1.name)
        assert_selector("h2", :text => @worksheet_2.name)
        
         # Individual page leads to show instead of edit
        assert_no_selector("input", :id => "worksheet_name")
        assert_selector("input", :id => "download_#{@worksheet_2.id}")
        
        # Back to Index
        click_on("All Files")
        
        assert_selector("h2", :text => "All Files")
        assert_no_selector("h2", :text => @worksheet_2.name)
    end

    test "files for teacher" do
        # A teacher can see her own files and delete them
        
        capybara_login(@teacher_1)
        click_on("Home")
        click_on("Materials")
        
        assert_no_selector("td", :text => "#{@worksheet_1.name}")
        assert_selector("td", :text => "#{@worksheet_2.name}")
        assert_selector("td", :text => "#{@worksheet_3.name}")
        assert_no_selector("h5", :id => "delete_#{@worksheet_1.id}")
        assert_no_selector("h5", :id => "delete_#{@worksheet_2.id}")
        assert_selector("h5", :id => "delete_#{@worksheet_3.id}")
        
        # Go to individual page
        click_on("#{@worksheet_2.name}")
        assert_no_selector("h2", :text => @worksheet_1.name)
        assert_selector("h2", :text => @worksheet_2.name)
        
        # Individual page leads to show instead of edit
        # But there is the capability to download the file
        assert_no_selector("input", :id => "worksheet_name")
        assert_selector("input", :id => "download_#{@worksheet_2.id}")
        
        # Back button goes to index, then teacher profile Page
        click_on("All Files")
        assert_selector("h2", :text => "All Files")
        click_on("Profile")
        assert_selector('p', :text => "Teacher Since:")
    end

    test "files for student" do
        # Same privilges as a non_login
        
        capybara_login(@student_2)
        click_on("Home")
        click_on("Materials")
        
        assert_no_selector("td", :text => "#{@worksheet_1.name}")
        assert_selector("td", :text => "#{@worksheet_2.name}")
        assert_no_selector("td", :text => "#{@worksheet_3.name}")
        assert_no_selector("h5", :id => "delete_#{@worksheet_1.id}")
        assert_no_selector("h5", :id => "delete_#{@worksheet_2.id}")
        assert_no_selector("h5", :id => "delete_#{@worksheet_3.id}")
        
        # Go to individual page
        click_on("#{@worksheet_2.name}")
        assert_no_selector("h2", :text => @worksheet_1.name)
        assert_selector("h2", :text => @worksheet_2.name)
        
        ## Individual page leads to show instead of edit
        # But there is the capability to download the file
        assert_no_selector("input", :id => "worksheet_name")
        assert_selector("input", :id => "download_#{@worksheet_2.id}")
        
        # Back button goes to index, then teacher profile Page
        click_on("All Files")
        assert_selector("h2", :text => "All Files")
        click_on("Profile")
        assert_selector('h3', :text => "Your Classes")
    end
end
