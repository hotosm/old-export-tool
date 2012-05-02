require 'spec_helper'

describe JobsController do
   render_views


   describe "GET 'newrun'" do
      before(:each) do
         @job = Factory(:job)
      end

      it "should create a run" do
         @runs = Run.where("job_id = ?", @job.id)
         @runs.each do |run|
            run.state = 'success'
            run.save
         end

         lambda do
            get :newrun, :job_id => @job.id
         end.should change(Run, :count).by(1)
      end
   end


   describe "GET 'new'" do
      it "should be successful" do
         get 'new'
         response.should be_success
      end
      it "should have the right title" do
         get 'new'
         response.should have_selector("title", :content => "New Export Job")
      end
      it "should have a map" do
         get 'new'
         response.should have_selector("div", :id => "map")
      end
   end


   describe "POST 'create'" do
      before(:each) do
         @attr = {
            :name => "My new job",
            :lonmin => 12.2,
            :latmin => 33.3,
            :lonmax => 15.4, 
            :latmax => 34.5
         }
      end


      describe "success" do
         it "should create a job" do
            lambda do
               post :create, :job => @attr
            end.should change(Job, :count).by(1)
         end

         it "should have a success message" do
            post :create, :job => @attr
            flash[:success].should =~ /success/i
         end

         it "should start a run of the job" do
            lambda do
               post :create, :job => @attr
            end.should change(Run, :count).by(1)
         end

      end

      describe "failure" do
         it "should not create a job" do
            lambda do
               post :create, :job => @attr.merge(:name => "")
            end.should change(Job, :count).by(0)
         end

         it "should have a error message" do
            post :create, :job => @attr.merge(:name => "")
            flash[:error].should =~ /No job saved/i
         end
      end
   end


   describe "POST 'wizard_area'" do
      it "should be successfull" do
         post :wizard_area, @job
         response.should be_success
      end


   end

   describe "POST 'tagupload'" do
      before(:each) do
         @attr = {
            :name => "My new job",
            :lonmin => 12.2,
            :latmin => 33.3,
            :lonmax => 15.4, 
            :latmax => 34.5
         }
         @file = fixture_file_upload('/preset.xml', 'text/xml')
      end

      it "can upload a preset file" do
         post :tagupload, :upload => @file
         response.should be_success
      end


      it "should save the default tags" do
         @count = 0
         Tag.default_tags.each do |key, value|
            value.each_key do |g|
               @count = @count + 1
            end
         end
         lambda do
            post :tagupload, :upload => @file, :job => @attr
         end.should change(Tag, :count).by(@count)
      end

      it "should save the job" do
         lambda do
            post :tagupload, :upload => @file, :job => @attr
         end.should change(Job, :count).by(1)
      end


      it "should save a new run" do
         lambda do
            post :tagupload, :upload => @file, :job => @attr
         end.should change(Run, :count).by(1)
      end

   end
  
  
   describe "newwithtags" do

      describe "failure" do
         it "should redirect to new if no job id is given" do
            get 'newwithtags'
            response.should redirect_to(newjob_path)
         end
         it "should have a flash message" do
            get 'newwithtags'
            flash[:error].should =~ /No job id given/i
         end
      end

      describe "success" do
         before(:each) do
            @job = Factory(:job)
         end
         it "should be successful" do
            get 'newwithtags', :job_id => @job.id
            response.should be_success
         end
         it "should have the right title" do
            get 'newwithtags', :job_id => @job.id
            response.should have_selector("title", :content => "New Export Job (with given Tags)")
         end
         it "should have a map" do
            get 'newwithtags', :job_id => @job.id
            response.should have_selector("div", :id => "map")
         end
      end

   end
 
 
   describe "newwithtags_create" do
      before(:each) do
         @oldjob = Factory(:job)
         @oldtags = Factory(:tag)
         @attr = {
            :name => "My new job",
            :lonmin => 12.2,
            :latmin => 33.3,
            :lonmax => 15.4, 
            :latmax => 34.5
         }
      end

      it "should save the job" do
         lambda do
            post :newwithtags_create, :job => @attr, :old_job_id => @oldjob.id
         end.should change(Job, :count).by(1)
      end

      it "should save a new run" do
         lambda do
            post :newwithtags_create, :job => @attr, :old_job_id => @oldjob.id
         end.should change(Run, :count).by(1)
      end

      it "should create a new job with old tags" do
         lambda do
            post :newwithtags_create, :job => @attr, :old_job_id => @oldjob.id
         end.should change(Tag, :count).by(Tag.where('job_id = ?', @oldjob.id).size)
      end
   end
 
   
   describe "GET 'show'" do
      before(:each) do
         @job = Factory(:job)
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
   end
 

   describe "GET 'index'" do
      before(:each) do
         @job1 = Factory(:job)
         @job2 = Factory(:job)
         @job3 = Factory(:job)
         @jobs = [@job1, @job2, @job3];
      end

      it "should be successfull" do
         get :index
         response.should be_success
      end

      it "should have the right title" do
         get :index
         response.should have_selector("title", :content => "All Jobs")
      end

      it "should have an element for each job" do
         get :index
         @jobs[0..2].each do |job|
            response.should have_selector("td", :content => job.name)
         end
      end
   end

end
