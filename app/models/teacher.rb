class Teacher < User
    
    before_destroy  :destroy_associated_records
    after_create    :create_star_commodity, :name_teacher_currency
    
    has_many    :seminar_teachers, dependent: :destroy, foreign_key: :user_id
    has_many    :seminars, through: :seminar_teachers
    has_many    :students, through: :seminars
    has_many    :sponsored_students, :class_name => "Student", :foreign_key => "sponsor_id"

    validates  :password, presence: true,
                    length: {minimum: 6},
                    allow_nil: true
    has_secure_password
    
    def first_seminar
        self.seminars.order(:name).first 
    end
    
    def create_star_commodity
      new_star = self.commodities.new(:name => "Star", :quantity => 25, :current_price => 5, :date_last_produced => Date.today, 
        :production_rate => 10, :production_day => 0, :salable => true, :usable => true, :deliverable => false)
      image_src = File.join(Rails.root, "app/assets/images/stars/filled_star.png")
      src_file = File.new(image_src)
      new_star.image = src_file
      new_star.save(validate: false)
    end
    
    def name_teacher_currency
        self.update(:teacher_currency_name => "#{self.name_with_title} Bucks") 
    end
    
    def seminars_i_can_edit
        Seminar.joins(seminar_teachers: :user)
            .where("seminar_teachers.user_id == ?", self.id)
            .where("seminar_teachers.can_edit == ?", true)
    end
    
    def unaccepted_classes
        Seminar.joins(seminar_teachers: :user)
            .where("seminar_teachers.user_id == ?", self.id)
            .where("seminar_teachers.accepted == ?", false)
    end
    
    private
    
        def destroy_associated_records
            Objective.where(:user => self).each do |objective|
                objective.destroy
            end
            self.seminars.each do |seminar|
                seminar.destroy
            end
        end
        
        

end
