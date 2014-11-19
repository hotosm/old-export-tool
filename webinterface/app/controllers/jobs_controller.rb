class JobsController < ApplicationController

   before_filter :authenticate_user!, :except => [:index, :show, :reload_runs, :newrun]

   require 'xml/libxml'
   
   def index
      @title = t('jobs.title')

      # Parameter
      # show deleted:   deleted = y 
      # hide deleted:   no parameter or deleted = n

      if user_signed_in? then
         if params['notowner'] == 'y' and params['deleted'] == 'y'
            @jobs = Job.jobs_notowner_notvisible(params[:page])
            @hide_notowner  = false
            @hide_invisible = false

         elsif params['deleted'] == 'y'
            @jobs = Job.jobs_owner_notvisible(params[:page], current_user.id)
            @hide_notowner  = true
            @hide_invisible = false

         elsif params['notowner'] == 'y'
            @jobs = Job.jobs_notowner_visible(params[:page])
            @hide_notowner  = false
            @hide_invisible = true

         else
            @jobs = Job.jobs_owner_visible(params[:page], current_user.id)
            @hide_notowner  = true
            @hide_invisible = true
         end
      else
         if params['deleted'] == 'y'
            @jobs = Job.jobs_notowner_notvisible(params[:page])
            @hide_notowner  = false
            @hide_invisible = false
         else
            @jobs = Job.jobs_notowner_visible(params[:page])
            @hide_notowner  = false
            @hide_invisible = true
         end
      end
   end
   
   def show
      @job = Job.find(params[:id])
      @runs = Run.where("job_id = ?", params[:id])
      # XXX TODO @lastdownload= Download.find(@runs.first.id)

      @uploads = @job.uploads.order('uptype').reverse_order
      @tags = Tag.where("job_id = ?", params[:id]).order('key')
      @title = @job.name
   end

   def reload_runs
      @runs = Run.where("job_id = ?", params[:job_id])

      respond_to do |format|
         
         if (current_user.try(:admin?))
            format.json {render :json => @runs, :include => [:user, :downloads] }
         else
            format.json {render :json => @runs, :include => :downloads }
         end
      end
   end

   def wizard_area
      @job     = Job.new
      @title   = t('jobs.newjob.title')
      @h1      = t('jobs.newjob.h1')
      @action  = 'wizard_configuration'
      
      @max_bounds_area = 100
      @max_bounds_area = 200 if current_user.admin
   end

   def newwithconfiguration
      if params[:job_id].nil?
         flash[:error] = "No job id given!"
         redirect_to wizard_area_path
      else
         @job         = Job.find(params[:job_id])
         @job.user_id = current_user.id

         @title   =  t('jobs.newjobwithconf.title') 
         @h1      =  t('jobs.newjobwithconf.h1')
         @action  = 'newwithconfiguration_create'

         @max_bounds_area = 100
         @max_bounds_area = 200 if current_user.admin
      
         render :wizard_area
      end
   end

   def wizard_configuration
      @job = Job.new(params[:job])

      @upfiles = uploadfiles_prepare
      @title = t('jobs.newjobconf.title')
      render 'wizard_configuration_form'
   end

   def wizard_configuration_create
      @job = Job.new(params[:job])
      @job.user_id = current_user.id

      @uploads = params[:uploads]
      # default tags
      if @uploads['default_tags']
         tags = Tag.default_tags
      else
         tags = Hash.new
      end
     
      error = 0
      Job.transaction do
         if @job.save then
            #puts @job.inspect
         else 
            error = 1
         end

         begin
            # presetfile (uploaded tags)
            if @uploads['presetfile'] != "0" then

               upload = Upload.find(@uploads['presetfile'])
               @job.uploads << upload

               at_string = upload.updated_at.strftime("%Y-%m-%d %H:%M")
               @job.presetfile = "#{upload.name} (#{at_string})"

               uploaded_tags = Tag.from_xml(upload.f_xml)
               tags = Tag.join_taghashes(tags, uploaded_tags)
            end

            # tagtransform
            if @uploads['tagtransform'] then
               @uploads['tagtransform'].each do |id|
                  upload = Upload.find(id)
                  @job.uploads << upload
               end
            end

            # translation
            if @uploads['translation'] != "0" then
               upload = Upload.find(@uploads['translation'])
               @job.uploads << upload
            end

            @job.save!
            Tag.save_tags(tags,@job.id)

         rescue Exception => @e
            error = 11
            @job.delete
            puts error
            puts @e.inspect
         end

      end

      if tags.count == 0 
         error = 111
      end

      if error == 0 then
         flash[:success] = t('jobs.flash.success.job_created')
         redirect_to @job

      elsif error == 11 then
         flash[:error] = t('jobs.flash.error.xml_parsing_failed')
         @upfiles = uploadfiles_prepare
         @title = t('jobs.newjobconf.h1')
         render 'wizard_configuration_form'

      elsif error == 111 then
         flash[:error] = t('jobs.flash.error.no_tags')
         @upfiles = uploadfiles_prepare
         @title = t('jobs.newjobconf.h1')
         render 'wizard_configuration_form'

      else 
         @title = t('jobs.newjob.title')
         flash[:error] = t('jobs.flash.error.not_saved')
         render 'wizard_area'
      end
   end

   def newwithconfiguration_create
      @job            = Job.new(params[:job])
      @old_job        = Job.find(params[:old_job_id])
      @job.presetfile = @old_job.presetfile
      @job.uploads    = @old_job.uploads
      @job.user_id    = current_user.id

      error = 0

      Job.transaction do
         if @job.save then
         else 
            error = 1
         end

         @old_tags = Tag.where('job_id = ?', @old_job.id)

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
         flash[:success] = t('jobs.flash.success.job_created')
         redirect_to @job
      else 
         @title = "New Job"
         flash[:error] = t('jobs.flash.error.not_saved')
         render 'wizard_area'
      end
   end

   def newrun
      @job = Job.find(params[:job_id])

      @run = Run.new
      @run.job_id = params[:job_id]
      @run.state = 'new'
     
      # user_id if user logged in 
      unless (current_user.nil?)
         @run.user_id = try(:current_user).id
      end

      # check if there is already a job runnning
      if Run.where("job_id = ? and state = 'new'", @job.id).count > 0 then
         flash[:error] = t('jobs.flash.error.running_job')
      # else save
      elsif @run.save
         flash[:success] = t('jobs.flash.success.run_started')
      else 
         flash[:error] = t('jobs.flash.error.no_run_started')
      end

      @title = @job.name
      redirect_to @job
   end
  
  
   def invisible
      change_visibility(params[:id], false, params['deleted'])
   end

   def restore
      change_visibility(params[:id], true, params['deleted'])
   end


private

   def change_visibility(id,resdel, deleted)
      job = Job.find(id)
      job.visible = resdel


      if !user_right_deletion? job
         if (resdel == true)
            flash[:error] = t('jobs.flash.error.restored')
         else
            flash[:error] = t('jobs.flash.error.deleted')
         end
         redirect_to :action => 'index', :deleted => deleted
         return
      end

      if job.save then
         if (resdel == true)
            flash[:success] = t('jobs.flash.success.restored')
         else
            flash[:success] = t('jobs.flash.success.deleted')
            flash[:notice] = t('jobs.purge_notice')
         end
      else
         if (resdel == true)
            flash[:error] = t('jobs.flash.error.restored')
         else
            flash[:error] = t('jobs.flash.error.deleted')
         end
      end

      redirect_to :action => 'index', :deleted => deleted
   end

   def uploadfiles_prepare
      up = Hash.new
      up['preset']       = up_prepare('preset')
      up['tagtransform'] = up_prepare('tagtransform')
      up['translation']  = up_prepare('translation')
      return up
   end

   def up_prepare(uptype)
      upf = Upload.where("visibility=true and uptype=?", uptype)
      upfiles = Hash.new
      upfiles[t('jobs.newjobconf.no_file')] = 0      

      upf.each do |up|
         upfiles[up.name] = up.id
      end
      return upfiles
   end

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
