class ConsultanciesController < ApplicationController
    
    include DeskConsultants

    def new
        @seminar = Seminar.find(params[:seminar])
        #@library = Library.all.includes( books: :author )
        @sem_studs = @seminar.seminar_students.includes(:user).sort_by{|x| x.user.last_name}
        current_user.update(:current_class => @seminar.id)
        @consultancy = Consultancy.new()
    end
    
    def create
        @seminar = Seminar.find(params[:consultancy][:seminar])
       
        check_if_date_already
        check_if_ten
        
        @sem_studs_hash = setup_sem_studs_hash
        @rank_by_consulting = setup_rank_by_consulting
        @unplaced_students = @rank_by_consulting.dup
        @teams = []
        @unplaced_team = {:consultant_id => nil, :objective_id => nil, :bracket => 1, :user_ids => []}
        @obj_sems = setup_obj_sems_hash
        @need_hash = setup_need_hash
        @objectives = get_objectives
        @score_hash = setup_score_hash
        
        # Each function in these steps is only called once. But I wrote them as
        # separate functions in order to better test the individual pieces.
        choose_consultants
        place_apprentices_by_requests
        place_apprentices_by_mastery
        check_for_lone_students
        new_place_for_lone_students
        create_consultancy
        
        current_user.update!(:current_class => @seminar.id)
        redirect_to consultancy_path(@consultancy, :consultancy_id => @consultancy.id)
    end
    
    def show
        if params[:consultancy_id].present?
            #@library = Library.all.includes( :books => { :author => :bio } )
            @consultancy = Consultancy.find(params[:consultancy_id])
            @teams = @consultancy.teams.includes(:users, :consultant, objective: :topic,)
            @seminar = @consultancy.seminar
        else
            @seminar = Seminar.find(params[:id])
            @consultancy = @seminar.consultancies.order(:created_at).last
            if @consultancy.blank?
                redirect_to new_consultancy_path(:seminar => @seminar.id)
            else
                @teams = @consultancy.teams.includes(:users, :consultant, objective: :topic)
            end
        end
    end
    
    def index
        @seminar = Seminar.find(params[:seminar])
        @consultancies = Consultancy.where(:seminar => @seminar).order(:updated_at)
    end
    
    def destroy
        @consultancy = Consultancy.find(params[:id])
        @seminar = @consultancy.seminar
    
        if @consultancy.destroy
            flash[:success] = "Arrangement Deleted"
            redirect_to consultancies_path(:seminar => @seminar.id)
        end
    end
    
    def edit
        @consultancy = Consultancy.find(params[:id])
        @consultancy.update(:duration => "permanent")
        give_dc_keys
        update_all_consultant_days
        update_last_obj
        redirect_to controller: 'consultancies', action: 'show', id: @consultancy.id, consultancy_id: @consultancy.id
    end
    
    private
        def check_if_date_already
            date = Date.today
            old_consult = @seminar.consultancies.find_by(:created_at => date.midnight..date.end_of_day)
            old_consult.destroy if old_consult
        end
        
        def check_if_ten
            if @seminar.consultancies.count > 9
                @seminar.consultancies.order('created_at asc').first.destroy
            end
        end
        
        def give_dc_keys
          @consultancy.teams.each do |team|
            ObjectiveStudent.where(:user_id => team.user_ids, :objective_id => team.objective_id).each do |obj_stud|
              obj_stud.update_keys("dc", 2) unless obj_stud.points_this_term == 10
            end
          end
        end
        
        def update_all_consultant_days
            all_consultants = @consultancy.all_consultants
            this_seminar = @consultancy.seminar
            this_date = @consultancy.created_at
            SeminarStudent
                .where(:seminar => this_seminar, :user => all_consultants)
                .update_all(:last_consultant_day => this_date)
        end
        
        def update_last_obj
            this_sem = @consultancy.seminar
            @consultancy.teams.each do |team|
                SeminarStudent.where(:user => team.user_ids, :seminar => this_sem).update(:last_obj => team[:objective_id])
            end
        end
end
