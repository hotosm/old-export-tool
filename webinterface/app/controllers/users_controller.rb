class UsersController < ApplicationController
   before_filter :authenticate_user!
   before_filter :admin_user

   def active_users
      @title = t('users.title')
      @users = User.where("confirmed_at IS NOT NULL AND suspended_at IS NULL")
   end

   def locked_users
      @title = t('users.locked.title')
      @locked = User.where("confirmed_at IS NULL OR suspended_at IS NOT NULL")
   end


   def suspend_user
      user = User.find(params[:id])
      user.suspend!("#{t('users.suspended_by')} #{current_user.email}")
      flash[:success] = "#{t('users.flash.success.suspended')} #{user.email}"
      redirect_to :active_users
   end
   
   def unsuspend_user
      user = User.find(params[:id])
      user.unsuspend!
      flash[:success] = "#{t('users.flash.success.unsuspended')} #{user.email}"
      redirect_to :locked_users
   end

end
