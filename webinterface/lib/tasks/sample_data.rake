require 'faker'

namespace :db do
   desc "Fill database with sample data"
   task :populate => :environment do
      Rake::Task['db:reset'].invoke
      region1 = Region.create!(
         :internal_name => "haiti",
         :name          => "Haiti",
         :left          => "-75",
         :bottom        => "17.3",
         :right         => "-68",
         :top           =>  "20.5"
      )
      region2 = Region.create!(
         :internal_name => "Chugoku",
         :name          => "chugoku",
         :left          => "130.5",
         :bottom        => "33.4",
         :right         => "135",
         :top           =>  "35.8"
      )
      3.times do |n|
         job = Job.create!(
            :name => "Example Job #{n}",
            :description => "populated example job",
            :latmin => 34,
            :latmax => 34.5,
            :lonmin => 133,
            :lonmax => 134,
            :region_id => region2.id
         )
         2.times do |m|
            run = Run.create!(
               :job_id => job.id,
               :state => 'success'
            )
            ['shp', 'kml', 'pgs'].each do |ext|
               download = Download.create!(
                  :run_id => run.id,
                  :name => "http://www.geofabrik.de/hot_exports/#{run.id}/blub-#{ext}.zip",
                  :size => "#{m} GB"
               )
            end
         end
      end
   end
end

