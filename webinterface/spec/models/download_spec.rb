require 'spec_helper'

describe Download do

   before(:each) do
      @run = Factory(:run)
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
