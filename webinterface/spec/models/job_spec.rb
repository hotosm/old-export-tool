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

      Region.connection.execute(
         "insert into regions (internal_name,name,created_at,updated_at,polygon) values('caribbean','caribbean',now(),now(),st_setsrid(st_geomfromtext('POLYGON((-60.428790 9.782485,-61.578630 9.946747,-61.998330 9.997709,-62.044320 10.427730,-61.687870 10.851500,-63.700100 11.381790,-67.293360 11.471950,-68.730660 11.742270,-69.535550 12.169730,-70.075980 12.304580,-70.374940 12.360740,-79.194240 15.481480,-83.241690 18.799220,-86.967180 23.135650,-83.149700 23.684350,-79.493200 24.167830,-79.735720 28.133000,-69.157780 26.580490,-55.996840 16.211640,-60.428790 9.782485))'),4326))"
      )
      @region = Region.last
      @user = FactoryGirl.create(:user)
      @attr = {
         :user_id => @user.id,
         :name => "Example job",
         :latmin => 18.9,
         :latmax => 19.4,
         :lonmin => -72.6,
         :lonmax => -72.04   
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

   it "should have a smaller box than BOXMAX" do
      # @region.jobs.new(@attr.merge(:lonmax => -72.04, :lonmin => -72.7, :latmax => 20, :latmin => 18)).should be_valid
      @region.jobs.new(@attr.merge(:lonmax => -60, :lonmin => -80, :latmax => 22, :latmin => 10)).should_not be_valid
   end

   it "should save a description" do
      job = @region.jobs.new(@attr.merge(:description => 'blub'))
      job.save!
      job.reload
      job.description.should == 'blub'
   end

   it "should have an area within an valid region" do
      attr = {
         :lonmin => 10,
         :lonmax => 11,
         :latmin => 70,
         :latmax => 71   
      }
      Job.new(attr).should_not be_valid
   end

   it "should respond to visible" do
      @region.jobs.new(@attr).should respond_to(:visible)
   end

   it "should not be visible by default" do
      @region.jobs.new(@attr).should be_visible
   end

   it "should be convertible to in-visible" do
      job = @region.jobs.new(@attr)
      job.toggle!(:visible)
      job.should_not be_visible
   end

   it "should have a uploads association" do
      job = @region.jobs.new(@attr)
      job.should be_valid
      job.should respond_to(:uploads)
   end

   it "should require a userid" do
      @region.jobs.new(@attr.merge(:user_id => "")).should_not be_valid
      @region.jobs.new(@attr.merge(:user_id => nil)).should_not be_valid
      @region.jobs.new(@attr).should be_valid
   end

end
