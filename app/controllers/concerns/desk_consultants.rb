
module DeskConsultants
    extend ActiveSupport::Concern
    
    
    # Sem_studs_hash
    def setup_sem_studs_hash
        SeminarStudent.where(:seminar => @seminar, :present => true).includes(:user)
        .pluck(:user_id, :present, :last_consultant_day, :teach_request, :learn_request)
            .map{|user_id, present, last_consultant_day, teach_request, learn_request| {
                user: user_id,
                present: present,
                last_consultant_day: last_consultant_day,
                teach_request: teach_request,
                learn_request: learn_request
            }}
    end
    
    # Rank students by their adjusted consultant points.
    def setup_rank_by_consulting
        @sem_studs_hash.sort_by{|x| x[:last_consultant_day]}.map{|x| x[:user]}
    end
    
    # obj_sems hash
    def setup_obj_sems_hash
        @seminar.objective_seminars.includes(:objective).where("priority > ?", 0)
            .pluck(:objective_id, :priority, :students_needed)
            .map{|objective_id, priority, students_needed|
                {obj: objective_id,
                 priority: priority,
                 students_needed: students_needed
                }
            }
    end
    
    # Need Hash
    def setup_need_hash
        need_hash = {}
        @obj_sems.each{|val| need_hash[val[:obj]] = val[:students_needed]}
        return need_hash
    end
    
    # Get Objectives
    def get_objectives
        @obj_sems.sort_by{|x| -x[:priority]}.map{|x| x.first[1]}
    end
    
    # score_hash
    def setup_score_hash
        ObjectiveStudent.where(:objective => @objectives, :user_id => @rank_by_consulting)
        .pluck(:objective_id, :user_id, :points_all_time, :ready, :teacher_granted_keys, :dc_keys, :pretest_keys)
        .map{|objective_id, user_id, points_all_time, ready, teacher_granted_keys, dc_keys, pretest_keys| {
            obj: objective_id,
            user: user_id,
            points: points_all_time,
            ready: ready,
            total_keys: teacher_granted_keys + dc_keys + pretest_keys
        }}
    end
  
    # Establish a new consultant group
    def establish_new_group(user_id, obj, is_consult)
      # Bracket 0 = normal
      # Bracket 1 = unplaced students
      # Bracket 2 = absent students
      new_team = {}
      new_team[:consultant_id] = nil
      new_team[:consultant_id] = user_id if is_consult
      new_team[:objective_id] = obj
      new_team[:user_ids] = []
      new_team[:user_ids] << user_id
      @teams << new_team
    end
    
    def adjust_need_hash(obj)
        @need_hash[obj] -= 4 if obj
    end
    
    def adjust_unplaced_students(user_id)
        @unplaced_students.delete(user_id)
    end
    
    # Choose the consultants
    def still_needed(obj)
        groups_need_for_obj = ((@need_hash[obj].to_f/4).to_f).ceil
        groups_need_for_class = @consultants_needed - @teams.count
        return [groups_need_for_obj, groups_need_for_class].min
    end
    
    def choose_consultants
      
      def check_for_final_break
        @teams.count >= @consultants_needed
      end
      
      def check_priority_five_objectives
          priority_five_objs = @obj_sems.select{|x| x[:priority] == 5}.map{|x| x[:obj]}
          priority_five_objs.each do |obj|
              perfect_studs = @score_hash.select{|x|
                  x[:obj] == obj &&
                  x[:points].to_i > 4 &&
                  x[:points].to_i < 9 &&
                  x[:total_keys] == 0
              }.map{|x| x[:user]}.sort_by{|x| @rank_by_consulting.index x}
              
              nine_star_studs = @score_hash.select{|x|
                  x[:obj] == obj &&
                  x[:points].to_i == 9 &&
                  x[:total_keys] == 0
              }.map{|x| x[:user]}.sort_by{|x| @rank_by_consulting.index x}
              
              ten_star_studs = @score_hash.select{|x|
                  x[:obj] == obj &&
                  x[:points].to_i == 10 &&
                  x[:total_keys] == 0
              }.map{|x| x[:user]}.sort_by{|x| @rank_by_consulting.index x}
              
              studs_with_keys = @score_hash.select{|x|
                  x[:obj] == obj &&
                  x[:points].to_i > 4 &&
                  x[:total_keys] > 0
              }.map{|x| x[:user]}.sort_by{|x| @rank_by_consulting.index x}
              
              qualified_studs = [perfect_studs,nine_star_studs,ten_star_studs,studs_with_keys].flatten
              
              qualified_studs.take(still_needed(obj)).each do |user_id|
                  establish_new_group(user_id, obj, true)
                  adjust_need_hash(obj)
                  adjust_unplaced_students(user_id)
              end
          end
      end
      
      @consultants_needed = ((@rank_by_consulting.count/4).to_f).ceil
      check_priority_five_objectives
      
      # Then look at students in order of increasing consultant points
      
      @unplaced_students.each do |user_id|
        return if check_for_final_break
        
        # See if student's teach_request will work.
        this_request = @sem_studs_hash.detect{|x| x[:user] == user_id}[:teach_request]
        if this_request
            this_obj_sem = @obj_sems.detect{|x| x[:obj] == this_request}
            if this_obj_sem
                this_priority = this_obj_sem[:priority]
                if (@need_hash[this_request] && @need_hash[this_request] > 0 && this_priority > 0)
                        establish_new_group(user_id, this_request, true)
                        adjust_need_hash(this_request)
                        adjust_unplaced_students(user_id)
                        next
                end
            end
        end
        
        # If the request doesn't work, look at the student's teach_options
        # This method basically emulates the teach_options method
        qualified_objs = @score_hash.select{|x|
            x[:user] == user_id &&
            x[:points].to_i > 4 &&
            x[:points].to_i < 9 &&
            x[:total_keys] < 1 &&
            @need_hash[x[:obj]] > 0
        }.map{|x| x[:obj]}
        this_obj = @objectives.detect{|x| qualified_objs.include?(x)}
        
        if this_obj
            establish_new_group(user_id, this_obj, true)
            adjust_need_hash(this_obj)
            adjust_unplaced_students(user_id)
            next
        end
      end
    end

    ## SORT APPRENTICES INTO CONSULTANT GROUPS ##
    
    # First, try to place apprentices into groups offering their learn Requests
    def place_apprentices_by_requests
        def find_student_by_request(team)
            this_obj = team[:objective_id]
            these_studs = @sem_studs_hash
            .select{|x|
                x[:learn_request] == this_obj &&
                @unplaced_students.include?(x[:user])
            }.map{|x| x[:user]}
            
            this_score = @score_hash.detect{|x|
                x[:obj] == this_obj &&
                these_studs.include?(x[:user]) &&
                x[:total_keys] < 1
            }
            
            if this_score
                this_user = this_score[:user]
                add_to_group(team, this_user)
                adjust_unplaced_students(this_user)
            end
        end
        
        4.times do
            @teams.each do |team|
                find_student_by_request(team)
            end
        end\
    end
    
    # Most students probably won't be placed by their requests. 
    # Place them by the group that can fit them.
    
    # Look for readiness next
    
    def add_to_group(team, this_user)
        team[:user_ids] << this_user
    end
    
    def find_student_by_score(team)
        this_obj = team[:objective_id]
        this_score = @score_hash
            .detect{|x|
                @unplaced_students.include?(x[:user]) &&
                x[:obj] == this_obj &&
                x[:points].to_i < 6 &&
                x[:ready] == true &&
                x[:total_keys] < 1
            }
        
        if this_score
            this_user = this_score[:user]
            add_to_group(team, this_user)
            adjust_unplaced_students(this_user)
        end
    end
    
    def place_apprentices_by_mastery
        4.times do
            @teams.each do |team|
                if team[:user_ids].count < 4
                    find_student_by_score(team)
                end
            end
        end
    end
    
    def check_for_lone_students
        # If some teams have a consultant, but no teams members, elimiate those teams
        # And place those students back on the unplaced list
      @teams.each do |team|
          if team[:user_ids].count < 2
              @unplaced_students.push(*team[:user_ids])
              @teams.delete(team)
          end
      end
    end
    
    def new_place_for_lone_students
        @unplaced_students.reverse.each do |stud|
            # First, check whether lone student can be placed into an established group
            teams_with_room = @teams.select{|x| x[:user_ids].count < 4}
            suitable_objs = @score_hash.select{|x|
                x[:user] == stud &&
                x[:ready] == true &&
                x[:points].to_i < 6 &&
                x[:total_keys] == 0
            }.map{|x| x[:obj]}
        
            this_team = teams_with_room.detect{|x| suitable_objs.include?(x[:objective_id])}
            
            if this_team
                add_to_group(this_team, stud)
                next
            end
            
            # If student can't be placed, try the student's learn request
            # If there is a request, and the priority is above zero, and the student is ready, make a new group
            # @objectives.include?(request_id) checks that the request is in the classes' objectives with non-zero priority
            request_id = @sem_studs_hash.detect{|x| x[:user] == stud}[:learn_request]
            
            if request_id && @objectives.include?(request_id) && suitable_objs.include?(request_id)
                establish_new_group(stud, request_id, false)
                next  # Moves on to the next student, which prevents looking at learn options
            end
            
            # Third resort is to make a new group with the student's top suitable objective
            this_obj = @objectives.detect{|x| suitable_objs.include?(x)}
            if this_obj
                establish_new_group(stud, this_obj, false)
                next
            end
            
            # If student is still not placed, add them to the unplaced_students
            @unplaced_team[:user_ids] << stud
        end
    end
  
    def assignSGSections()
      # In the future, it might be cool to bring back this feature. Gives each
      # team member a number, which could correspond to different roles of the
      # activity.
      
      #@consultancy.teams.each do |team|
      #currAssign = 1
      #rev[:group].each_with_index do |groupMember, index|
      #if rev[:consultant][index] == 0
      #rev[:consultant][index] = currAssign
      #currAssign = currAssign + 1
      #end
      #end
      #end
    end
    
    def create_consultancy
        @consultancy = Consultancy.create(:seminar => @seminar)
        
        @teams << @unplaced_team if @unplaced_team[:user_ids].count > 0
        
        these_teams = []
        @teams.each_with_index do |team, index|
            these_teams[index] = Team.new(:consultancy_id => @consultancy.id, :consultant_id => team[:consultant_id], :objective_id => team[:objective_id], :bracket => team[:bracket])
            these_teams[index].user_ids = team[:user_ids]
        end
        
        # This method of saving creates all teams in a single db call
        Team.transaction do
            these_teams.each do |this_team|
                this_team.save!
            end
        end
    end
    

end
