require 'spec_helper'

describe Tag do

   before(:each) do
      @job = Factory(:job)
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
         @tag1 = Factory(:tag, :job => @job, :created_at => 1.day.ago)
         @tag2 = Factory(:tag, :job => @job, :created_at => 1.hour.ago)
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
