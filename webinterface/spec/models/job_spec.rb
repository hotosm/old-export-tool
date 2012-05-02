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
      @attr = {
         :name => "Example job",
         :latmin => 7,
         :latmax => 8,
         :lonmin => 44,
         :lonmax => 45   
      }
   end

   it "should create a new instance given valid attributes" do
      Job.create!(@attr)
   end

   it "should require a name" do
      no_name_job = Job.new(@attr.merge(:name => ""))
      no_name_job.should_not be_valid
   end

   it "should reject names that are too long" do
      long_name = "a" * 257
      long_name_job = Job.new(@attr.merge(:name => long_name))
      long_name_job.should_not be_valid
   end

   it "should require latmin" do
      no_name_job = Job.new(@attr.merge(:latmin => ""))
      no_name_job.should_not be_valid
   end

   it "should require latmax" do
      no_name_job = Job.new(@attr.merge(:latmax => ""))
      no_name_job.should_not be_valid
   end

   it "should require lonmin" do
      no_name_job = Job.new(@attr.merge(:lonmin => ""))
      no_name_job.should_not be_valid
   end

   it "should require lonmax" do
      no_name_job = Job.new(@attr.merge(:lonmax => ""))
      no_name_job.should_not be_valid
   end

   it "should have a numeric latmin" do
      Job.new(@attr.merge(:latmin => 7)).should be_valid
      Job.new(@attr.merge(:latmin => 'xx')).should_not be_valid
   end

   it "should have a numeric latmax" do
      Job.new(@attr.merge(:latmax => 7)).should be_valid
      Job.new(@attr.merge(:latmax => 'xx')).should_not be_valid
   end

   it "should have a numeric lonmin" do
      Job.new(@attr.merge(:lonmin => 7)).should be_valid
      Job.new(@attr.merge(:lonmin => 'xx')).should_not be_valid
   end

   it "should have a numeric lonmax" do
      Job.new(@attr.merge(:lonmax => 7)).should be_valid
      Job.new(@attr.merge(:lonmax => 'xx')).should_not be_valid
   end

   it "should save a description" do
      job = Job.new(@attr.merge(:description => 'blub'))
      job.save!
      job.reload
      job.description.should == 'blub'
   end
end
