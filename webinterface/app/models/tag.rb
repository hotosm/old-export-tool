class Tag < ActiveRecord::Base
   belongs_to :job
   default_scope :order => 'tags.key ASC'


   validates :key, :presence => true
   validates :job_id, :presence => true


   def self.join_taghashes(default_tags, uploaded_tags)

      tags = Hash.new

      uploaded_tags.each_key do |key|
         tags[key] = Hash.new
         uploaded_tags[key].each_key do |geom|
            tags[key][geom] = uploaded_tags[key][geom]
         end
      end
   
      default_tags.each_key do |key|
         if (!tags.has_key?(key)) then 
            tags[key] = Hash.new
         end
         default_tags[key].each_key do |geom|
            tags[key][geom] = default_tags[key][geom]
         end
      end

      # logger.error tags

      return tags
   end


   def self.default_tags

      tags = {
         "access"             => { "point" => true, "line" => true },
         "addr:housename"     => { "point" => true, "line" => true },
         "addr:housenumber"   => { "point" => true, "line" => true },
         "addr:interpolation" => { "point" => true, "line" => true },
         "admin_level"        => { "point" => true, "line" => true },
         "aerialway"          => { "point" => true, "line" => true },
         "aeroway"            => { "point" => true, "polygon" => true },
         "amenity"            => { "point" => true, "polygon" => true },
         "barrier"            => { "point" => true, "line" => true },
         "bicycle"            => { "point" => true },
         #"brand"              => { "point" => true, "line" => true },
         "bridge"             => { "point" => true, "line" => true },
         "boundary"           => { "point" => true, "line" => true },
         "building"           => { "point" => true, "polygon" => true },
         "capital"            => { "point" => true },
         "construction"       => { "point" => true, "line" => true },
         "covered"            => { "point" => true, "line" => true },
         #"culvert"            => { "point" => true, "line" => true },
         "cutting"            => { "point" => true, "line" => true },
         "denomination"       => { "point" => true, "line" => true },
         "disused"            => { "point" => true, "line" => true },
         "ele"                => { "point" => true },
         "embankment"         => { "point" => true, "line" => true },
         "foot"               => { "point" => true, "line" => true },
         "generator:source"   => { "point" => true, "line" => true },
         "harbour"            => { "point" => true, "polygon" => true },
         "highway"            => { "point" => true, "line" => true },
         "historic"           => { "point" => true, "polygon" => true },
         #"horse"              => { "point" => true, "line" => true },
         #"intermittent"       => { "point" => true, "line" => true },
         "junction"           => { "point" => true, "line" => true },
         "landuse"            => { "point" => true, "polygon" => true },
         "layer"              => { "point" => true, "line" => true },
         "leisure"            => { "point" => true, "polygon" => true },
         "lock"               => { "point" => true, "line" => true },
         "man_made"           => { "point" => true, "polygon" => true },
         "military"           => { "point" => true, "polygon" => true },
         "motorcar"           => { "point" => true, "line" => true },
         "name"               => { "point" => true, "line" => true },
         "natural"            => { "point" => true, "polygon" => true },
         "oneway"             => { "point" => true, "line" => true },
         #"operator"           => { "point" => true, "line" => true },
         "poi"                => { "point" => true },
         "population"         => { "point" => true, "line" => true },
         "power"              => { "point" => true, "polygon" => true },
         #"power_source"       => { "point" => true, "line" => true },
         "place"              => { "point" => true, "polygon" => true },
         "railway"            => { "point" => true, "line" => true },
         "ref"                => { "point" => true, "line" => true },
         "religion"           => { "point" => true },
         "route"              => { "point" => true, "line" => true },
         "service"            => { "point" => true, "line" => true },
         "shop"               => { "point" => true, "polygon" => true },
         "sport"              => { "point" => true, "polygon" => true },
         "surface"            => { "point" => true, "line" => true },
         "toll"               => { "point" => true, "line" => true },
         "tourism"            => { "point" => true, "polygon" => true },
         "tower:type"         => { "point" => true, "line" => true },
         "tracktype"          => { "line" => true },
         "tunnel"             => { "point" => true, "line" => true },
         "water"              => { "point" => true, "polygon" => true },
         "waterway"           => { "point" => true, "polygon" => true },
         "wetland"            => { "point" => true, "polygon" => true },
         "width"              => { "point" => true, "line" => true },
         "wood"               => { "point" => true, "line" => true },
      }
      return tags
   end

   def self.from_xml(xml)

      tags = Hash.new
      p = XML::Parser.string(xml)
      doc = p.parse
      doc.root.namespaces.default_prefix='fuzz'
      items = doc.find('//fuzz:item')

      items.each do |item|
         process_item_and_children(tags, item, Tag.type2geometrytype(nil))
      end
      return tags

   end

   def self.save_tags(tags, job_id)

      tags.each_key do |key|
         tags[key].each do |type, value|
            tag = Tag.new
            tag.key = key
            tag.geometrytype = type
            tag.job_id = job_id
            tag.default = value
            tag.save
         end
      end
   end



private
  def self.process_item_and_children(tags, something, geometrytype)

      if (!something['type'].nil?)
         geometrytype = Tag.type2geometrytype(something['type'])
      end

      if (!something['key'].nil? && !geometrytype.nil?)
         key = something['key']
         if !tags.has_key?(key)
            tags[key] = Hash.new
         end

         geometrytype.each do |type|
            tags[key][type] = false
         end
     end

     something.children.each do |child|
        process_item_and_children(tags, child, geometrytype)
     end
   end


   def self.type2geometrytype(type) 

      geometrytype = Array.new

      if(type.nil?)
         geometrytype.push('point')
         geometrytype.push('line')
         geometrytype.push('polygon')
      else
         types = type.split(',')
         types.each do |type| 
            if type == 'node'
               geometrytype.push('point')
            elsif type == 'way'
               geometrytype.push('line')
            elsif type == 'closedway'
               geometrytype.push('polygon')
            elsif type == 'relation'
               geometrytype.push('polygon')
            end
         end
      end

      return geometrytype
   end



end
