class PagesController < ApplicationController

   def home
      @title = t('home.title')
   end

   def help
      @title = t('help.title')
   end

   def help_translate
      @title = t('help.translation.title')
   end

   def help_transform
      @title = t('help.transform.title')
   end
end
