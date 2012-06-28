require 'spec_helper'

describe Region do

   before(:each) do
      @attr = {
         :internal_name => "h",
         :name          => "Haiti",
         :left          => 7,
         :bottom        => 8,
         :right         => 44,
         :top           => 45
      }
      @region = Region.create(@attr)
   end

   it "should have a jobs attribute" do
      @region.should respond_to(:jobs)
   end

end
