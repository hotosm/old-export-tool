require 'spec_helper'

describe "Jobs" do

   describe "new job" do
      before(:each) do
         @region = Factory(:region)
      end

      it "should have the right path" do
         get newjob_path
         response.status.should be(200)
      end


#      describe "failure" do
#        it "should not make a new job" do
#            lambda do
#               visit newjob_path
#               fill_in "Job Name",        :with => ""
#               fill_in "Min. Longitude",  :with => ""
#               fill_in "Min. Latitude",   :with => ""
#               fill_in "Max. Longitude",  :with => ""
#               fill_in "Max. Latitude",   :with => ""
#               click_button
#               response.should render_template('jobs/new')
#               response.should have_selector("div#error_explanation")
#            end.should_not change(Job, :count)
#         end
#      end
#
#      describe "success" do
#        it "should make a new job" do
#            lambda do
#               visit newjob_path
#               fill_in "Job Name",        :with => "Blub"
#               fill_in "Min. Longitude",  :with => "10.5"
#               fill_in "Min. Latitude",   :with => "20"
#               fill_in "Max. Longitude",  :with => "12.5"
#               fill_in "Max. Latitude",   :with => "21"
#               click_button
#               response.should render_template('jobs/new')
#               response.should have_selector("div.flash.success", :content => "successfully")
#            end.should change(Job, :count)
#         end
#      end
   end


   describe "show job" do
      before(:each) do
         @job = Factory(:job)
      end

      it "should have the right path" do
         get job_path(@job)
         response.status.should be(200)
      end
   end


   describe "index job" do
      it "should have the right path" do
         get jobs_path(@job)
         response.status.should be(200)
      end
   end



end
