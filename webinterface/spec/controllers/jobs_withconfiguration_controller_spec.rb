require 'spec_helper'

describe JobsController do
   after(:all) do
      @dir = Dir.open(Upload.upload_directory)
      @dir.each do |file|
         if File.directory? file
         else
            if (( /^preset/ =~ file ) or
                ( /^tagtransform/ =~ file )
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
      sign_in @user

      Region.connection.execute(
               "insert into regions (id,internal_name,name,created_at,updated_at,polygon) values(2, 'caribbean','caribbean',now(),now(),st_setsrid(st_geomfromtext('POLYGON((-60.428790 9.782485,-61.578630 9.946747,-61.998330 9.997709,-62.044320 10.427730,-61.687870 10.851500,-63.700100 11.381790,-67.293360 11.471950,-68.730660 11.742270,-69.535550 12.169730,-70.075980 12.304580,-70.374940 12.360740,-79.194240 15.481480,-83.241690 18.799220,-86.967180 23.135650,-83.149700 23.684350,-79.493200 24.167830,-79.735720 28.133000,-69.157780 26.580490,-55.996840 16.211640,-60.428790 9.782485))'),4326))"
      )
      @region = Region.last
   end


   render_views

   describe "newwithconfiguration" do

      describe "failure" do
         it "should redirect to new if no job id is given" do
            get 'newwithconfiguration'
            response.should redirect_to(wizard_area_path)
         end
         it "should have a flash message" do
            get 'newwithconfiguration'
            flash[:error].should =~ /No job id given/i
         end
      end

      describe "success" do
         before(:each) do
            @job = FactoryGirl.build(:job, :user_id => @user.id)
            @job.save!
         end
         it "should be successful" do
            get 'newwithconfiguration', :job_id => @job.id
            response.should be_success
         end
         it "should have the right title" do
            get 'newwithconfiguration', :job_id => @job.id
            response.should have_selector("title", :content => "New Export Job (with fixed Configuration)")
         end
         it "should have a map" do
            get 'newwithconfiguration', :job_id => @job.id
            response.should have_selector("div", :id => "map")
         end
      end

   end
 
 
   describe "newwithconfiguration_create" do
      before(:each) do
         @oldjob = FactoryGirl.build(:job, :user_id => @user.id)
         @oldjob.save!
         @oldtags = FactoryGirl.create(:tag, :job => @oldjob)
         @attr = {
            :name => "My new job",
            :lonmin => -77,
            :latmin => 19,
            :lonmax => -76, 
            :latmax => 20
         }
      end

      it "should save the job" do
         lambda do
            post :newwithconfiguration_create, :job => @attr, :old_job_id => @oldjob.id
         end.should change(Job, :count).by(1)
      end

      it "should save a new run" do
         lambda do
            post :newwithconfiguration_create, :job => @attr, :old_job_id => @oldjob.id
         end.should change(Run, :count).by(1)
      end

      it "should create a new job with old tags" do
         lambda do
            post :newwithconfiguration_create, :job => @attr, :old_job_id => @oldjob.id
         end.should change(Tag, :count).by(Tag.where('job_id = ?', @oldjob.id).size)
      end
      
      it "should create a new job with old uploads" do
         up_preset      = FactoryGirl.create(:upload, :uptype => 'preset')
         up_tagtr1      = FactoryGirl.create(:upload, :uptype => 'preset')
         up_tagtr2      = FactoryGirl.create(:upload, :uptype => 'preset')
         up_translation = FactoryGirl.create(:upload, :uptype => 'preset')

         myjob = FactoryGirl.build(:job, :user_id => @user.id)
         myjob.save!
         myjob.uploads << up_preset
         myjob.uploads << up_tagtr1
         myjob.uploads << up_tagtr2
         myjob.uploads << up_translation
         myjob.save!


         lambda do
            post :newwithconfiguration_create, :job => @attr, :old_job_id => myjob.id
         end.should change(JobsUploads, :count).by(JobsUploads.where('job_id = ?', myjob.id).size)
      end
   end

end
