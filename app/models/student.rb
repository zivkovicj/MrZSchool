class Student < User
    
    has_many   :seminar_students, dependent: :destroy, foreign_key: :user_id
    has_many   :seminars, through: :seminar_students
    has_many   :objective_students, dependent: :destroy, foreign_key: :user_id
    has_many   :consulted_teams, :class_name => "Team", foreign_key: "consultant_id"
    belongs_to   :sponsor,  :class_name => "Teacher"
    
    validates_uniqueness_of :username, unless: Proc.new { |a| a.username.blank? }
    has_secure_password :validations => false, :allow_nil => true
    
   
    # Add the total points for this student
    def total_stars(seminar)
        objective_students.where(:objective => seminar.objectives).sum(:points)
    end
    
    # Returns first name with limit plus last initial
    def firstPlusInit
        "#{first_name[0,15].split.map(&:capitalize).join(' ')} #{last_name[0,1].split.map(&:capitalize).join(' ')}" 
    end
    
    def fullName
        "#{first_name[0,20].split.map(&:capitalize).join(' ')} #{last_name[0,20].split.map(&:capitalize).join(' ')}"
    end
    
    def last_name_first
        "#{last_name[0,20].split.map(&:capitalize).join(' ')}, #{first_name[0,20].split.map(&:capitalize).join(' ')}"
    end
    
    def consultant_days(seminar)
        @ss = self.seminar_students.find_by(:seminar => seminar)
        last_team = seminar.teams.where(:consultant => self).order(:updated_at).last
        last_consult_date = last_team.present? ? last_team.created_at.to_date : @ss.created_at.to_date
        pre_points = (Date.today - last_consult_date).to_i
        if @ss.pref_request == 2
            pre_points += 1
            pre_points *= 1.2
        elsif @ss.pref_request == 0
            pre_points *= 0.8
            pre_points -= 1
        end
        return pre_points
    end
    
    # Checks whether a student has met all pre-requisites for an objective
    def check_if_ready(objective)
        objective.preassigns.each do |preassign|
            droog = objective_students.find_by(objective_id: preassign.id)
            if droog and droog.points < 7
              return false
            end
        end
        return true
    end
    
    
    
    

end
