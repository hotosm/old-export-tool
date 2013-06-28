FactoryGirl.define do

   factory :job do |job|
      job.name                     "Phil Losoph"
      job.lonmin                   -72.6
      job.latmin                   18.9
      job.lonmax                   -72.0
      job.latmax                   19.4
      job.association              :region
   end

   factory :upload do |upload|
      upload.name                'upload preset haiti'
      upload.filename            'my_preset_file.xml'
      upload.uptype              'preset'
      upload.visibility          true
      upload.uploadfile          'abc'
   end

   factory :tag do |tag|
      tag.key           "highway"
      tag.association   :job
   end

   factory :run do |run|
      run.state          'new'
      run.association    :job
   end

   factory :download do |dl|
      dl.name            'http://www.geofabrik.de/hot_exports/blub.zip'
      dl.size            '3 GB'
      dl.association     :run
   end

   factory :region do |r|
      r.internal_name  'ht'
      r.name           'haiti xxxx'
      r.polygon        'POLYGON((-60.428790 9.782485,-61.578630 9.946747,-61.998330 9.997709,-62.044320 10.427730,-61.687870 10.851500,-63.700100 11.381790,-67.293360 11.471950,-68.730660 11.742270,-69.535550 12.169730,-70.075980 12.304580,-70.374940 12.360740,-79.194240 15.481480,-83.241690 18.799220,-86.967180 23.135650,-83.149700 23.684350,-79.493200 24.167830,-79.735720 28.133000,-69.157780 26.580490,-55.996840 16.211640,-60.428790 9.78248))'
   end

   factory :user do |u|
      u.email                 'ck40@geofabrik.de'
      u.password              'abcabcabc'
      u.password_confirmation 'abcabcabc'
      u.confirmed_at          Time.now
   end
end


