# == Schema Information
#
# Table name: jobs
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  latmin     :float
#  latmax     :float
#  lonmin     :float
#  lonmax     :float
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe Job do

   before(:each) do
      @region = Factory(:region)
      @attr = {
         :name => "Example job",
         :latmin => 7,
         :latmax => 8,
         :lonmin => 44,
         :lonmax => 45   
      }
   end

   it "should create a new instance given valid attributes" do
      @region.jobs.create!(@attr)
   end

   it "should require a name" do
      @region.jobs.new(@attr.merge(:name => "")).should_not be_valid
      @region.jobs.new(@attr).should be_valid
   end

   it "should reject names that are too long" do
      long_name = "a" * 257
      @region.jobs.new(@attr.merge(:name => long_name)).should_not be_valid
   end

   it "should require latmin" do
      @region.jobs.new(@attr.merge(:latmin => "")).should_not be_valid
   end

   it "should require latmax" do
      @region.jobs.new(@attr.merge(:latmax => "")).should_not be_valid
   end

   it "should require lonmin" do
      @region.jobs.new(@attr.merge(:lonmin => "")).should_not be_valid
   end

   it "should require lonmax" do
      @region.jobs.new(@attr.merge(:lonmax => "")).should_not be_valid
   end

   it "should have a numeric latmin" do
      @region.jobs.new(@attr.merge(:latmin => 7)).should be_valid
      @region.jobs.new(@attr.merge(:latmin => 'xx')).should_not be_valid
   end

   it "should have a numeric latmax" do
      @region.jobs.new(@attr.merge(:latmax => 7)).should be_valid
      @region.jobs.new(@attr.merge(:latmax => 'xx')).should_not be_valid
   end

   it "should have a numeric lonmin" do
      @region.jobs.new(@attr.merge(:lonmin => 7)).should be_valid
      @region.jobs.new(@attr.merge(:lonmin => 'xx')).should_not be_valid
   end

   it "should have a numeric lonmax" do
      @region.jobs.new(@attr.merge(:lonmax => 7)).should be_valid
      @region.jobs.new(@attr.merge(:lonmax => 'xx')).should_not be_valid
   end

   it "should save a description" do
      job = @region.jobs.new(@attr.merge(:description => 'blub'))
      job.save!
      job.reload
      job.description.should == 'blub'
   end


   it "should require a region id" do
      Job.new(@attr).should_not be_valid
      @region.jobs.new(@attr).should be_valid
   end

end
