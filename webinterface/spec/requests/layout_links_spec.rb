require 'spec_helper'

describe "LayoutLinks" do
   before(:each) do
      @region = FactoryGirl.create(:region)
   end

   it "should have a job index at '/jobs'" do
      get '/jobs'
      response.should have_selector('title', :content => "Jobs")
   end

#   it "should have a new job page at '/wizard_area'" do
#      get '/newjob'
#      response.should have_selector('title', :content => "New Export Job")
#   end

# moved to footer
#   it "should have a Upload Link in the header" do
#      get '/'
#      response.should have_selector('a', :content => "Configuration")
#   end

   it "should have a preset link in footer" do
      get '/'
      response.should have_selector('a', :content => "Preset Files")
   end


end
