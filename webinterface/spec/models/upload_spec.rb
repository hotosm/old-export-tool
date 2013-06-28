require 'spec_helper'

describe Upload do

   before(:each) do
      @user = FactoryGirl.create(:user)
      @attr = {
         :user_id    => @user.id,
         :name       => 'my upload',
         :filename   => 'preset_7',
         :uptype     => 'preset',
         :visibility => true,
         :uploadfile => 'abc'   
      }
   end

   it "should create a new instance with given valid attributes" do
      Upload.create!(@attr)
   end

   it "should require a name" do
      Upload.new(@attr.merge(:name => "")).should_not be_valid
      Upload.new(@attr).should be_valid
   end

   it "should reject names that are to long" do
      longname = "a" * 300
      Upload.new(@attr.merge(:name => longname)).should_not be_valid
   end

   it "should require a filename" do
      Upload.new(@attr.merge(:filename => '')).should_not be_valid
   end

   it "should require a uptype" do
      Upload.new(@attr.merge(:uptype => '')).should_not be_valid
   end

   it "should reject invalid uptypes" do
      Upload.new(@attr.merge(:uptype => 'xxxx')).should_not be_valid
      Upload.new(@attr.merge(:uptype => 'tagtransform')).should be_valid
   end

   it "should have a directory method" do
      Upload.upload_directory.should =~ /public\/uploads/
   end

   it "should have the right uptype strings" do
      Upload.uptypes['preset'].should == 'Preset File'
   end

   it "should have a jobs association" do
      up = Upload.new(@attr)
      up.should respond_to(:jobs)
   end

end
