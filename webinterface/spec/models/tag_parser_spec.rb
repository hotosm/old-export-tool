require 'spec_helper'
require 'xml/libxml'

describe Tag do

   before(:each) do
      @job = Factory(:job)
      @xml = "<?xml version='1.0' encoding='UTF-8'?><presets xmlns='http://josm.openstreetmap.de/tagging-preset-1.0'><groups><group><item type='node'><text key='name'></text></item></group></groups></presets>"

      @xml2 = "<?xml version='1.0' encoding='UTF-8'?><presets xmlns='http://josm.openstreetmap.de/tagging-preset-1.0'><groups><group><item type='node'><text key='name'></text><blub key='name' type='way'></blub></item></group></groups></presets>"
      
      @xml3 = "<?xml version='1.0' encoding='UTF-8'?><presets xmlns='http://josm.openstreetmap.de/tagging-preset-1.0'><groups><group><item type='node,way,closedway'><text key='name'></text><blub key='name' type='way'></blub></item></group></groups></presets>"
   end


   # fuzz solves namespace problem
   it "should find an item with xpath" do
      p = XML::Parser.string(@xml)
      doc = p.parse
      doc.root.namespaces.default_prefix='fuzz'
      doc.find('//fuzz:item').each do |item|
         item.should_not be_empty
      end
   end

   it "should parse xml" do
      tags = Tag.from_xml(@xml)
      tags.has_key?('name').should be_true
   end

   it "should find name:point and name:line" do
      tags = Tag.from_xml(@xml2)
      tags.has_key?('name').should be_true
   end

   it "should find 2 key-geometry combinations" do
      tags = Tag.from_xml(@xml2)
      @count = 0
      tags.each do |key,value|
         @count = value.size
      end
      @count.should == 2
   end

   it "should split comma seperated types" do
      tags = Tag.from_xml(@xml3)
      tags.has_key?('name').should be_true
      tags.each do |key,value|
         value.has_key?('point').should be_true
         value.has_key?('line').should be_true
         value.has_key?('polygon').should be_true
      end
   end

end
