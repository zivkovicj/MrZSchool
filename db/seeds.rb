# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Admin
Admin.create!(first_name:  "Jeff",
             last_name:   "Zivkovic",
             title: "Mr.",
             email: "zivkovic.jeff@gmail.com",
             username: "zivkovic.jeff@gmail.com",
             password:              "foobar",
             password_confirmation: "foobar",
             user_number: 1,
             activated: true,
             activated_at: Time.zone.now)
             
jeff = Admin.first

Admin.create!(first_name:  "Second",
             last_name:   "InCommand",
             title: "Mr.",
             email: "noobsauce@gmail.com",
             username: "noobsauce@gmail.com",
             password:              "foobar",
             password_confirmation: "foobar",
             user_number: 2,
             activated: true,
             activated_at: Time.zone.now)
 
Admin.create!(first_name:  "Business",
             last_name:   "Partner",
             title: "Mrs.",
             email: "businesspartner@gmail.com",
             username: "businesspartner@gmail.com",
             password:              "foobar",
             password_confirmation: "foobar",
             user_number: 3,
             activated: true,
             activated_at: Time.zone.now)
             
Admin.create!(first_name:  "Last",
             last_name:   "Admin",
             title: "Ms.",
             email: "lastadmin@gmail.com",
             username: "lastadmin@gmail.com",
             password:              "foobar",
             password_confirmation: "foobar",
             user_number: 4,
             activated: true,
             activated_at: Time.zone.now)

title_array = ["Mrs.", "Mr.", "Miss", "Ms.", "Dr."]

# Teachers
9.times do |n|
  first_name  = Faker::Name.first_name
  last_name  = Faker::Name.last_name
  which_title = rand(title_array.length)
  email = "example-#{n+1}@railstutorial.org"
  password = "password"
  Teacher.create!(first_name:  first_name,
               last_name:   last_name,
               email: email,
               username: email,
               title: title_array[which_title],
               password:              password,
               password_confirmation: password,
               user_number: n,
               activated: true,
               activated_at: Time.zone.now)
end

# Seminars
[["Main Teacher, 1st Period",5], ["Main Teacher, 2nd Period",5], ["Another Teacher, First Period",6]].each_with_index do |n, index|
    sem = Seminar.create!(name: n[0], user_id: n[1], term: 0, school_year: 9, :owner => Teacher.find(n[1]), :quiz_open_days => [0,1,2,3,4,5,6], :quiz_open_times => [0,1380])
    sem.teachers << Teacher.find(n[1])
end

# Fields

f1 = Field.create(:name => "Mathematics")
f2 = Field.create(:name => "Science")
f3 = Field.create(:name => "Misc.")

# Domains

d1 = Domain.create(:name => "Numbers", :field => f1)
d2 = Domain.create(:name => "Geometry", :field => f1)
d3 = Domain.create(:name => "Other Mathematics", :field => f1)
d4 = Domain.create(:name => "Biology", :field => f2)
d5 = Domain.create(:name => "Functions", :field => f1)
d6 = Domain.create(:name => "Misc.", :field => f3)

# Topics

t1= Topic.create(:name => "Integers", :domain => d1)
t2 = Topic.create(:name => "Roots", :domain => d1)
t3 = Topic.create(:name => "Transformations", :domain => d2)
t4 = Topic.create(:name => "Pythagorean Theorem", :domain => d2)
t5 = Topic.create(:name => "Other Math Topics", :domain => d3)
t6 = Topic.create(:name => "Anatomy", :domain => d4)
t7 = Topic.create(:name => "Cells", :domain => d4)
t8 = Topic.create(:name => "Intercept", :domain => d5)
t9 = Topic.create(:name => "Misc.", :domain => d6)



       
# Objectives

assignNameArray = [[1,"Add and Subtract Numbers", "Addy Subby", t1, 7],
    [1,"Multiply and Divide Numbers", "Multy Divvy", t1, 7],
    [1,"Numbers Summary", "Numb Sumb", t1, 7],
    [1,"Intercept", "Catch!", t5, 7],
    [1,"Slope","Whee!", t5, 8],
    [1,"Scatterplots", "Bladderspots", t5, 8],
    [1,"Association", "Don't", t5, 8],
    [1,"One-step Equations", "One-Steppers", t5, 7],
    [2,"Integers", "Intergers", t1, 8],
    [2,"Volume", "Loud!",  t5, 6],
    [2,"Fractions", "So hard!", t5, 6],
    [2,"Rationals", "Rats! Rats! Rats!", t5, 8], 
    [2,"Irrationals", "Eye-Rats!", t5, 8],
    [3,"Volcanos", "Eldon Volcanado", t5, 8],
    [3,"Evolution", "is Fake", t5, 10],
    [3,"Taxonomy", "Tamoxony", t5, 7],
    [3,"Intro to Cells", "Sales", t7, 7],
    [3,"Human Anatomy", "A Manatee", t6, 10]]
    
assignNameArray.each_with_index do |objective, index|
    @objective = Objective.create(:name => objective[1], :catchy_name => objective[2], :topic => objective[3], :user => jeff, :extent => "public", :grade_level => objective[4])
    ObjectiveSeminar.create(:seminar_id => objective[0], :objective => @objective, :priority => 2, :pretest => 0)
end


# Students       
29.times do |n|
  first_name  = Faker::Name.first_name
  last_name  = Faker::Name.last_name
  email = "example-#{n+20}@railstutorial.org"
  password = "password"
  @student = Student.create!(first_name:  first_name,
               last_name:   last_name,
               email: email,
               user_number: n,
               password: password,
               school_year: 9)
   SeminarStudent.create!(seminar_id: 1, user_id: @student.id)
end

# Some students are registered to two class periods
SeminarStudent.create!(seminar_id: 2, user_id: 17)
SeminarStudent.create!(seminar_id: 2, user_id: 18)

18.times do |n|
  first_name  = Faker::Name.first_name
  last_name  = Faker::Name.last_name
  email = "example-#{n+50}@railstutorial.org"
  password = "password"
  @student = Student.create!(first_name:  first_name,
               last_name:   last_name,
               email: email,
               user_number: n,
               password: password,
               school_year: 9)
   SeminarStudent.create!(seminar_id: 2, user_id: @student.id)
end

36.times do |n|
  first_name  = Faker::Name.first_name
  last_name  = Faker::Name.last_name
  email = "example-#{n+100}@railstutorial.org"
  password = "password"
  @student = Student.create!(first_name:  first_name,
               last_name:   last_name,
               email: email,
               user_number: n,
               password: password,
               school_year: 9)
   SeminarStudent.create!(seminar_id: 3, user_id: @student.id)
end

Student.all.each do |student|
    student.update(:user_number => student.id)
    student.update(:username => "#{student.first_name[0,1].downcase}#{student.last_name[0,1].downcase}#{student.id}")
    student.update(:password => "#{student.id}")
end

# Scores
skillMatrix = [[0,0,0,0,5,7],[0,0,5,5,7,10],[0,5,7,10,10,10]]
Student.all.each do |student|
    skill = rand(3)
    student.seminar_students.each do |ss|
        seminar = ss.seminar
        seminar.objectives.each do |obj|
            scooby = rand(6)
            doo = skillMatrix[skill][scooby]
            ss.update(pref_request: skill)
            student.objective_students.create!(objective: obj, points: doo) if student.objective_students.find_by(:objective => obj) == nil
        end
    end
end

label_for_pictures = Label.create(:name => "Label for Pictures", :extent => "public", :user => jeff)
other_label_for_pictures = Label.create(:name => "Other Label for Pictures", :extent => "public", :user => jeff)

add_label = Label.create(:name => "Adding Numbers", :extent => "public", :user => jeff)
subtract_label = Label.create(:name => "Subtracting Numbers", :extent => "public", :user => jeff)
multiply_label = Label.create(:name => "Multiplying Numbers", :extent => "public", :user => jeff)
divide_label = Label.create(:name => "Dividing Numbers", :extent => "public", :user => jeff)
select_many_label = Label.create(:name => "Which Expressions are Equal", :extent => "public", :user => jeff)

teacher_user = Teacher.first
intercept_from_graphs_label = Label.create(:name => "Intercept from Graphs", :extent => "public", :user => teacher_user)
intercept_from_equations_label = Label.create(:name => "Intercept from Equations", :extent => "public", :user => teacher_user)
intercept_from_tables_label = Label.create(:name => "Intercept from Tables", :extent => "public", :user => teacher_user)


# Add labels to topics

t1.labels << add_label
t1.labels << subtract_label
t1.labels << multiply_label
t1.labels << divide_label
t2.labels << select_many_label
t8.labels << intercept_from_graphs_label
t8.labels << intercept_from_equations_label
t8.labels << intercept_from_tables_label
t9.labels << label_for_pictures
t9.labels << other_label_for_pictures

add_and_sub_obj = Objective.find_by(:name => "Add and Subtract Numbers")
mult_and_div_obj = Objective.find_by(:name => "Multiply and Divide Numbers")
sum_obj = Objective.find_by(:name => "Numbers Summary")

LabelObjective.create(:label => add_label, :objective => add_and_sub_obj,
    :quantity => 2, :point_value => 200)
LabelObjective.create(:label => subtract_label, :objective => add_and_sub_obj,
    :quantity => 3, :point_value => 100)
    
LabelObjective.create(:label => multiply_label, :objective => mult_and_div_obj,
    :quantity => 3, :point_value => 200)
LabelObjective.create(:label => divide_label, :objective => mult_and_div_obj,
    :quantity => 2, :point_value => 200)
    
LabelObjective.create(:label => add_label, :objective => sum_obj,
    :quantity => 2, :point_value => 100)
LabelObjective.create(:label => subtract_label, :objective => sum_obj,
    :quantity => 1, :point_value => 200)
LabelObjective.create(:label => multiply_label, :objective => sum_obj,
    :quantity => 2, :point_value => 300)
LabelObjective.create(:label => divide_label, :objective => sum_obj,
    :quantity => 1, :point_value => 400)
LabelObjective.create(:label => select_many_label, :objective => add_and_sub_obj,
    :quantity => 1, :point_value => 200)

pic_array = [["Labels", "app/assets/images/labels.png"],
    ["Objectives", "app/assets/images/objectives.png"],
    ["Desk Consultants", "app/assets/images/desk_consult.png"],]

pic_array.each do |n|
    pic = Picture.new(:name => n[0], :user => User.first)
    image_src = File.join(Rails.root, n[1])
    src_file = File.new(image_src)
    pic.image = src_file
    pic.save
end

Label.first.pictures << Picture.first
Label.first.pictures << Picture.second
Label.second.pictures << Picture.third

(1..10).each do |n|
    question = Question.new(:user => jeff, :extent => "public", :style => "multiple_choice")
    r = rand(10 * n)
    s = rand(6 * n)
    prompt_string = "What is #{r} + #{s} ?"
    question.prompt = prompt_string
    question.choices = [r + s, r + s + 1, r + s - 1, r - s]
    question.correct_answers = ["#{r + s}"]
    question.label = add_label
    question.save
    
    question = Question.new(:user => jeff, :extent => "public", :style => "multiple_choice")    
    r = rand(9 * n)
    s = rand(5 * n)
    prompt_string = "What is #{r} - #{s} ?"
    question.prompt = prompt_string
    question.choices = [r - s, r + 1 - s, (r - 1) + s, r + s]
    question.correct_answers = ["#{r - s}"]
    question.label = subtract_label
    question.save
    
    question = Question.new(:user => jeff, :extent => "public", :style => "multiple_choice")
    r = rand(12)
    prompt_string = "What is #{n} x #{r} ?"
    question.prompt = prompt_string
    question.choices = [n * r, n * (r + 1), n * (r - 1), (n - 1) * r]
    question.correct_answers = ["#{(n) * r}"]
    question.label = multiply_label
    question.save
    
    question = Question.new(:user => jeff, :extent => "public", :style => "multiple_choice")
    r = rand(12)
    prompt_string = "What is #{n * r} / #{n} ?"
    question.prompt = prompt_string
    question.choices = [r, r + 1, r - 1, r - 2, 2 * r]
    question.correct_answers = ["#{r}"]
    question.label = divide_label
    question.save
    
    question = Question.new(:user => jeff, :extent => "public", :style => "fill_in")
    r = rand(10 * n)
    s = rand(6 * n)
    prompt_string = "What is #{r} + #{s} ?"
    question.prompt = prompt_string
    question.correct_answers = ["#{r + s}"]
    question.label = add_label
    question.save
    
    question = Question.new(:user => jeff, :extent => "public", :style => "select_many")
    r = rand(12)
    question.prompt = "Which of these expressions are equal to #{n} - #{r}"
    question.choices = ["#{n} + -(#{r})", "-(#{r}) + #{n}", "-(#{n}) + #{r}"]
    question.correct_answers = ["#{n} + -(#{r})", "-(#{r}) + #{n}"]
    question.label = select_many_label
    question.save
end

Precondition.create(:preassign => Objective.first, :mainassign => Objective.second)

c1 = Seminar.first.consultancies.create()
t1 = c1.teams.create(:consultant => Student.all[0])
t1.users << Student.all[1]
t1.users << Student.all[2]
t1.users << Student.all[3]
t2 = c1.teams.create(:consultant => Student.all[4])
t2.users << Student.all[5]
t2.users << Student.all[6]
t2.users << Student.all[7]

school_array = 
    [["Beaver High School", "Beaver", "UT"],
    ["Milford High School", "Milford", "UT"],
    ["Bear River High School", "Garland", "UT"],
    ["Box Elder High School", "Brigham", "UT"],
    ["Beaver High School", "Beaver", "UT"],
    ["Cache High School", "North Logan", "UT"],
    ["Mountain Crest High School", "Hyrum", "UT"],
    ["Sky View High School", "Smithfield", "UT"],
    ["Logan High School", "Logan", "UT"],
    ["East Carbon High School", "East Carbon", "UT"],
    ["Manila High School", "Manila", "UT"],
    ["Altamont High School", "Altamont", "UT"],
    ["Green River High School", "Green River", "UT"],
    ["East High School", "Salt Lake City", "UT"],
    ["West High School", "Salt Lake City", "UT"],
    ["Highland High School", "Salt Lake City", "UT"],
    ["Monticello High School", "Monticello", "UT"],
    ["Cedar Ridge High School", "Richfield", "UT"],
    ["North Summit High School", "Coalville", "UT"],
    ["Blue Peak High School", "Toole", "UT"],
    ["Wasatch High School", "Heber", "UT"],
    ["Carson High School", "Carson City", "NV"],
    ["Clark High School", "Las Vegas", "NV"]]
    
school_array.each do |school|
    School.create(:name => school[0], :city => school[1], :state => school[2])
end




Teacher.all[0..5].each do |teach|
    teach.update(:school => School.first)
end
Teacher.all[6..8].each do |teach|
    teach.update(:school => School.second)
end

Student.all.each do |stud|
    stud.update(:sponsor => stud.seminars.first.teachers.first)
    stud.update(:school => stud.sponsor.school)
end


