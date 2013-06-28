require 'spec_helper'

describe Tag do

   before(:each) do
      Region.connection.execute(
                     "insert into regions (internal_name,name,created_at,updated_at,polygon) values('caribbean','caribbean',now(),now(),st_setsrid(st_geomfromtext('POLYGON((-60.428790 9.782485,-61.578630 9.946747,-61.998330 9.997709,-62.044320 10.427730,-61.687870 10.851500,-63.700100 11.381790,-67.293360 11.471950,-68.730660 11.742270,-69.535550 12.169730,-70.075980 12.304580,-70.374940 12.360740,-79.194240 15.481480,-83.241690 18.799220,-86.967180 23.135650,-83.149700 23.684350,-79.493200 24.167830,-79.735720 28.133000,-69.157780 26.580490,-55.996840 16.211640,-60.428790 9.782485))'),4326))"
      )
      @region = Region.last
      @user = FactoryGirl.create(:user, :email => 'ck45@geofabrik.de')
      @job = FactoryGirl.build(:job, :user_id => @user.id)
      @job.save!

      @attr = {
         :key => 'highway'
      }
   end

   it "should create a new instance given valid attributes" do
      @job.tags.create!(@attr)
   end

   describe "job associations" do
      before(:each) do
         @tag = @job.tags.create(@attr)
      end

      it "should have a job attribute" do
         @tag.should respond_to(:job)
      end

      it "should have the right associated job" do
         @tag.job_id.should == @job.id
         @tag.job.should == @job
      end
   end

   describe "tag associations" do
      before(:each) do
         @tag1 = FactoryGirl.create(:tag, :job => @job, :created_at => 1.day.ago)
         @tag2 = FactoryGirl.create(:tag, :job => @job, :created_at => 1.hour.ago)
      end

      it "should have a tag attribute" do
         @job.should respond_to(:tags)
      end
   end

   describe "validations" do
      it "should require a job_id" do
         Tag.new(@attr).should_not be_valid
         Tag.new(@attr.merge(:job_id => 1)).should be_valid
      end

      it "should require a key" do
         @job.tags.new(@attr.merge(:key => '')).should_not be_valid
         @job.tags.new(@attr).should be_valid
      end
   end
end
