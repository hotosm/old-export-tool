require 'spec_helper'

describe JobsController do
   after(:all) do
      @dir = Dir.open(Upload.upload_directory)
      @dir.each do |file|
         if File.directory? file
         else
            if (( /^preset/ =~ file ) or
                ( /^tagtransform/ =~ file ) or
                ( /^translation/ =~ file)
            )
               File.delete "#{Upload.upload_directory}/#{file}"
               puts "DELETED #{Upload.upload_directory}/#{file}"
            else
               puts "NOT DELETED #{Upload.upload_directory}/#{file}"
            end
         end
      end
   end

   before(:each) do
      @user = FactoryGirl.create(:user)

      Region.connection.execute(
              "insert into regions (internal_name,name,created_at,updated_at,polygon) values('caribbean','caribbean',now(),now(),st_setsrid(st_geomfromtext('POLYGON((-60.428790 9.782485,-61.578630 9.946747,-61.998330 9.997709,-62.044320 10.427730,-61.687870 10.851500,-63.700100 11.381790,-67.293360 11.471950,-68.730660 11.742270,-69.535550 12.169730,-70.075980 12.304580,-70.374940 12.360740,-79.194240 15.481480,-83.241690 18.799220,-86.967180 23.135650,-83.149700 23.684350,-79.493200 24.167830,-79.735720 28.133000,-69.157780 26.580490,-55.996840 16.211640,-60.428790 9.782485))'),4326))"
      )
      @region = Region.last
   end

   after(:each) do
      User.destroy_all
   end



   render_views

   describe "GET 'index'" do
      before(:each) do

         @job1 = FactoryGirl.build(:job, :user_id => @user.id)
         @job1.save!
         @job2 = FactoryGirl.build(:job, :user_id => @user.id)
         @job2.save!
         @job3 = FactoryGirl.build(:job, :user_id => @user.id)
         @job3.save!

         @jobs = [@job1, @job2, @job3];
      end

      it "should be successfull" do
         get :index
         response.should be_success
      end

      it "should have the right title" do
         get :index
         response.should have_selector("title", :content => "Jobs")
      end

      it "should have a based upon default tags hint" do
         get :index
         response.should have_selector("th", :content => "Based upon Presetfile")
         response.should have_selector("td", :content => "default tags only")
      end

      it "should have an element for each job" do
         get :index
         @jobs[0..2].each do |job|
            response.should have_selector("td", :content => job.name)
         end
      end


      describe "signed-in users" do
         it "should have delete links for signed-in users" do
            sign_in @user
            @attr = {
               :name => "My new job",
               :lonmin => -72.6,
               :latmin => 18,
               :lonmax => -72.04, 
               :latmax => 19
            }

            @attr_uploads = {
               :default_tags => 1,
               :presetfile   => 0,
               :tagtransform => nil,
               :translation  => 0   
            }

            post :wizard_configuration_create, :uploads => @attr_uploads, :job => @attr

            get 'index'
            response.should have_selector('img', :class => 'delicon')
         end
      end

      describe "not-signed-in users" do
      it "should NOT have delete links for signed-in users" do
         sign_in @user
         @attr = {
            :name => "My new job",
            :lonmin => -72.6,
            :latmin => 18,
            :lonmax => -72.04, 
            :latmax => 19
         }

         @attr_uploads = {
            :default_tags => 1,
            :presetfile   => 0,
            :tagtransform => nil,
            :translation  => 0   
         }

         post :wizard_configuration_create, :uploads => @attr_uploads, :job => @attr

         sign_out @user
         get 'index'
         response.should_not have_selector('img', :class => 'delicon')
      end

      end
   end
   
   
   describe "GET 'show'" do
      before(:each) do
         @job = FactoryGirl.build(:job, :user_id => @user.id)
         @job.save!
      end

      it "should be successfull" do
         get :show, :id => @job
         response.should be_success
      end

      it "should find the right job" do
         get :show, :id => @job
         assigns(:job).should == @job
      end

      it "should have the right title" do
         get :show, :id => @job
         response.should have_selector("title", :content => @job.name)
      end

      it "should include the job's name" do
         get :show, :id => @job
         response.should have_selector("h1", :content => @job.name)
      end

      it "should have default tags" do
         get :show, :id => @job
         response.should have_selector("td", :content => I18n.translate('jobs.based_upon.default_tags'))
      end

      it "should show linked upload files" do
         get :show, :id => @job
         response.should have_selector("h2", :content => "Job Configuration")
      end
   end


   describe "GET 'newrun'" do
      before(:each) do
         @job = FactoryGirl.build(:job, :user_id => @user.id)
         @job.save!
      end

      it "should create a run for signed-in users" do
         sign_in @user
         @runs = Run.where("job_id = ?", @job.id)
         @runs.each do |run|
            run.state = 'success'
            run.save
         end

         lambda do
            get :newrun, :job_id => @job.id
         end.should change(Run, :count).by(1)
      end

      it "should NOT create a run for NOT-signed-in users" do
         @runs = Run.where("job_id = ?", @job.id)
         @runs.each do |run|
            run.state = 'success'
            run.save
         end

         lambda do
            get :newrun, :job_id => @job.id
         end.should change(Run, :count).by(0)
      end


   end


   describe "GET 'wizard_area'" do

      describe "signed-in users" do
         before(:each) do
            sign_in @user
         end

         it "should be successful" do
            get 'wizard_area'
            response.should be_success
         end
         it "should have the right title" do
            get 'wizard_area'
            response.should have_selector("title", :content => "New Export Job")
         end
         it "should have a map" do
            get 'wizard_area'
            response.should have_selector("div", :id => "map")
         end

         it "should have a Job Name input field" do
            get 'wizard_area'
            response.should have_selector('input', :id => "job_name")
         end
      end

      describe "unsigned-in users" do
         it "should redirect to sign_in path" do
            get 'wizard_area', :locale => I18n.default_locale
            response.should redirect_to(new_user_session_path) 
         end
      end
   end

   describe "POST 'wizard_configuration'" do
      before(:each) do
         sign_in @user

         @upload_preset          = FactoryGirl.create(:upload)
         @upload_tagtransform    = FactoryGirl.create(:upload, :uptype => 'tagtransform')
         @upload_translation     = FactoryGirl.create(:upload, :uptype => 'translation')
      end


      it "should be successfull" do
         post :wizard_configuration, @job
         response.should be_success
      end

      it "should have a checkbox for default tags" do
         post :wizard_configuration, @job
         response.should have_selector('input', :type => "checkbox", :name => "uploads[default_tags]")
      end
      
      it "should have a select box for preset files" do
         post :wizard_configuration, @job
         response.should have_selector('select', :name => "uploads[presetfile]")
      end
      
      it "should have a check box for tagtransform files" do
         post :wizard_configuration, @job
         response.should have_selector('input', :type => "checkbox", :name => "uploads[tagtransform][]")
      end

      it "should have a select box for translation files" do
         post :wizard_configuration, @job
         response.should have_selector('select', :name => "uploads[translation]")
      end
   end


   describe "POST 'wizard_configuration_create'" do
      before(:each) do
         sign_in @user

         @attr = {
            :user_id => @user.id,
            :name    => "My new job",
            :lonmin  => -72.6,
            :latmin  => 18,
            :lonmax  => -72.04, 
            :latmax  => 19
         }

         @up_preset       = FactoryGirl.create(:upload, :uptype => 'preset')
         @up_tagtransform = FactoryGirl.create(:upload, :uptype => 'tagtransform')
         @up_translation  = FactoryGirl.create(:upload, :uptype => 'translation')
      end

      describe "only default tags, no preset file" do
         before(:each) do
            @attr_uploads = {
               :default_tags  => 1,
               :presetfile    => 0,
               :tagtransform  => nil,
               :translation   => 0,   
            }
         end

         it "should be successful request" do
            post :wizard_configuration_create, :uploads => @attr_uploads, :job => @attr
            response.should redirect_to(job_path(assigns(:job)))
         end

         it "should save the default tags" do
            @count = 0
            Tag.default_tags.each do |key, value|
               value.each_key do |g|
                  @count = @count + 1
               end
            end
            lambda do
               post :wizard_configuration_create, :uploads => @attr_uploads, :job => @attr
            end.should change(Tag, :count).by(@count)
         end

         it "should save the job" do
            lambda do
               post :wizard_configuration_create, :uploads => @attr_uploads, :job => @attr
            end.should change(Job, :count).by(1)
         end

         it "should save a new run" do
            lambda do
               post :wizard_configuration_create, :uploads => @attr_uploads, :job => @attr
            end.should change(Run, :count).by(1)
         end
      end

      describe "with default tags and preset file" do
         before(:each) do
            @dir = Dir.open(Upload.upload_directory)
            @file = fixture_file_upload('files/test.xml', 'text/xml')
            #@file = fixture_file_upload('/preset.xml', 'text/xml')
            
            @attr_uploads = {
               :default_tags  => 1, 
               :presetfile    => @up_preset.id,
               :tagtransform  => nil,
               :translation   => 0,   
            }
         end

         it "should be successful request" do
            post :wizard_configuration_create, :uploads => @attr_uploads, :job => @attr
            response.should redirect_to(job_path(assigns(:job)))
         end

         it "should save the job" do
            lambda do
               post :wizard_configuration_create, :uploads => @attr_uploads, :job => @attr
            end.should change(Job, :count).by(1)
         end

         it "should save a new run" do
            lambda do
               post :wizard_configuration_create, :uploads => @attr_uploads, :job => @attr
            end.should change(Run, :count).by(1)
         end
      end

      it "should save the default and uploaded tags" do
         ju2_file = fixture_file_upload('/HAITI_OSM_STM020_presets_v1.93_Hot_Exports.xml', 'text/xml')
         
         ju2_upload = Upload.new
         ju2_upload.name = 'HAITI OSM preset file'
         ju2_upload.uptype = 'preset'
         ju2_upload.uploadfile = 'HAITI OSM uploadfile'
         ju2_upload.complete_save(ju2_file)

         ju2_attr_uploads = {
            :default_tags => 1,
            :presetfile   => ju2_upload.id,
            :tagtransform => nil,
            :translation  => 0
         }

         count          = 0 
         count_uploaded = 0
         count_default  = 0

         Tag.default_tags.each do |key, value|
            value.each_key do |g|
               count_default = count_default + 1
            end
         end

         content = IO.read(Rails.root.join("spec/fixtures/HAITI_OSM_STM020_presets_v1.93_Hot_Exports.xml"))
         uploaded_tags = Tag.from_xml(content)
         uploaded_tags.each do |key, value|
            value.each_key do |g|
               count_uploaded = count_uploaded + 1
            end
         end

         tags = Tag.join_taghashes(Tag.default_tags, uploaded_tags)
         tags.each do |key, value|
            value.each_key do |g|
               count = count + 1
            end
         end

         lambda do
            post :wizard_configuration_create, :uploads => ju2_attr_uploads, :job => @attr
         end.should change(Tag, :count).by(count)

      end


      it "should save the default and uploaded tags (modified preset 2012-10)" do
         ju3_file = fixture_file_upload('/building.xml', 'text/xml')
         
         ju3_upload = Upload.new
         ju3_upload.name = 'building preset file'
         ju3_upload.uptype = 'preset'
         ju3_upload.uploadfile = 'building uploadfile'
         ju3_upload.complete_save(ju3_file)

         ju3_attr_uploads = {
            :default_tags => 1,
            :presetfile   => ju3_upload.id,
            :tagtransform => nil,
            :translation  => 0
         }

         count          = 0 
         count_uploaded = 0
         count_default  = 0

         Tag.default_tags.each do |key, value|
            value.each_key do |g|
               count_default = count_default + 1
            end
         end

         content = IO.read(Rails.root.join("spec/fixtures/building.xml"))
         uploaded_tags = Tag.from_xml(content)
         uploaded_tags.each do |key, value|
            value.each_key do |g|
               count_uploaded = count_uploaded + 1
            end
         end

         tags = Tag.join_taghashes(Tag.default_tags, uploaded_tags)
         tags.each do |key, value|
            value.each_key do |g|
               count = count + 1
            end
         end

         lambda do
            post :wizard_configuration_create, :uploads => ju3_attr_uploads, :job => @attr
         end.should change(Tag, :count).by(count)

      end

      it "should save tagtransform files" do
         up_preset       = FactoryGirl.create(:upload, :uptype => 'preset')
         up_tagtransform = FactoryGirl.create(:upload, :uptype => 'tagtransform')
         up_translation  = FactoryGirl.create(:upload, :uptype => 'translation')
         
         attr_uploads = {
            :default_tags => 0,
            :presetfile   => 0,
            :tagtransform => [up_tagtransform.id],
            :translation  => 0
         }

         lambda do
            post :wizard_configuration_create, :uploads => attr_uploads, :job => @attr
         end.should change(JobsUploads, :count).by(1)

      end

      it "should save translation files" do
         up_preset       = FactoryGirl.create(:upload, :uptype => 'preset')
         up_tagtransform = FactoryGirl.create(:upload, :uptype => 'tagtransform')
         up_translation  = FactoryGirl.create(:upload, :uptype => 'translation')
         
         attr_uploads = {
            :default_tags => 0,
            :presetfile   => 0,
            :tagtransform => nil,
            :translation  => up_translation.id
         }

         lambda do
            post :wizard_configuration_create, :uploads => attr_uploads, :job => @attr
         end.should change(JobsUploads, :count).by(1)

      end

      it "should save preset and translation files" do
         up_preset       = FactoryGirl.create(:upload, :uptype => 'preset')
         up_tagtransform = FactoryGirl.create(:upload, :uptype => 'tagtransform')
         up_translation  = FactoryGirl.create(:upload, :uptype => 'translation')
         
         attr_uploads = {
            :default_tags => 0,
            :presetfile   => up_preset,
            :tagtransform => nil,
            :translation  => up_translation.id
         }

         lambda do
            post :wizard_configuration_create, :uploads => attr_uploads, :job => @attr
         end.should change(JobsUploads, :count).by(2)
      end

      it "should save tagtransform files" do
         up_preset       = FactoryGirl.create(:upload, :uptype => 'preset')
         up_tagtransform = FactoryGirl.create(:upload, :uptype => 'tagtransform')
         up_translation  = FactoryGirl.create(:upload, :uptype => 'translation')
         
         attr_uploads = {
            :default_tags => 0,
            :presetfile   => 0,
            :tagtransform => [up_tagtransform.id],
            :translation  => 0
         }

         lambda do
            post :wizard_configuration_create, :uploads => attr_uploads, :job => @attr
         end.should change(JobsUploads, :count).by(1)
      end

      it "should save three tagtransform files" do
         up_preset       = FactoryGirl.create(:upload, :uptype => 'preset')
         up_tagtr1 = FactoryGirl.create(:upload, :uptype => 'tagtransform')
         up_tagtr2 = FactoryGirl.create(:upload, :uptype => 'tagtransform')
         up_tagtr3 = FactoryGirl.create(:upload, :uptype => 'tagtransform')
         up_translation  = FactoryGirl.create(:upload, :uptype => 'translation')
         
         attr_uploads = {
            :default_tags => 0,
            :presetfile   => 0,
            :tagtransform => [up_tagtr1.id, up_tagtr2.id, up_tagtr3.id],
            :translation  => 0
         }

         lambda do
            post :wizard_configuration_create, :uploads => attr_uploads, :job => @attr
         end.should change(JobsUploads, :count).by(3)
      end

   end  
   
   describe 'invisible' do
      before(:each) do
         @user2 = FactoryGirl.create(:user, :email => 'ck44@geofabrik.de')
         @job = FactoryGirl.build(:job, :user_id => @user.id)
         @job.save!
      end

      it "should make an job invisible in job index" do
         sign_in @user
         post :invisible, :id => @job.id
         get :index, :deleted => 'y'
         response.should have_selector("a", :content => "Restore")
         sign_out @user
      end

      it "should only be allowed to job owner or admins to make a job invisible" do
         sign_in @user2
         post :invisible, :id => @job.id
         response.should_not be_success
         sign_out @user2
      end
   end

   describe 'restore' do
      before(:each) do
         @user2 = FactoryGirl.create(:user, :email => 'ck44@geofabrik.de')
         @job = FactoryGirl.build(:job, :user_id => @user.id)
         @job.save!
         sign_in @user
      end

      it "should make an job visible in job index" do
         @job.toggle(:visible)

         post :restore, :id => @job.id
         get :index, :deleted => 'y'
         response.should_not have_selector("a", :content => "Restore")
         response.should have_selector("td", :content => @job.name)
      end
      
      it "should only be allowed to job owner or admins to make a job invisible" do
         sign_in @user2
         post :restore, :id => @job.id
         response.should_not be_success
         sign_out @user2
      end
   end

end
