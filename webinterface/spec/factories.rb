
Factory.define :job do |job|
   job.name                     "Phil Losoph"
   job.lonmin                   10.0
   job.latmin                   20.0
   job.lonmax                   11.0
   job.latmax                   21.0
end

Factory.define :tag do |tag|
   tag.key           "highway"
   tag.association   :job
end


Factory.define :run do |run|
   run.state          'new'
   run.association    :job
end

Factory.define :download do |dl|
   dl.name            'http://www.geofabrik.de/hot_exports/blub.zip'
   dl.size            '3 GB'
   dl.association     :run
end

