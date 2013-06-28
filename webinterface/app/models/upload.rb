class Upload < ActiveRecord::Base
   attr_accessor :uploadfile
   attr_accessible :uploadfile, :name, :filename, :uptype, :visibility, :user_id

   has_and_belongs_to_many :jobs
   belongs_to :user

   default_scope :order => 'uploads.updated_at DESC'

   validates :name,
      :presence => true,
      :length => {:maximum => 256}

   validates :uploadfile,
      :presence => true

   validates :filename,
      :presence => true

   validates :uptype,
      :presence => true,
      :inclusion => {
         :in => %w(preset tagtransform translation),
         :message => "%{value} is not a valid update file type"
      }


   def move_upload(old_filename)
      directory = Upload.upload_directory
      src  = File.join(directory, old_filename)
      dest = File.join(directory, self.filename)
      FileUtils.mv src, dest
   end

   def save_upload(upload)
      directory = Upload.upload_directory
      path = File.join(directory, self.filename)
      File.open(path, "wb") { |f| f.write(upload.read) }
   end

   def complete_save(upload)
      self.filename = 'filenotsaved'
      self.visibility = false
      if self.save then
         self.filename = "#{self.uptype}-#{self.id}"
         self.visibility = true
         self.save_upload(upload)
         self.save
      end
   end

   def complete_delete
      directory = Upload.upload_directory
      path = File.join(directory, self.filename)
      File.delete(path)
      self.delete
   end

   def f_xml
      directory = Upload.upload_directory
      path = File.join(directory, self.filename)
      file = File.open(path, "rb")

      # xml = file.read
      xml = String.new
      while !file.eof?
         xml.concat(file.readline)
      end
      file.close
      return xml
   end


   def upload_check 
      if (self.uptype == 'preset')
         tags = Tag.from_xml(self.f_xml)
      end 

      ## XXX check tagtransform and translation file syntax
   end


   def self.upload_directory
      if Rails.env.test? then
         return "public/uploads_test"
      end

      return "public/uploads"
   end

   def self.uptypes
      xx = Hash.new
      xx['preset']       = 'Preset File'
      xx['tagtransform'] = 'Tag Transform SQL File'
      xx['translation']  = 'Translation File'
      return xx
   end

   def self.uptype_options
      yy = Hash.new
      Upload.uptypes.each do |k, v|
         yy[v] = k
      end
      return yy
   end

end
