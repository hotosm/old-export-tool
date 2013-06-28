require 'spec_helper'

describe UsersController do

   render_views

   describe "POST 'suspend_user'" do
      before(:each) do
         @user_test = FactoryGirl.create(:user, :email => 'ck41@geofabrik.de')
         @user = FactoryGirl.create(:user)
         @user.toggle!(:admin)
         sign_in @user
      end

      it "should suspend a user" do
         post :suspend_user, :id => @user_test.id
         User.find(@user_test.id).suspended?.should be_true
      end

      it "should unsuspend a user" do
         post :unsuspend_user, :id => @user_test.id
         User.find(@user_test.id).suspended?.should_not be_true
      end

   end
   
   describe "GET 'active_users'" do

      describe "failure for unsigned-in non-admin users" do
         it "should not be successfull" do
            get :active_users
            response.should_not be_success
         end
         it "should be redirected to sign_in page" do
            get :active_users
            response.should redirect_to(new_user_session_path)
         end
      end
      
      describe "failure for non-admin users" do
         before(:each) do
            @user = FactoryGirl.create(:user)
            sign_in @user
         end
         it "should not be successfull" do
            get :active_users
            response.should_not be_success
         end
         it "should be redirected to sign_in page" do
            get :active_users
            response.should redirect_to(root_path)
         end
      end

      describe "success" do
         before(:each) do
            @user = FactoryGirl.create(:user)
            @user.toggle!(:admin)
            sign_in @user
         end

         it "should be successfull" do
            {:get => "/active_users"}.should route_to(:controller => "users", :action => "active_users")
            response.should be_success
         end

         it "should render the right template" do
            get "active_users"
            response.should render_template("users/active_users")
         end


         it "should have the right title" do
            get :active_users
            response.should have_selector("h1", :content => "Users")
         end
      end

   end

   describe "GET 'locked_users'" do
      describe "success" do
         before(:each) do
            @user = FactoryGirl.create(:user)
            @user.toggle!(:admin)
            sign_in @user
         end

         it "should be successfull" do
            get :locked_users
            response.should be_success
         end

         it "should have the right title" do
            get :locked_users
            response.should have_selector("h1", :content => "Locked Users")
         end
      end
   end

end
