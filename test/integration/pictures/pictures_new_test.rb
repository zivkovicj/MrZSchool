require 'test_helper'

class PicturesNewTest < ActionDispatch::IntegrationTest
    
    def setup
        setup_users
        setup_schools
        setup_labels
        @old_picture_count = Picture.count
    end
    
    #test "has image attached" do
        #pic = pictures(:cheese_logo)
        #assert File.exists?(pic.image.file.path)
    #end
    
    def goto_picture_create
        capybara_login(@teacher_1)
        click_on("View/Create Content")
        click_on("Upload Pictures")
    end
    
    test "uploads an image" do
        pic = Picture.create(:image => fixture_file_upload('/files/DJ.jpg','image/jpg'), :user => User.first, :name => "Test Picture")
        assert(File.exists?(pic.reload.image.file.path))
    end
    
    test "create new picture" do
        goto_picture_create
        fill_in "picture_name", with: "Apple"
        attach_file('picture[image]', Rails.root + 'app/assets/images/apple.jpg')
        debugger
        check("check_#{@user_l.id}")
        check("check_#{@admin_l.id}")
        click_on ("Create Picture")
        
        assert_equal @old_picture_count + 1, Picture.count
        @new_pic = Picture.last
        assert_equal "Apple", @new_pic.name
        assert @new_pic.labels.include?(@user_l)
        assert @new_pic.labels.include?(@admin_l)
        assert @user_l.pictures.include?(@new_pic)
        assert @admin_l.pictures.include?(@new_pic)
        assert @teacher_1, @new_pic.user
        #assert File.exists?(@new_pic.reload.image.file.path)
        
        assert_no_selector('h2', :text => "New Picture")
        assert_no_selector('div', :id => "error_explanation")
        assert_text("Teacher Since:")
    end
    
    test "no picture name" do
        goto_picture_create
        fill_in "picture_name", with: ""
        attach_file('picture[image]', Rails.root + 'app/assets/images/apple.jpg')
        click_on ("Create Picture")
        
        assert_selector('h2', :text => "New Picture")
        assert_selector('div', :id => "error_explanation")
        assert_selector('li', :text => "Name can't be blank")
        assert_no_text("Teacher Since:")
    end
    
    test "no picture file" do
        goto_picture_create
        fill_in "picture_name", with: "Apple"
        click_on ("Create Picture")
        
        assert_selector('h2', :text => "New Picture")
        assert_selector('div', :id => "error_explanation")
        assert_selector('li', :text => "Image can't be blank")
        assert_no_text("Teacher Since:")
    end
    
end