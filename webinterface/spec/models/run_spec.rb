require 'spec_helper'

describe Run do


   before(:each) do
      @job = Factory(:job)
      @attr = {
         :state => 'new',
         :downloadlink => '',
         :comment => ''   
      }
   end

   it "should create a new instance with given valid attributes" do
      @run = @job.runs.create!(@attr)
   end

   describe "job associations" do
      before(:each) do
         @run = @job.runs.create(@attr)
      end

      it "should have a job attribute" do
         @run.should respond_to(:job)
      end

      it "should have the right associated job" do
         @run.job_id.should == @job.id
         @run.job.should == @job
      end
   end

   describe "run associations" do
      before(:each) do
         @run1 = Factory(:run, :job => @job, :created_at => 1.day.ago)
         @run2 = Factory(:run, :job => @job, :created_at => 1.hour.ago)
      end

      it "should have a run attribute" do
         @job.should respond_to(:runs)
      end

      it "should have the right runs in the right order" do
         @job.runs[1].should == @run2
         @job.runs[2].should == @run1

         # @job.runs[0] is created with before_save
         # @job.runs.should == [@run2, @run1] # ordered newest first
      end
   end


   describe "validations" do
      it "should require a job_id" do
         Run.new(@attr).should_not be_valid
         Run.new(@attr.merge(:job_id => 1)).should be_valid
      end

      it "should require a state" do
         @job.runs.new(@attr.merge(:state => "")).should_not be_valid
      end

      it "should require a valid state" do
         @job.runs.new(@attr.merge(:state => 'new')).should be_valid
         @job.runs.new(@attr.merge(:state => "blub")).should_not be_valid
      end
   end
end

