require 'spec_helper'

describe Download do

   before(:each) do
      Region.connection.execute(
         "insert into regions (internal_name,name,created_at,updated_at,polygon) values('caribbean','caribbean',now(),now(),st_setsrid(st_geomfromtext('POLYGON((-60.428790 9.782485,-61.578630 9.946747,-61.998330 9.997709,-62.044320 10.427730,-61.687870 10.851500,-63.700100 11.381790,-67.293360 11.471950,-68.730660 11.742270,-69.535550 12.169730,-70.075980 12.304580,-70.374940 12.360740,-79.194240 15.481480,-83.241690 18.799220,-86.967180 23.135650,-83.149700 23.684350,-79.493200 24.167830,-79.735720 28.133000,-69.157780 26.580490,-55.996840 16.211640,-60.428790 9.782485))'),4326))"
      )
      @region = Region.last
      @user = FactoryGirl.create(:user, :email => 'ck45@geofabrik.de')
      @job = FactoryGirl.build(:job, :user_id => @user.id)
      @job.save!
      @run = FactoryGirl.build(:run, :job_id => @job.id, :user_id => @user.id)
      @run.save!

      @attr = {
         'name' => 'http://www.geofabrik.de/hot_exports/blub.zip',
         'size' => '5 GB'   
      }
   end

   it "should create a new instance with given valid attributes" do
      @download = @run.downloads.create!(@attr)
   end


   describe "run associations" do
      before(:each) do
         @download = @run.downloads.create!(@attr)
      end

      it "should have a run attribute" do
         @download.should respond_to(:run)
      end

      it "should have the right associated run" do
         @download.run_id.should == @run.id
         @download.run.should == @run
      end
   end

   describe "download associations" do
      it "should have a run attribute" do
         @run.should respond_to(:downloads)
      end
   end

   describe "validations" do
      it "should require a run id" do
         Download.new(@attr).should_not be_valid
      end
   end

end
