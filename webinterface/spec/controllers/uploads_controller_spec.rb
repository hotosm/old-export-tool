require 'spec_helper'

describe UploadsController do
   after(:all) do
      @dir = Dir.open(Upload.upload_directory)
      @dir.each do |file|
         if File.directory? file
         else
            # puts "delete #{Upload.upload_directory}/#{file}"
            # XXX File.delete "#{Upload.upload_directory}/#{file}"
         end
      end
   end

   render_views

   describe "GET 'new'" do
      before(:each) do
         @user = FactoryGirl.create(:user)
         sign_in @user
      end

      it "returns http success" do
         get 'new'
         response.should be_success
      end

      it "should have the right title" do
         get 'new'
         response.should have_selector('title', :content => "New Upload")
      end

      it "should have a name input field" do
         get 'new'
         response.should have_selector('input', :id => "upload_name")
      end
      
      it "should have a upload type select box" do
         get 'new'
         response.should have_selector('select', :id => "upload_uptype")
      end

      it "should have a upload field" do
         get 'new'
         response.should have_selector('input', :id => "upload_uploadfile")
      end
   end


   describe "POST 'create'" do
      before(:each) do
         @user = FactoryGirl.create(:user)
         sign_in @user
      end

      describe "success" do 
         before(:each) do
            @dir = Dir.open(Upload.upload_directory)
            @file = fixture_file_upload('files/test.xml', 'text/xml')
            @attr = {
               :name       => 'new preset file',
               :uptype     => 'preset',
               :uploadfile => @file
            }
         end

         it "should save a upload entry in the database" do
            lambda do
               post :create, :upload => @attr
            end.should change(Upload, :count).by(1)
         end

         it "should save a file in the file system" do

            count = 0
            @dir.each do |f|
               count += 1
            end

            post :create, :upload => @attr

            count2 = 0
            @dir.each do |f|
               count2 += 1
            end

            count2.should == (count + 1)
         end
      end

      describe "failure" do
         before(:each) do
            @dir = Dir.open(Upload.upload_directory)
            @file = fixture_file_upload('files/corrupt.xml', 'text/xml')
            @attr = {
               :name       => 'new preset file',
               :uptype     => 'preset',
               :uploadfile => @file
            }
         end

         it "should not save a upload entry in the database" do
            lambda do
               post :create, :upload => @attr
            end.should change(Upload, :count).by(0)
         end

         it "should not save a file in the file system" do

            count = 0
            @dir.each do |f|
               count += 1
            end

            post :create, :upload => @attr

            count2 = 0
            @dir.each do |f|
               count2 += 1
            end

            count2.should == (count + 0)
         end

         it "should display an error message" do
            post :create, :upload => @attr
            response.should have_selector("div", :class => "flash error", :content => "XML parsing failed")
         end
      end
   end

   describe "GET 'invisible'" do
      before(:each) do
         @user = FactoryGirl.create(:user)
         sign_in @user
      end

      before(:each) do
         @dir = Dir.open(Upload.upload_directory)
         @file = fixture_file_upload('files/test.xml', 'text/xml')
         @attr = {
            :name       => 'test invisible',
            :uptype     => 'preset',
            :uploadfile => @file
         }
         post :create, :upload => @attr
         @my_upload = Upload.last
      end


      it "returns http success" do
         get 'invisible', :id => @my_upload.id
         response.should redirect_to(uploads_presets_path)
      end
   

      it "changes visibility from true to false" do
         get 'invisible', :id => @my_upload.id
         @my_upload = Upload.find(@my_upload.id)
         @my_upload.visibility.should_not be_true
      end
   end


   describe "GET 'restore'" do
      before(:each) do
         @user = FactoryGirl.create(:user)
         sign_in @user

         @dir = Dir.open(Upload.upload_directory)
         @file = fixture_file_upload('files/test.xml', 'text/xml')
         @attr = {
            :name       => 'test invisible',
            :uptype     => 'preset',
            :uploadfile => @file
         }
         post :create, :upload => @attr
         @my_upload = Upload.last
         get 'invisible', :id => @my_upload.id
         @my_upload = Upload.find(@my_upload.id)
      end


      it "returns http success" do
         get 'restore', :id => @my_upload.id
         response.should redirect_to(uploads_presets_path)
      end
   

      it "changes visibility from false to true" do
         @my_upload.visibility.should_not be_true

         get 'restore', :id => @my_upload.id
         @my_upload = Upload.find(@my_upload.id)
         @my_upload.visibility.should be_true
      end
   end


   describe "GET 'index'" do
      it "returns http success" do
         get 'index'
         response.should be_success
      end

      it "should have the right title" do
         get 'index'
         response.should have_selector('title', :content => "Configuration")
      end
   end

   describe "Get 'presets'" do
      before(:each) do
         @user = FactoryGirl.create(:user)
         sign_in @user

         @dir = Dir.open(Upload.upload_directory)
         @file = fixture_file_upload('files/test.xml', 'text/xml')
         @attr = {
            :name =>       'new preset file',
            :uptype =>     'preset',
            :uploadfile => @file
         }
         post :create, :upload => @attr
         sign_out @user
      end


      it "returns http success" do
         get 'presets'
         response.should be_success
      end

      it "should have check tags links for preset type" do
         get 'presets'
         response.should have_selector('img', :class => 'checktags_icon')
      end
      
      it "should have delete links for signed_in users" do
         sign_in @user
         get 'presets'
         response.should have_selector('img', :class => 'delicon')
      end
   end

   describe "Get 'tagtransforms'" do
      before(:each) do
         @user = FactoryGirl.create(:user)
         sign_in @user

         @dir = Dir.open(Upload.upload_directory)
         @file = fixture_file_upload('files/test.xml', 'text/xml')
         @attr = {
            :name =>       'new tagtransform file',
            :uptype =>     'tagtransform',
            :uploadfile => @file
         }
         post :create, :upload => @attr
         sign_out @user
      end

      it "returns http success" do
         get 'tagtransforms'
         response.should be_success
      end

      it "should have delete links for signed in users" do
         sign_in @user
         get 'tagtransforms'
         response.should have_selector('img', :class => 'delicon')
      end
   end

   describe "Get 'translations'" do
      before(:each) do
         @user = FactoryGirl.create(:user)
         sign_in @user

         @dir = Dir.open(Upload.upload_directory)
         @file = fixture_file_upload('files/test.xml', 'text/xml')
         @attr = {
            :name =>       'new translation file',
            :uptype =>     'translation',
            :uploadfile => @file
         }
         post :create, :upload => @attr
         sign_out @user
      end

      it "returns http success" do
         get 'translations'
         response.should be_success
      end

      it "should have delete links" do
         sign_in @user
         get 'translations'
         response.should have_selector('img', :class => 'delicon')
      end
   end


   describe "Get 'checktags'" do
      before(:each) do
         @user = FactoryGirl.create(:user)
         sign_in @user

         @dir = Dir.open(Upload.upload_directory)
         @file = fixture_file_upload('files/test.xml', 'text/xml')
         @attr = {
            :name =>       'new preset file',
            :uptype =>     'preset',
            :uploadfile => @file
         }
         post :create, :upload => @attr
         @upload = Upload.last
      end


      it "returns http success" do
         get 'checktags', :id => @upload.id
         response.should be_success
      end

      it "should have a title" do
         get 'checktags', :id => @upload.id
         response.should have_selector('title', :content => "Tag Check")
      end

      it "should have the table head 'Tag' and 'Geometrytype'" do
         get 'checktags', :id => @upload.id
         response.should have_selector('th', :content => "Tag")
         response.should have_selector('th', :content => "Geometrytype")
      end

   end
end
