class Teacher < User
    
    before_destroy  :destroy_associated_records
    
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
    
    
    
    def seminars_i_can_edit
        Seminar.joins(seminar_teachers: :user)
            .where("seminar_teachers.user_id = ?", self.id)
            .where("seminar_teachers.can_edit = ?", true)
    end
    
    def unaccepted_classes
        Seminar.joins(seminar_teachers: :user)
            .where("seminar_teachers.user_id = ?", self.id)
            .where("seminar_teachers.accepted = ?", false)
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
