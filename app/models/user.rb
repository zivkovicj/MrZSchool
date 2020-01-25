class User < ApplicationRecord
    attr_accessor       :remember_token, :activation_token, :reset_token
    #before_save         :downcase_stuff
    before_validation   :check_title, :check_user_number, :check_username, :check_password
    before_create       :create_activation_digest
    after_create        :update_last_login
    
    has_many    :commodities
    has_many    :objectives
    has_many    :questions
    has_many    :labels
    has_many    :quizzes
    has_many    :pictures
    has_many    :goals
    has_many    :currencies
    has_many    :given_currencies, :class_name => "Currency", :as => :giver
    has_many    :ripostes
    has_and_belongs_to_many  :teams
    belongs_to  :school
    belongs_to   :sponsor,  :class_name => "User"
    has_many    :goal_students, dependent: :destroy
    has_many    :worksheets
    
    attribute :verified, :integer, default: 0
    attribute :school_admin, :integer, default: 0

    validates :first_name, length: {maximum: 25},
            presence: true
    validates :last_name, length: {maximum: 25},
            presence: true
    validates :user_number, numericality: { less_than_or_equal_to: 2000000000 }, unless: Proc.new { |a| a.user_number.blank? }
    
    include ModelMethods
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
    validates :email,
                    length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false },
                    unless: Proc.new { |a| a.type == "Student" && a.email.blank? }
    
    include NeedDelivered
    
    class << self
        # Returns the hash digest of the given string.
        def digest(string)
            cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                          BCrypt::Engine.cost
            BCrypt::Password.create(string, cost: cost)
        end
        
        # Returns a random token
        def new_token
            SecureRandom.urlsafe_base64
        end
    end
      
    # Remembers a user in the database for use in persistent sessions
    def remember 
        self.remember_token = User.new_token
        update_attribute(:remember_digest, User.digest(remember_token))
    end
    
    # Returns true if the given token matches the digest.
    def authenticated?(attribute, token)
        digest = send("#{attribute}_digest")
        return false if digest.nil?
        BCrypt::Password.new(digest).is_password?(token)
    end
    
    # Forgets a user.
    def forget
        update_attribute(:remember_digest, nil)
    end
    
    # Activates an account
    def activate
        update_columns(activated: true, activated_at: Time.zone.now)
    end
        
    # Sends activation email
    def send_activation_email
        #UserMailer.account_activation(self).deliver_now
    end
    
    # Sets the password reset attributes
    def create_reset_digest
        self.reset_token = User.new_token
        update_columns(reset_digest: User.digest(reset_token), reset_sent_at: Time.zone.now)
    end
    
    # Sends password reset email
    def send_password_reset_email
        UserMailer.password_reset(self).deliver_now
    end
    
    # Returns true if a password reset has expired
    def password_reset_expired?
        reset_sent_at < 2.hours.ago
    end

    # Determines whether a teacher has an objective
    def has_objective?(this_objective)
        seminars.each do |seminar|
           return true if seminar.objectives.include?(this_objective)
        end
        return false
    end
    
    def name_with_title
        "#{title.split.map(&:capitalize).join(' ')} #{last_name.split.map(&:capitalize).join(' ')}"
    end
    
    def full_name_with_title
        "#{title.split.map(&:capitalize).join(' ')} #{first_name.split.map(&:capitalize).join(' ')} #{last_name.split.map(&:capitalize).join(' ')}"
    end
    
    def one_unfinished(obj)
        self.quizzes.find_by(:objective => obj, :total_score => nil)
    end
 
    def all_unfinished_quizzes(seminar)
        seminar.objectives.select{|x| self.one_unfinished(x)} 
    end
    
    def desk_consulted_objectives(seminar)
        blap = self.teams.map(&:objective_id)
        return seminar.objectives.where(:id => blap).select{|x| !self.one_unfinished(x)}
    end
    
    def quiz_collection(seminar, which_key)
        # The line x.ready || which_key != "pretest" ensures that students are only offered pretests they are ready for.  But readiness doesn't affect showing other types of keys
        objective_students
            .select{|x| x.read_attribute(:"#{which_key}_keys") > 0 && (which_key != "pretest" || x.ready) && !one_unfinished(x.objective)}
            .map(&:objective)
            .sort_by{|e| e.topic_and_number }
    end
    
    def can_edit_this_seminar(seminar)
        this_st = self.seminar_teachers.find_by(:seminar => seminar)
        this_st && this_st.can_edit
    end
    
    private

        # Converts info to all lower-case.
        def downcase_stuff
          email.downcase! if email
          username.downcase! if username
        end
    
        # Creates and assigns the activation token and digest.
        def create_activation_digest
          self.activation_token  = User.new_token
          self.activation_digest = User.digest(activation_token)
        end
    
        def check_title
            self.title = "Awesome" if self.title.blank?
        end
    
        def check_user_number
            self.user_number = User.maximum(:id).next if self.user_number.blank? or self.user_number.abs > 2000000000
        end
        
        def make_username
          firstInitial = self.first_name[0,1].downcase
          lastInitial = self.last_name[0,1].downcase
          user_number = self.user_number
          username = "#{firstInitial}#{lastInitial}#{user_number}"
          return username if User.find_by(:username => username) == nil
          
          firstDown = self.first_name.downcase
          username = "#{firstDown}#{lastInitial}#{user_number}"
          return username if User.find_by(:username => username) == nil
    
          lastDown = self.last_name.downcase
          username = "#{firstInitial}#{lastDown}#{user_number}"
          return username if User.find_by(:username => username) == nil
    
          username = "#{firstDown}#{lastDown}#{user_number}"
          return username if User.find_by(:username => username) == nil
          
          return SecureRandom.hex(4)
        end
        
        def check_username
            user_with_username = User.find_by(:username => self.username)
            already_taken = user_with_username.present? && user_with_username != self
            self.username = make_username if self.username.blank? or already_taken
        end
        
        def check_password
            self.password = "#{self.username}" if self.password_digest.blank?
        end
        
        def update_last_login
            self.update(:last_login => self.created_at) 
        end
        
        
end
