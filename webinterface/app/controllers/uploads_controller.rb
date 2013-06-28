class UploadsController < ApplicationController

   before_filter :authenticate_user!, 
      :except => [
         :index, :presets, :tagtransforms, :translations, 
         :checktags, :defaulttags
      ]

   require 'fileutils'

   def index
      @title = t('uploads.index.title')
   end

   def presets
      @title = t('uploads.presets.title')
      @hide_invisible = true
      @uploads = Upload.where("uptype=?", 'preset')
   end

   def tagtransforms
      @title = t('uploads.tagtransforms.title')
      @hide_invisible = true
      @uploads = Upload.where("uptype=?", 'tagtransform')
   end

   def translations
      @title = t('uploads.translations.title')
      @hide_invisible = true
      @uploads = Upload.where("uptype=?", 'translation')
   end

   def edit
      @title = t('uploads.update.title')
      @upload = Upload.find(params[:id])
   end

   def newfileversion
      @upload = Upload.find(params[:id])
      @upload.updated_at = Time.now
      @upload.visibility = true
      @upload.user_id = current_user.id

      real_filename = @upload.filename
      test_filename = "test_" + real_filename
      @upload.filename = test_filename

      @upload.save_upload(params[:uploadfile])
      u_error = 0

      # preset files are checked
      if @upload.uptype == 'preset' then
         begin
            tags = Tag.from_xml(@upload.f_xml)
         rescue Exception => @e
            u_error = 1
         end
      end

      if u_error == 0
         @upload.filename = real_filename
         @upload.move_upload(test_filename)

         flash[:success] = "#{t('uploads.flash.success.newversion_saved')} #{@upload.name}"
         redirect_to(uploads_path)
      elsif u_error == 1
         flash.now[:error] = t('uploads.flash.error.xml_parsing_failed')

         @title = t('uploads.update.title')
         render 'edit'
      end
   end

   def new
      @title = t('uploads.newupload.title')
      @upload = Upload.new
   end

   def create
      @upload = Upload.new(params[:upload])
      @upload.user_id = current_user.id

      if @upload.complete_save(@upload.uploadfile) then
         begin
            u_error = 0
            @upload.upload_check
         rescue Exception => @e
            u_error = 1
         end
      else
         u_error = 2
      end

      if u_error == 0
         flash[:success] = t('uploads.flash.success.saved')
         redirect_to_uploads @upload.uptype
      elsif u_error == 1
         @upload.complete_delete
         flash[:error] = t('uploads.flash.error.xml_parsing_failed')
         @title = "New Upload"
         render 'new'
      else
         flash[:error] = t('uploads.flash.error.not_saved')
         @title = "New Upload"
         render 'new'
      end
   end

   def invisible
      change_visibility(params[:id], false)
   end

   def restore
      change_visibility(params[:id], true)
   end

   def checktags
      @upload = Upload.find(params[:id])

      begin
         @tags = Tag.from_xml(@upload.f_xml)
      rescue Exception => @e
         @tags = t('uploads.error.xml_exception')
      end

      @title = t('uploads.tagpreview.title')
   end

   def defaulttags
      @tags = Tag.default_tags
      @title = t('uploads.defaulttags.title')
   end


private

   def change_visibility(id,resdel) 
      upload = Upload.find(id)
      upload.uploadfile = 'no new uploadfile'      

      # XXX upload.visibility = resdel
      upload.toggle!(:visibility)


      if !user_right_deletion? upload
         if (resdel == true)
            flash[:error] = t('uploads.flash.error.restored')
         else
            flash[:error] = t('uploads.flash.error.deleted')
         end
      else
         
         if upload.save then
            if (resdel == true)
               flash[:success] = t('uploads.flash.success.restored')
            else
               flash[:success] = t('uploads.flash.success.deleted')
            end
         else
            if (resdel == true)
               flash[:error] = t('uploads.flash.error.restored')
            else
               flash[:error] = t('uploads.flash.error.deleted')
            end
         end
      end

      @hide_invisible = !resdel

      @uploads = Upload.where("uptype=?", upload.uptype)

      redirect_to_uploads upload.uptype
   end


   def redirect_to_uploads uptype
      if (uptype == 'preset')
         redirect_to :action => 'presets'

      elsif (uptype == 'tagtransform')
         redirect_to :action => 'tagtransforms'

      elsif (uptype == 'translation')
         redirect_to :action => 'translations'

      else 
         redirect_to :action => 'presets'
      end
   end

end

