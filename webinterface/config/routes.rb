HotExports::Application.routes.draw do

   scope "(:locale)" do
      root :to => "pages#home"
      devise_for :users

      match '/locked_users',           :to => 'users#locked_users'
      match '/active_users',           :to => 'users#active_users'
      match '/suspend_user',           :to => 'users#suspend_user'
      match '/unsuspend_user',         :to => 'users#unsuspend_user'


      match '/uploads/invisible',      :to => 'uploads#invisible'
      match '/uploads/restore',        :to => 'uploads#restore'
      match '/uploads/newfileversion', :to => 'uploads#newfileversion'
      match '/uploads/checktags',      :to => 'uploads#checktags'
      match '/uploads/defaulttags',    :to => 'uploads#defaulttags' 
     
      match '/uploads/presets',        :to => 'uploads#presets' 
      match '/uploads/tagtransforms',  :to => 'uploads#tagtransforms' 
      match '/uploads/translations',   :to => 'uploads#translations' 

      match '/jobs/invisible',         :to => 'jobs#invisible'
      match '/jobs/restore',           :to => 'jobs#restore'

      resources :uploads
      resources :jobs

      match '/wizard_area',                  :to => 'jobs#wizard_area'
      match '/wizard_configuration',         :to => 'jobs#wizard_configuration'
      match '/wizard_configuration_create',  :to => 'jobs#wizard_configuration_create'
      match '/newwithconfiguration',         :to => 'jobs#newwithconfiguration'
      match '/newwithconfiguration_create',  :to => 'jobs#newwithconfiguration_create'

      match '/reload_runs',   :to => 'jobs#reload_runs'
      match '/newrun',        :to => 'jobs#newrun'
      match '/newjob',        :to => 'jobs#wizard_area'


      match '/home',          :to => 'pages#home'

      match '/help',           :to => 'pages#help'
      match '/help_translate', :to => 'pages#help_translate'
      match '/help_transform', :to => 'pages#help_transform'
   
   end


  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
