class ObjectiveStudent < ApplicationRecord
    
    before_create  :initialize_ready
    
    belongs_to :user
    belongs_to :objective
    
    validates :teacher_granted_keys, numericality: { :less_than_or_equal_to => 6, :greater_than_or_equal_to => 0 }
    validates_uniqueness_of :user, :scope => :objective
    
    attribute :pretest_keys, :integer, default: 0
    attribute :dc_keys, :integer, default: 0
    attribute :teacher_granted_keys, :integer, default: 0
    attribute :ready, :boolean, default: false
    
    def applicable_classes
        Seminar.select{|x| x.students.include?(user) && x.objectives.include?(objective)}
    end
    
    def obj_willing?(max)
        (points_all_time.to_i < max) && total_keys == 0
    end
    
    def obj_ready_and_willing?(max)
        ready && obj_willing?(max)
    end
    
    def passed
        self.points_all_time.to_i >= 6
    end
    
    def passed_with_100
        self.points_all_time.to_i == 10
    end
    
    def set_points(origin, this_score)
        old_score_all_time = points_all_time.to_i
        new_score_all_time = Quiz.where(:user_id => user_id, :objective_id => objective_id).maximum(:total_score) || this_score
        self.points_all_time = new_score_all_time
        
        if origin == "pretest" || origin == "manual_pretest_score"
            self.pretest_score = this_score if this_score > pretest_score.to_i
        elsif origin == "manual_points_this_term"
            self.points_this_term = this_score
        elsif origin != "manual_points_all_time"
            self.points_this_term = [points_this_term.to_i, this_score].max
        end
        
        
        self.save
        
        # Set ready for all mainassigns
        if old_score_all_time < 6 && new_score_all_time >= 6
            objective.mainassigns.each do |mainassign|
                mainassign_os = ObjectiveStudent.find_or_create_by(:user => user, :objective => mainassign)
                mainassign_os.set_ready
            end
        end
        
        # Change students_needed for applicable seminars
        if old_score_all_time < 9 && new_score_all_time >= 9
            these_classes = applicable_classes
            these_classes.each do |sem|
                ObjectiveSeminar.find_by(:objective => objective, :seminar => sem).students_needed_refresh
            end
        end
            
    end
    
    def take_all_keys
        update(:teacher_granted_keys => 0, :dc_keys => 0, :pretest_keys => 0)
    end
    
    def total_keys
        self.teacher_granted_keys + self.pretest_keys + self.dc_keys 
    end
    
    def update_keys(which_key, new_keys)
        old_keys = self.read_attribute(:"#{which_key}_keys")
        temp_keys_1 = old_keys + new_keys.to_i
        temp_keys_2 = [temp_keys_1, 6].min
        current_keys = [temp_keys_2, 0].max
        if which_key == "pretest"
            self.update(:pretest_keys => current_keys) 
        else
            self.update(:"#{which_key}_keys" => current_keys, :pretest_keys => 0)  # If dc_keys or teacher_keys are given, erase the pretest keys
        end
    end
    
    def new_ready
        objective.preassigns.all? {|preassign| ObjectiveStudent.find_by(:user => user, :objective => preassign)&.points_all_time.to_i >= 6 }
    end
    
    def initialize_ready
        self.ready = new_ready
        return true
    end
    
    def set_ready
        self.update(:ready => new_ready)
    end
end
