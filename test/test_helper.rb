

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'best_in_place/test_helpers'
require "minitest/reporters"
require 'capybara/rails'
require 'capybara/poltergeist'

Minitest::Reporters.use!

CarrierWave.root = 'test/fixtures/files'

class CarrierWave::Mount::Mounter
  def store!
    # Not storing uploads in the tests
  end
end


class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  
  include ApplicationHelper
  
  include ActionDispatch::TestProcess

  CarrierWave.root = Rails.root.join('test/fixtures/files')
  
  def after_teardown
    super
    CarrierWave.clean_cached_files!(0)
  end
  
  def answer_quiz_randomly
    10.times do
      choose("choice_bubble_1")
      click_on("Next Question")
    end
  end
  
  def create_quiz(student, obj, score)
    student.quizzes.create(:objective => obj, :total_score => score, :origin => "teacher_granted") 
  end
  
  def disable_images
    Question.where.not(:picture_id => nil).update_all(:picture_id => nil) 
  end
  
  def give_a_key
      @test_obj_stud = @objective_10.objective_students.find_by(:user => @student_2)
      @test_obj_stud.update(:teacher_granted_keys => 2, :ready => true)
  end
  
  def go_to_seminar
    click_on("seminar_#{@seminar.id}")
  end
  
  def make_ready(student, objective)
    objective.preassigns.each do |preassign|
      pre_os = ObjectiveStudent.find_or_create_by(:user => student, :objective => preassign)
      pre_os.update(:points_all_time => 7)
    end
    ObjectiveStudent.find_or_create_by(:user => student, :objective => objective).set_ready
  end
  
  def refresh_all_objective_seminars_for_testing
      # Don't mix-up with refresh_all_obj_sems that only looks at a specific seminar
      ObjectiveSeminar.all.each do |obj_sem|
          obj_sem.students_needed_refresh
      end
  end
  
  def search_for(target)
    fill_in "search_field", with: target
    click_on("Search")
  end
  
  def set_ready_all (student)
    student.objective_students.each do |os|
      os.set_ready
    end
  end
  
  def set_specific_score (student, objective, score)
    ObjectiveStudent.find_or_create_by(:user => student, :objective => objective)
    this_quiz = Quiz.find_or_create_by(:user => student, :objective => objective, :origin => "manual_points_all_time")
    if this_quiz.ripostes.count == 0
        3.times do |trip|
            this_quiz.ripostes.create(:question => Question.all[trip])
        end
    end
    this_quiz.update(:total_score => score)
  end
  
  def set_all_scores(category, subject, score)
    ObjectiveStudent.where(category => subject).update_all(:points_all_time => score)
  end
  
  def setup_commodities
    @testing_date_last_produced = "Sat, 16 Jun 2018 00:00:00 UTC +00:00"
    @teacher_1_star = @teacher_1.commodities.first
    @teacher_1_star.update_attribute(:date_last_produced,  @testing_date_last_produced)
    @commodity_2 = Commodity.find_by(:name => "Burger Salad")
    
    @game_time_ticket = commodities(:game_time_ticket)
    @fidget_spinner = Commodity.find_by(:name => "Fidget Spinner")
    @piece_of_candy = Commodity.find_by(:name => "Piece of Candy")
  end
  
  def setup_consultancies
    c1 = seminars(:one).consultancies.create
    t1 = c1.teams.create(:objective => objectives(:objective_10), :consultant => users(:student_2))
    t1.users << users(:student_2)
    t1.users << users(:student_3)
    t1.users << users(:student_4)
    t1.users << users(:student_5)
    
    c2 = seminars(:one).consultancies.create
    t2 = c2.teams.create(:objective => objectives(:objective_20), :consultant => users(:student_3))
    t2.users << users(:student_2)
    t2.users << users(:student_3)
    t2.users << users(:student_4)
    t2.users << users(:student_5)
    
    @consultancy_from_setup = Consultancy.all[-1]
    @other_consultancy = Consultancy.all[-2]
  end
  
  def setup_goals
    Seminar.all.each do |seminar|
      seminar.students.each do |stud|
        4.times do |n|
          term_num = n + 1
          stud.goal_students.create(:seminar_id => seminar.id, :term => term_num)
        end
      end
    end
  end
  
  def setup_objectives
    @objective_10 = objectives(:objective_10)
    @objective_20 = objectives(:objective_20)
    @objective_30 = objectives(:objective_30)
    @objective_40 = objectives(:objective_40)
    @objective_50 = objectives(:objective_50)
    @own_assign = objectives(:objective_60)
    @assign_to_add = objectives(:objective_70)
    @other_teacher_objective = objectives(:objective_160)
  end
  
  def setup_labels
    @unlabeled_l = labels(:unlabeled_label)
    @admin_l = labels(:admin_label)
    @user_l = labels(:user_label)
    @other_l_pub = labels(:other_label_public)
    @other_l_priv = labels(:other_label_private)
    @fill_in_label = labels(:fill_in_label)
    @teacher_graded_l = labels(:teacher_graded_label_1)
    
    Label.all.each do |lab|
        lab.topics << topics(:test_topic)
    end
  end
  
  def setup_questions
    @admin_q = questions(:one)
    @user_q = questions(:two)
    @other_q_pub = questions(:three)
    @other_q_priv = questions(:four)
  end
  
  def setup_pictures
    @admin_p = pictures(:cheese_logo)
    @user_p = pictures(:two)
    @other_p = pictures(:three)
  end
  
  def setup_schools
    @school = @teacher_1.school
    @school.update(:term_dates => School.default_terms, :term => 1)
    @school_2 = schools(:school_2)
    School.all.each do |school|
      school.set_market_and_currency_name
    end
  end
  
  def setup_seminars
    @seminar = seminars(:one)
    @seminar_2 = seminars(:two)
    @seminar_3 = seminars(:three)
    @avcne_seminar = seminars(:archer_can_view_not_edit)
  end
  
  def setup_scores
    Seminar.all.each do |seminar|
      seminar.students.each do |student|
        seminar.objectives.each do |objective|
          rand_score = rand(11)
          student.objective_students.find_or_create_by(:objective => objective,
            :points_all_time => rand_score,
            :points_this_term => rand_score)
        end
      end
    end
  end
  
  def setup_topics
      @roots_topic = topics(:roots)
      @integers_topic = topics(:integers)
      @transformations_topic = topics(:transformations)
  end
  
  def setup_users
    @admin_user = users(:michael)
    @teacher_1 = users(:archer)
    @other_teacher = users(:zacky)
    @unverified_teacher = users(:user_1)
    @teacher_3 = @teacher_1.school.teachers[3]
    
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
    @student_11 = users(:student_11)
    @student_12 = users(:student_12)
    @student_13 = users(:student_13)
    @student_14 = users(:student_14)
    @student_15 = users(:student_15)
    @student_16 = users(:student_16)
    @student_17 = users(:student_17)
    @student_18 = users(:student_18)
    @student_19 = users(:student_19)
    @student_20 = users(:student_20)
    @student_46 = users(:student_46)
    
    @other_school_student = Student.last
    @other_school_student.update(:school => schools(:school_2))
    @student_90 = users(:student_90)
    Student.all[0..70].each do |student|
      student.update(:sponsor => @teacher_1)
    end
    Student.all[71..90].each do |student|
      student.update(:sponsor => @other_teacher)
    end
  end
  
  def setup_worksheets
    @worksheet_1 = worksheets(:one)
    @worksheet_2 = worksheets(:two)
    @worksheet_3 = worksheets(:three)
  end
  
  def travel_to_open_time
      travel_to Time.zone.local(2019, 12, 06, 23, 45, 44)
  end
  
  def is_logged_in?
    !session[:user_id].nil?
  end
  
  def log_in_as(user)
    session[:user_id] = user.id
  end
  
  def assert_on_teacher_page
    assert_text("Teacher Since:")
  end
  
  def assert_not_on_teacher_page
    assert_no_text("Teacher Since:")
  end
  
  def assert_on_admin_page
    assert_text("Admin Control Page")
  end
  
  def assert_not_on_admin_page
    assert_no_text("Admin Control Page")
  end
  
  def capybara_login(user)
    visit('/')
    click_on('Log In')
    fill_in('username', :with => user.username)
    fill_in('Password', :with => 'password')
    click_on('Log In')
  end
  
  def logout
      click_on("Log out")
  end
  
  def go_to_first_period
    capybara_login(@student_2)
    click_on('1st Period')
  end
  
  def go_to_create_student_view
    capybara_login(@teacher_1)
    click_on("seminar_#{@seminar.id}")
    click_on("Basic Info")
    click_on('Create New Students')
  end
  
  def go_to_goals
    click_on("goal_students_#{@seminar.id}")
  end
  
  def teacher_form_stuff(button_text)
    select('Mrs.', :from => 'teacher_title')
    fill_in "teacher_first_name", with: "Burgle"
    fill_in "teacher_last_name", with: "Cut"
    fill_in "teacher_email", with: "Burgle@Cut.com"
    fill_in "teacher_password", with: "bigbigbigbig"
    fill_in "teacher_password_confirmation", with: "bigbigbigbig"
    click_on(button_text)
  end
  
  def teacher_assertions(teacher)
    teacher.reload
    assert_equal "Mrs.", teacher.title
    assert_equal "Burgle", teacher.first_name
    assert_equal "Cut", teacher.last_name
    assert_equal "burgle@cut.com", teacher.email
    assert teacher.authenticate("bigbigbigbig")
  end
  
  def fill_prompt(a)
    fill_in "prompt_#{a}", with: @new_prompt[a]
  end
    
  def fill_choice(a, b)
    fill_in "question_#{a}_choice_#{b}", with: @new_choice[a][b]
  end
  
  def poltergeist_stuff
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, {:timeout => 60})
    end
    Capybara.current_driver = :poltergeist
    require 'database_cleaner'
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean
  end
end



class ActionDispatch::IntegrationTest
  
  include BestInPlace::TestHelpers
  
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL

  Capybara.javascript_driver = :poltergeist

  # Reset sessions and driver between tests
  # Use super wherever this method is redefined in your individual test classes
  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
  
  # Log in as a particular user.
  def log_in_as(user, password: 'password', remember_me: '1')
    post login_path, params: { session: { username: user.username,
                                    password: password,
                                    remember_me: remember_me } }
  end
end
