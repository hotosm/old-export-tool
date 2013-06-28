require 'spec_helper'

describe JobsController do
   after(:all) do
      @dir = Dir.open(Upload.upload_directory)
      @dir.each do |file|
         if File.directory? file
         else
            puts "delete #{Upload.upload_directory}/#{file}"
            # XXX File.delete "#{Upload.upload_directory}/#{file}"
         end
      end
   end

   before(:each) do
      @user = FactoryGirl.create(:user)
      sign_in @user

      Region.connection.execute(
               "insert into regions (id,internal_name,name,created_at,updated_at,polygon) values(2, 'caribbean','caribbean',now(),now(),st_setsrid(st_geomfromtext('POLYGON((-60.428790 9.782485,-61.578630 9.946747,-61.998330 9.997709,-62.044320 10.427730,-61.687870 10.851500,-63.700100 11.381790,-67.293360 11.471950,-68.730660 11.742270,-69.535550 12.169730,-70.075980 12.304580,-70.374940 12.360740,-79.194240 15.481480,-83.241690 18.799220,-86.967180 23.135650,-83.149700 23.684350,-79.493200 24.167830,-79.735720 28.133000,-69.157780 26.580490,-55.996840 16.211640,-60.428790 9.782485))'),4326))"
      )
      @region = Region.last
   end



   render_views


   describe "POST 'wizard_configuration_create'" do
      before(:each) do
         @attr = {
            :name => "My new job",
            :lonmin => -77,
            :latmin => 18,
            :lonmax => -74, 
            :latmax => 19,
         }

      end
      
      it "should save a translation file" do
         up_preset       = FactoryGirl.create(:upload, :uptype => 'preset')
         up_tagtransform = FactoryGirl.create(:upload, :uptype => 'tagtransform')
         up_translation  = FactoryGirl.create(:upload, :uptype => 'translation')
         
         attr_uploads = {
            :default_tags => 0,
            :presetfile   => 0,
            :tagtransform => nil,
            :translation  => up_translation.id
         }

         lambda do
            post :wizard_configuration_create, :uploads => attr_uploads, :job => @attr
         end.should change(JobsUploads, :count).by(1)
      end

      it "should save preset and translation files" do
         up_preset       = FactoryGirl.create(:upload, :uptype => 'preset')
         up_tagtransform = FactoryGirl.create(:upload, :uptype => 'tagtransform')
         up_translation  = FactoryGirl.create(:upload, :uptype => 'translation')
         
         attr_uploads = {
            :default_tags => 0,
            :presetfile   => up_preset.id,
            :tagtransform => nil,
            :translation  => up_translation.id
         }

         lambda do
            post :wizard_configuration_create, :uploads => attr_uploads, :job => @attr
         end.should change(JobsUploads, :count).by(2)
      end

      it "should save tagtransform files" do
         up_preset       = FactoryGirl.create(:upload, :uptype => 'preset')
         up_tagtransform = FactoryGirl.create(:upload, :uptype => 'tagtransform')
         up_translation  = FactoryGirl.create(:upload, :uptype => 'translation')
         
         attr_uploads = {
            :default_tags => 0,
            :presetfile   => 0,
            :tagtransform => [up_tagtransform.id],
            :translation  => 0
         }

         lambda do
            post :wizard_configuration_create, :uploads => attr_uploads, :job => @attr
         end.should change(JobsUploads, :count).by(1)
      end

      it "should save three tagtransform files" do
         up_preset       = FactoryGirl.create(:upload, :uptype => 'preset')
         up_tagtr1 = FactoryGirl.create(:upload, :uptype => 'tagtransform')
         up_tagtr2 = FactoryGirl.create(:upload, :uptype => 'tagtransform')
         up_tagtr3 = FactoryGirl.create(:upload, :uptype => 'tagtransform')
         up_translation  = FactoryGirl.create(:upload, :uptype => 'translation')
         
         attr_uploads = {
            :default_tags => 0,
            :presetfile   => 0,
            :tagtransform => [up_tagtr1.id, up_tagtr2.id, up_tagtr3.id],
            :translation  => 0
         }

         lambda do
            post :wizard_configuration_create, :uploads => attr_uploads, :job => @attr
         end.should change(JobsUploads, :count).by(3)
      end

   end  

end
