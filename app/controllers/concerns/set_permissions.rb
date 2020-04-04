module SetPermissions
    extend ActiveSupport::Concern
    
    include SessionsHelper
    
    def set_permissions(target)
      thisId = target.user_id
      this_user = current_user
      if this_user
          if this_user.type == "Admin"
              @assign_permission = "admin"
          else
            if thisId == this_user.id
              @assign_permission = "this_user"
            else
              @assign_permission = "other"
            end
          end
      else
          @assign_permission = "other"
      end

      if thisId == 0
        @created_by = "Mr. Z School"
      else
        @created_by = User.find(thisId).full_name_with_title
      end
    end
    
    
    
end
