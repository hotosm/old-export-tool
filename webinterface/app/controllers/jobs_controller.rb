class JobsController < ApplicationController

   require 'xml/libxml'

   def new
      @job     = Job.new
      @title   = 'New Export Job'
      @h1      = 'New Export Job'
      @action  = 'wizard_area'
   end

   def newwithtags
      if params[:job_id].nil?
         flash[:error] = "No job id given!"
         redirect_to newjob_path
      else
         @job     = Job.find(params[:job_id])
         @title   = 'New Export Job (with given Tags)'
         @h1      = 'New Export Job (with given Tags)'
         @action  = 'newwithtags_create'
         render :new
      end
   end

   def wizard_area
      @job = Job.new(params[:job])
      @title = "Tag Upload"
      render 'tagupload_form'
   end

   def tagupload
      @job = Job.new(params[:job])
      error = 0

      Job.transaction do
         if @job.save then
         else 
            error = 1
         end

         # default tags
         tags = Tag.default_tags

         # uploaded tags
         if params[:tagfile] then
            content = content_from_upload(params[:tagfile])
             
            uploaded_tags = Tag.from_xml(content)
            tags = Tag.join_taghashes(tags, uploaded_tags)
         end

         # save tags
         tags.each_key do |key|
            tags[key].each do |type, value|
               tag = Tag.new
               tag.key = key
               tag.geometrytype = type
               tag.job_id = @job.id
               tag.default = value
               tag.save
            end
         end
      end


      if error == 0 then
         flash[:success] = "Job successfully created!"
         redirect_to @job
      else 
         @title = "New Job"
         flash[:error] = "No job saved!"
         render 'new'
      end
   end

   def newwithtags_create
      @job = Job.new(params[:job])
      error = 0

      Job.transaction do
         if @job.save then
         else 
            error = 1
         end

         @old_tags = Tag.where('job_id = ?', params[:old_job_id])

         @old_tags.each do |ot|
            tag = Tag.new
            tag.key = ot.key
            tag.geometrytype = ot.geometrytype
            tag.default = ot.default
            tag.job_id = @job.id
            tag.save
         end
      end

      if error == 0 then
         flash[:success] = "Job successfully created!"
         redirect_to @job
      else 
         @title = "New Job"
         flash[:error] = "No job saved!"
         render 'new'
      end
   end




   def show
      @job = Job.find(params[:id])
      @runs = Run.where("job_id = ?", params[:id])
      # XXX TODO @lastdownload= Download.find(@runs.first.id)
      @tags = Tag.where("job_id = ?", params[:id]).order('key')
      @title = @job.name
   end


   def index
      @title = "All Jobs"
      @jobs = Job.all
   end


   def newrun
      @job = Job.find(params[:job_id])

      @run = Run.new
      @run.job_id = params[:job_id]
      @run.state = 'new'
      

      # check if there is already a job runnning
      if Run.where("job_id = ? and state = 'new'", @job.id).count > 0 then
         flash[:error] = "There is already a running job."
      # else save
      elsif @run.save
         flash[:success] = "Run successfully started!"
      else 
         flash[:error] = "No run started!"
      end

      @title = @job.name
      redirect_to @job
   end





# XXX obsolet 
   def create
      @job = Job.new(params[:job])
      if @job.save
         flash[:success] = "Job successfully created!"
         redirect_to @job
      else 
         @title = "New Job"
         flash[:error] = "No job saved!"
         render 'new'
      end
   end



private

   def content_from_upload(file_data)
      if file_data.respond_to?(:read)
         content = file_data.read
      elsif file_data.respond_to?(:path)
         content = File.read(file_data.path)
      else
         logger.error "Bad file_data: #{file_data.class.name}: #{file_data.inspect}"
      end
      return content
   end


end
