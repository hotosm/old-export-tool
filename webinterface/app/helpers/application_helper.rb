module ApplicationHelper

   def admin_user
      # redirect_to(signin_path) unless current_user.active?
      unless current_user.admin?
         flash[:error] = "Access to user administration only for admin users."
         redirect_to(root_path)
      end
   end

   def user_right_deletion? my_obj
      if !user_signed_in?
         return false
      elsif current_user.admin?
         return true
      elsif (my_obj.user_id == current_user.id)
         return true
      else
         return false
      end
   end

end
