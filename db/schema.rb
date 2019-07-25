# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20190719162757) do

  create_table "checkpoints", force: :cascade do |t|
    t.integer  "goal_student_id"
    t.string   "action"
    t.integer  "achievement"
    t.text     "teacher_comment"
    t.text     "student_comment"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "sequence"
  end

  create_table "commodities", force: :cascade do |t|
    t.string   "name"
    t.string   "image"
    t.integer  "school_id"
    t.integer  "user_id"
    t.integer  "production_rate"
    t.integer  "current_price"
    t.integer  "production_day"
    t.integer  "quantity"
    t.datetime "date_last_produced"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.boolean  "deliverable"
    t.boolean  "salable"
    t.boolean  "usable"
    t.index ["school_id"], name: "index_commodities_on_school_id"
    t.index ["user_id"], name: "index_commodities_on_user_id"
  end

  create_table "commodity_students", force: :cascade do |t|
    t.integer  "commodity_id"
    t.integer  "user_id"
    t.integer  "quantity"
    t.integer  "price_paid"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.boolean  "delivered"
    t.integer  "seminar_id"
    t.integer  "school_id"
    t.index ["commodity_id"], name: "index_commodity_students_on_commodity_id"
    t.index ["school_id"], name: "index_commodity_students_on_school_id"
    t.index ["seminar_id"], name: "index_commodity_students_on_seminar_id"
    t.index ["user_id"], name: "index_commodity_students_on_user_id"
  end

  create_table "consultancies", force: :cascade do |t|
    t.integer  "seminar_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "duration"
    t.index ["seminar_id"], name: "index_consultancies_on_seminar_id"
  end

  create_table "currencies", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "seminar_id"
    t.integer  "school_id"
    t.integer  "giver_id"
    t.integer  "value"
    t.text     "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["giver_id"], name: "index_currencies_on_giver_id"
    t.index ["school_id"], name: "index_currencies_on_school_id"
    t.index ["seminar_id"], name: "index_currencies_on_seminar_id"
    t.index ["user_id"], name: "index_currencies_on_user_id"
  end

  create_table "domains", force: :cascade do |t|
    t.string   "name"
    t.integer  "field_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["field_id"], name: "index_domains_on_field_id"
  end

  create_table "fields", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "goal_students", force: :cascade do |t|
    t.integer  "goal_id"
    t.integer  "user_id"
    t.integer  "seminar_id"
    t.integer  "target"
    t.boolean  "approved"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "term"
    t.index ["goal_id", "user_id"], name: "index_goal_students_on_goal_id_and_user_id"
    t.index ["goal_id"], name: "index_goal_students_on_goal_id"
    t.index ["seminar_id"], name: "index_goal_students_on_seminar_id"
    t.index ["user_id"], name: "index_goal_students_on_user_id"
  end

  create_table "goals", force: :cascade do |t|
    t.text     "actions"
    t.integer  "style"
    t.string   "name"
    t.string   "statement_stem"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "extent"
    t.integer  "user_id"
    t.index ["user_id"], name: "index_goals_on_user_id"
  end

  create_table "label_objectives", force: :cascade do |t|
    t.integer  "objective_id"
    t.integer  "label_id"
    t.integer  "quantity"
    t.integer  "point_value"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["label_id", "objective_id"], name: "index_label_objectives_on_label_id_and_objective_id"
    t.index ["label_id"], name: "index_label_objectives_on_label_id"
    t.index ["objective_id"], name: "index_label_objectives_on_objective_id"
  end

  create_table "label_pictures", id: false, force: :cascade do |t|
    t.integer  "label_id"
    t.integer  "picture_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["label_id", "picture_id"], name: "index_label_pictures_on_label_id_and_picture_id"
    t.index ["label_id"], name: "index_label_pictures_on_label_id"
    t.index ["picture_id"], name: "index_label_pictures_on_picture_id"
  end

  create_table "labels", force: :cascade do |t|
    t.string   "name"
    t.string   "extent"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_labels_on_user_id"
  end

  create_table "labels_topics", id: false, force: :cascade do |t|
    t.integer "label_id", null: false
    t.integer "topic_id", null: false
    t.index ["label_id", "topic_id"], name: "index_labels_topics_on_label_id_and_topic_id"
    t.index ["topic_id", "label_id"], name: "index_labels_topics_on_topic_id_and_label_id"
  end

  create_table "objective_seminars", force: :cascade do |t|
    t.integer  "seminar_id"
    t.integer  "objective_id"
    t.integer  "priority"
    t.integer  "pretest"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "students_needed"
    t.index ["objective_id", "seminar_id"], name: "index_objective_seminars_on_objective_id_and_seminar_id"
    t.index ["objective_id"], name: "index_objective_seminars_on_objective_id"
    t.index ["seminar_id"], name: "index_objective_seminars_on_seminar_id"
  end

  create_table "objective_students", force: :cascade do |t|
    t.integer  "objective_id"
    t.integer  "user_id"
    t.integer  "points_all_time"
    t.integer  "unlocked"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "pretest_keys"
    t.integer  "dc_keys"
    t.integer  "teacher_granted_keys"
    t.text     "score_record"
    t.integer  "pretest_score"
    t.integer  "teacher_manual_score"
    t.integer  "points_this_term"
    t.boolean  "ready",                default: false, null: false
    t.index ["objective_id", "user_id"], name: "index_objective_students_on_objective_id_and_user_id"
    t.index ["objective_id"], name: "index_objective_students_on_objective_id"
    t.index ["user_id"], name: "index_objective_students_on_user_id"
  end

  create_table "objective_worksheets", force: :cascade do |t|
    t.integer  "objective_id"
    t.integer  "worksheet_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["objective_id"], name: "index_objective_worksheets_on_objective_id"
    t.index ["worksheet_id"], name: "index_objective_worksheets_on_worksheet_id"
  end

  create_table "objectives", force: :cascade do |t|
    t.string   "name"
    t.string   "extent"
    t.integer  "user_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "catchy_name"
    t.integer  "objective_number"
    t.integer  "grade_level"
    t.integer  "topic_id"
    t.index ["topic_id"], name: "index_objectives_on_topic_id"
    t.index ["user_id"], name: "index_objectives_on_user_id"
  end

  create_table "pictures", force: :cascade do |t|
    t.string   "name"
    t.string   "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "user_id"
    t.index ["user_id"], name: "index_pictures_on_user_id"
  end

  create_table "preconditions", force: :cascade do |t|
    t.integer  "mainassign_id"
    t.integer  "preassign_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "questions", force: :cascade do |t|
    t.string   "style"
    t.text     "prompt"
    t.string   "extent"
    t.integer  "user_id"
    t.integer  "label_id"
    t.integer  "picture_id"
    t.text     "correct_answers"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "grade_type"
    t.text     "choices"
    t.index ["label_id"], name: "index_questions_on_label_id"
    t.index ["picture_id"], name: "index_questions_on_picture_id"
    t.index ["user_id"], name: "index_questions_on_user_id"
  end

  create_table "quizzes", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "objective_id"
    t.integer  "total_score"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "progress"
    t.string   "origin"
    t.integer  "old_stars"
    t.integer  "seminar_id"
    t.boolean  "needs_grading"
    t.index ["objective_id"], name: "index_quizzes_on_objective_id"
    t.index ["seminar_id"], name: "index_quizzes_on_seminar_id"
    t.index ["user_id"], name: "index_quizzes_on_user_id"
  end

  create_table "ripostes", force: :cascade do |t|
    t.integer  "quiz_id"
    t.integer  "question_id"
    t.integer  "tally"
    t.integer  "position"
    t.string   "stud_answer"
    t.integer  "poss"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "graded"
    t.index ["question_id"], name: "index_ripostes_on_question_id"
    t.index ["quiz_id"], name: "index_ripostes_on_quiz_id"
  end

  create_table "schools", force: :cascade do |t|
    t.string   "name"
    t.string   "city"
    t.string   "state"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "term"
    t.text     "term_dates"
    t.string   "market_name"
    t.string   "school_currency_name"
  end

  create_table "seminar_students", force: :cascade do |t|
    t.integer  "seminar_id"
    t.integer  "user_id"
    t.integer  "teach_request"
    t.integer  "learn_request"
    t.integer  "pref_request"
    t.boolean  "present"
    t.integer  "consulting_stars"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "seminar_bucks_earned"
    t.integer  "gems_given_toward_reward"
    t.text     "stars_used_toward_grade"
    t.date     "last_consultant_day"
    t.index ["seminar_id", "user_id"], name: "index_seminar_students_on_seminar_id_and_user_id"
    t.index ["seminar_id"], name: "index_seminar_students_on_seminar_id"
    t.index ["user_id"], name: "index_seminar_students_on_user_id"
  end

  create_table "seminar_teachers", force: :cascade do |t|
    t.integer "seminar_id"
    t.integer "user_id"
    t.boolean "can_edit"
    t.boolean "accepted"
    t.index ["seminar_id", "user_id"], name: "index_seminar_teachers_on_seminar_id_and_user_id"
    t.index ["seminar_id"], name: "index_seminar_teachers_on_seminar_id"
    t.index ["user_id"], name: "index_seminar_teachers_on_user_id"
  end

  create_table "seminars", force: :cascade do |t|
    t.string   "name"
    t.integer  "user_id"
    t.integer  "consultantThreshold"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "which_checkpoint"
    t.text     "checkpoint_due_dates"
    t.integer  "school_year"
    t.integer  "default_buck_increment"
    t.string   "class_reward"
    t.integer  "target_rate"
    t.integer  "school_id"
    t.datetime "term_start_date"
    t.datetime "term_end_date"
    t.integer  "term"
    t.integer  "owner_id"
    t.boolean  "grading_needed"
    t.index ["owner_id"], name: "index_seminars_on_owner_id"
    t.index ["school_id"], name: "index_seminars_on_school_id"
    t.index ["user_id"], name: "index_seminars_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.integer  "consultancy_id"
    t.integer  "objective_id"
    t.integer  "consultant_id"
    t.integer  "bracket"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["consultancy_id"], name: "index_teams_on_consultancy_id"
    t.index ["objective_id"], name: "index_teams_on_objective_id"
  end

  create_table "teams_users", id: false, force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "team_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_teams_users_on_team_id"
    t.index ["user_id", "team_id"], name: "index_teams_users_on_user_id_and_team_id"
    t.index ["user_id"], name: "index_teams_users_on_user_id"
  end

  create_table "topics", force: :cascade do |t|
    t.string  "name"
    t.integer "domain_id"
    t.index ["domain_id"], name: "index_topics_on_domain_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "type"
    t.string   "title"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "username"
    t.string   "password_digest"
    t.string   "email"
    t.integer  "user_number"
    t.integer  "current_class"
    t.string   "remember_digest"
    t.string   "activation_digest"
    t.boolean  "activated"
    t.datetime "activated_at"
    t.string   "reset_digest"
    t.datetime "reset_sent_at"
    t.datetime "last_login"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.integer  "school_id"
    t.integer  "verified"
    t.integer  "sponsor_id"
    t.integer  "school_year"
    t.integer  "school_admin"
    t.string   "teacher_currency_name"
    t.integer  "school_bucks_earned"
  end

  create_table "worksheets", force: :cascade do |t|
    t.string   "name"
    t.string   "uploaded_file"
    t.string   "extent"
    t.integer  "user_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["user_id"], name: "index_worksheets_on_user_id"
  end

end
