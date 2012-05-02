require 'faker'

namespace :db do
   desc "Fill database with sample data"
   task :populate => :environment do
      Rake::Task['db:reset'].invoke
      3.times do |n|
         job = Job.create!(
            :name => "Example Job #{n}",
            :description => "populated example job",
            :latmin => 35,
            :latmax => 37,
            :lonmin => 10,
            :lonmax => 12
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

