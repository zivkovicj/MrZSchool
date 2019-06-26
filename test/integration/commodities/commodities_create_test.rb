require 'test_helper'

class CommoditiesCreateTest < ActionDispatch::IntegrationTest
    
    include CommoditiesHelper
    
    def setup
        setup_users
        setup_schools
        
        @old_commodity_count = Commodity.count
    end
    
    def assert_returned_to_market
        assert_no_selector('h2', :text => "New Item")
        assert_selector('h2', :text => "#{@teacher_1.name_with_title} Market")
    end
    
    def go_to_new_commodity_page
        click_on("manage_teacher_market")
        click_on("Create a New Item")
    end
    
    
    
    test "create teacher commodity" do
        capybara_login(@teacher_1)
        go_to_new_commodity_page
        
        fill_in("commodity[name]", :with => "Teacher Salad")
        fill_in("commodity[current_price]", :with => 7)
        fill_in("commodity[quantity]", :with => 99)
        choose("salable_true")
        choose("deliverable_false")
        
        click_on("Create a New Item")
        
        assert_returned_to_market
        
        assert_equal @old_commodity_count + 1, Commodity.count
        
        @commodity = Commodity.last
        assert_equal "Teacher Salad", @commodity.name
        assert_nil @commodity.school_id
        assert_equal @teacher_1, @commodity.user
        assert_equal 7, @commodity.current_price
        assert_equal 99, @commodity.quantity
        assert_not @commodity.deliverable
        assert @commodity.salable
        assert_not @commodity.usable
    end
    
    test "deliverable not salable on create" do
        capybara_login(@teacher_1)
        go_to_new_commodity_page
        
        fill_in("commodity[name]", :with => "Deliverable but not salable item")
        choose("salable_true")
        choose("deliverable_true")
        
        click_on("Create a New Item")
        
        assert_returned_to_market
        
        @commodity = Commodity.last
        assert @commodity.deliverable
        assert_not @commodity.salable
    end
    
    test "default commodity values" do
        capybara_login(@teacher_1)
        go_to_new_commodity_page
        
        fill_in("commodity[name]", :with => "Burger Salad")
        
        click_on("Create a New Item")
        
        assert_equal @old_commodity_count + 1, Commodity.count
        
        @commodity = Commodity.last
        assert_equal "Burger Salad", @commodity.name
        assert_nil @commodity.school
        assert_equal 1, @commodity.current_price
        assert_equal 10, @commodity.quantity
        assert_equal @teacher_1, @commodity.user
    end
    
    test "commodity must have name" do
        capybara_login(@teacher_1)
        go_to_new_commodity_page
        
        fill_in("commodity[current_price]", :with => 6)
        fill_in("commodity[quantity]", :with => 95)
        
        click_on("Create a New Item")
        
        assert_equal @old_commodity_count, Commodity.count
        assert_selector('h2', :text => "New Item")
    end
    
    test "new item button showing for personal market" do
        @other_teacher.update(:school_admin => 0)
        capybara_login(@other_teacher)
        
        click_on("Manage #{@other_teacher.name_with_title} Market")
        
        assert_text("Create a New Item")
    end
    
    test "no item screen for non admin" do
        @teacher_1.update(:school_admin => 0)
        
        capybara_login(@teacher_1)
        visit("/commodities/new")
        
        assert_no_selector('h2', :text => "New Item")
        assert_selector('p', :text => "New to Mr. Z School?")
    end
    
end