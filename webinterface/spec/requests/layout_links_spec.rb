require 'spec_helper'

describe "LayoutLinks" do

   it "should have a job index at '/jobs'" do
      get '/jobs'
      response.should have_selector('title', :content => "All Jobs")
   end

   it "should have a new job page at '/newjob'" do
      get '/newjob'
      response.should have_selector('title', :content => "New Export Job")
   end

end
