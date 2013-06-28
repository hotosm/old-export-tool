require 'spec_helper'
require 'xml/libxml'

describe Tag do

   before(:each) do
      Region.connection.execute(
         "insert into regions (internal_name,name,created_at,updated_at,polygon) values('caribbean','caribbean',now(),now(),st_setsrid(st_geomfromtext('POLYGON((-60.428790 9.782485,-61.578630 9.946747,-61.998330 9.997709,-62.044320 10.427730,-61.687870 10.851500,-63.700100 11.381790,-67.293360 11.471950,-68.730660 11.742270,-69.535550 12.169730,-70.075980 12.304580,-70.374940 12.360740,-79.194240 15.481480,-83.241690 18.799220,-86.967180 23.135650,-83.149700 23.684350,-79.493200 24.167830,-79.735720 28.133000,-69.157780 26.580490,-55.996840 16.211640,-60.428790 9.782485))'),4326))"
      )
      @region = Region.last

      @user = FactoryGirl.create(:user, :email => 'ck45@geofabrik.de')
      @job = FactoryGirl.build(:job, :user_id => @user.id)
      @job.save!

      @xml = "<?xml version='1.0' encoding='UTF-8'?><presets xmlns='http://josm.openstreetmap.de/tagging-preset-1.0'><groups><group><item type='node'><text key='name'></text></item></group></groups></presets>"

      @xml2 = "<?xml version='1.0' encoding='UTF-8'?><presets xmlns='http://josm.openstreetmap.de/tagging-preset-1.0'><groups><group><item type='node'><text key='name'></text><blub key='name' type='way'></blub></item></group></groups></presets>"
      
      @xml3 = "<?xml version='1.0' encoding='UTF-8'?><presets xmlns='http://josm.openstreetmap.de/tagging-preset-1.0'><groups><group><item type='node,way,closedway'><text key='name'></text><blub key='name' type='way'></blub></item></group></groups></presets>"
      
      @xml4 = "<?xml version='1.0' encoding='UTF-8'?><presets xmlns='http://josm.openstreetmap.de/tagging-preset-1.0'><groups><group><item type='node'><text key='name'></text><blub key='name' type='way'></blub><optional><green key='tree' type='node'/></optional></item></group></groups></presets>"

      @xml5 = "<?xml version='1.0' encoding='UTF-8'?><presets xmlns='http://josm.openstreetmap.de/tagging-preset-1.0'><groups type='node,closedway'><group><item><text key='building'></text><optional><green key='tree' type='node'/></optional></item></group></groups></presets>"

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
   
   it "should find a key as child from an optional tag" do
      tags = Tag.from_xml(@xml4)
      tags.has_key?('tree').should be_true
   end

   it "should read a complex preset file" do
      xml5 = IO.read(Rails.root.join("spec/fixtures/HAITI_OSM_STM020_presets_v1.93_Hot_Exports.xml"))
      tags = Tag.from_xml(xml5)
      tags.has_key?('waterway').should be_true
      tags['waterway'].has_key?('line').should be_true
   end

   it "should read a complex preset file (building file bug)" do
      xml6 = IO.read(Rails.root.join("spec/fixtures/building.xml"))
      tags = Tag.from_xml(xml6)
      tags.has_key?('building').should be_true
   end

   it "should reduce types in the right way" do 
      tags = Tag.from_xml(@xml5)
      tags.has_key?('building').should be_true
      tags['building'].has_key?('point').should be_true
      tags['building'].has_key?('polygon').should be_true
      tags.has_key?('tree').should be_true
      tags['tree'].has_key?('point').should be_true
      tags['tree'].has_key?('polygon').should_not be_true
   end

end
