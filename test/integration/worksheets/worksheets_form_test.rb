require 'test_helper'

class WorksheetsNewTest < ActionDispatch::IntegrationTest

    def setup
        setup_users
    end

    test "new worksheet while attaching" do
        this_obj = @teacher_1.objectives.first
        old_worksheet_count = Worksheet.count
        
        capybara_login(@teacher_1)
        click_on("View/Create Content")
        click_on("All Objectives")
        click_on(this_obj.name)
        click_on("Files")
        
        fill_in("worksheet[name]", :with => "Brand Spankin New Worksheet")
        attach_file("worksheet[uploaded_file]", Rails.root + 'app/assets/worksheets/Test File for Objective Worksheets.docx')
        click_on ("Create File")
        
        assert_equal old_worksheet_count + 1, Worksheet.count
        @new_worksheet = Worksheet.last
        assert_equal "Brand Spankin New Worksheet", @new_worksheet.name
        assert this_obj.reload.worksheets.include?(@new_worksheet)
        assert @new_worksheet.objectives.include?(this_obj)
        assert_equal @teacher_1, @new_worksheet.user
        
        
        assert_no_selector('h2', :text => "New Worksheet")
        assert_no_selector('div', :id => "error_explanation")
        assert_text("File Successfully Uploaded")
        assert_text(this_obj.name)
    end
    
    test "new worksheet without attaching" do
        old_worksheet_count = Worksheet.count
        
        capybara_login(@teacher_1)
        click_on("View/Create Content")
        click_on("Upload File")
        
        fill_in("worksheet[name]", :with => "Newest Worksheet")
        attach_file("worksheet[uploaded_file]", Rails.root + 'app/assets/worksheets/Test File for Objective Worksheets.docx')
        click_on ("Create File")
        
        assert_equal old_worksheet_count + 1, Worksheet.count
        @new_worksheet = Worksheet.last
        assert_equal "Newest Worksheet", @new_worksheet.name
        assert_equal @teacher_1, @new_worksheet.user
        assert @new_worksheet.objectives.empty?
        
        assert_no_selector('h2', :text => "New Worksheet")
        assert_no_selector('div', :id => "error_explanation")
        assert_text("File Successfully Uploaded")
        assert_text("Teacher Since:")
    end

    test "edit worksheet" do
        setup_worksheets
        
        @worksheet_2.update(:extent => "private")
        
        capybara_login(@admin_user)
        click_on("Home")
        click_on("Materials")
        click_on("#{@worksheet_2.name}")
        
        fill_in "worksheet[name]", :with => "Beef blaster"
        fill_in "worksheet[description]", :with => "This is the new description"
        find("#public_worksheet").choose
        attach_file("worksheet[uploaded_file]", Rails.root + 'app/assets/worksheets/Test File for Objective Worksheets.docx')
        click_on "Update File"
        
        @worksheet_2.reload
        assert_equal "Beef blaster", @worksheet_2.name
        assert_equal "public", @worksheet_2.extent
        assert_equal "This is the new description", @worksheet_2.description
        
        assert_selector("h2", :text => "All Files")
    end

    test "edit worksheet back button" do
        setup_worksheets
        
        capybara_login(@admin_user)
        click_on("Home")
        click_on("Materials")
        click_on("#{@worksheet_2.name}")
        
        click_on("All Files")
        
        assert_selector("h2", :text => "All Files")
    end
    
end
