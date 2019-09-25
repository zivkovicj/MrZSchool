
module DeskConsultants
    extend ActiveSupport::Concern
    
    # Populate preList with all students who are present today
    def setup_present_students
      @seminar.students.select{|x| x.present_in(@seminar)}
    end
    
    def setup_prof_list()
        # The main array that is actually used is profList, which sorts students
        # by their total scores
        @prof_list = @students.sort {|a,b| a.quiz_stars_all_time(@seminar) <=> b.quiz_stars_all_time(@seminar)}
    end
    
    # Rank students by their adjusted consultant points.
    def setup_rank_by_consulting
        @seminar.seminar_students.where(:user => @students).order(:last_consultant_day).map(&:user)
    end
    
    # need_hash
    def setup_need_hash()
      become_need_hash = Hash.new
      @seminar.objective_seminars.each do |obj_sem|
        become_need_hash[obj_sem.objective.id] = obj_sem.students_needed / 3
      end
      return become_need_hash
    end
  
    # Establish a new consultant group
    def establish_new_group(stud, obj, isConsult)
      # Bracket 0 = normal
      # Bracket 1 = unplaced students
      # Bracket 2 = absent students
      new_team = @consultancy.teams.build(:objective => obj, :bracket => 0)
      new_team.consultant = stud if isConsult
      new_team.save
      new_team.users << stud
      @need_hash[obj.id] -= 1 if obj
    end
    
    def need_placement(student)
      !@consultancy.users.include?(student)
    end
    
    # Choose the consultants
    def choose_consultants
      classSize = @students.count
      @consultantsNeeded = (classSize/4.to_f).ceil
      
      def consult_list_still_needed
        @rank_by_consulting.select{|x| need_placement(x)}
      end
    
      def check_for_final_break
        @consultancy.teams.count >= @consultantsNeeded
      end
      
      def still_needed(obj)
        [(@consultantsNeeded - @consultancy.teams.count), @need_hash[obj.id]].min
      end
      
      # First look at the priority 5 objectives
      @seminar.objectives.select{|y| y.priority_in(@seminar) == 5}.each do |obj|
        temp_consult_list = consult_list_still_needed.select{|x| x.score_on(obj) >= @cThresh}
        hp_consult_list = temp_consult_list.select{|x| x.score_on(obj) < 10 && x.student_has_keys(obj) == 0}
        hp_consult_list << temp_consult_list.select{|x| x.student_has_keys(obj) > 0}
        hp_consult_list << temp_consult_list.select{|x| x.score_on(obj) == 10}
        hp_consult_list.flatten!
        hp_consult_list.take(still_needed(obj)).each do |student|
          establish_new_group(student, obj, true)
        end
        # Can probably get reid of the next block
        consult_list_still_needed.select{|x| x.score_on(obj) >= @cThresh && x.student_has_keys(obj) == 0}.take(still_needed(obj)).each do |student|
          establish_new_group(student, obj, true)
        end
      end
      
      # Then look at students in order of increasing consultant points
      consult_list_still_needed.each do |student|
        return if check_for_final_break  # Needed in case some potential need to be skipped because they're not qualified
        
        # See if student's consultant request will work.
        this_request = student.teach_request_in(@seminar)
        obj = Objective.find(this_request) if this_request
        if obj && @need_hash[this_request] && @need_hash[this_request] > 0 && obj.priority_in(@seminar) > 0
          establish_new_group(student, obj, true)
          next  # So that the requested topic isn't replaced with the teach_option topic
        end
        
        # If the request didn't work out, look at the student's teach_options
        obj = student.teach_options(@seminar).detect{|x| @need_hash[x.id] > 0}
        establish_new_group(student, obj, true) if obj
      end
    end
    

    ## SORT APPRENTICES INTO CONSULTANT GROUPS ##
    
    def prof_list_still_needed
      @prof_list.select{|x| need_placement(x)}
    end
    
    # First, try to place apprentices into groups offering their learn Requests
    def place_apprentices_by_requests
      prof_list_still_needed.each do |student|
        this_request = student.learn_request_in(@seminar)
        if this_request
          team = @consultancy.teams.detect{|x| x.objective.id == this_request && x.has_room}
          team.users << student if team
        end
      end
    end
    
    # Most students probably won't be placed by their requests. 
    def place_apprentices_by_mastery()
      prof_list_still_needed.each do |stud|
        find_placement(stud)
      end
    end
    
    def find_placement(student)
      team = @consultancy.teams.detect{|x| x.has_room && student.objective_students.find_by(:objective => x.objective).obj_ready_and_willing?(@cThresh)}
      team.users << student if team
      return team
    end
    
    def check_for_lone_students
      @consultancy.teams.joins(:users).group('teams.id').having('count(users.id) < 2').destroy_all
      @consultancy.reload
    end
    
    def new_place_for_lone_students
      prof_list_still_needed.reverse.each do |student|
        # First, check whether lone student can be placed into an established group
        if find_placement(student) == nil
          
          # If not, try establishing a new group for that student. This function is smelly, but I'm doing it in this order so that other
          # lone students might also join this group.
          
          # In establishing a new group, try the student's learn_request
          # This should happen if all goes normal.
          request_id = student.learn_request_in(@seminar)
          this_request = Objective.find(request_id) if request_id 
          if this_request && this_request.priority_in(@seminar) > 0
            establish_new_group(student, this_request, false)
          else
            # Last resort is to start a new group with the student's first learn option
            # This is mostly for the case where the student doesn't have a learn_request
            # This can also happen if something happened to the student's learn_request after it was made.
            # For example, the teacher changed the priority to zero.
            obj = student.learn_options(@seminar)[0]
            establish_new_group(student, obj, false) if obj
          end
        end
      end
    end
  
    def assignSGSections()
      # In the future, it might be cool to bring back this feature. Gives each
      # team member a number, which could correspond to different roles of the
      # activity.
      
      @consultancy.teams.each do |team|
        currAssign = 1
        rev[:group].each_with_index do |groupMember, index|
          if rev[:consultant][index] == 0
            rev[:consultant][index] = currAssign
            currAssign = currAssign + 1
          end
        end
      end
    end
    
    def are_some_unplaced
      if prof_list_still_needed.present?
        unplaced_team = @consultancy.teams.create(:bracket => 1)
        prof_list_still_needed.each do |student|
          unplaced_team.users << student
        end
      end
    end
    

end
