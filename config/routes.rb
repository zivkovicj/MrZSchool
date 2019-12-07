Rails.application.routes.draw do

  root   'static_pages#home'
  get    '/help',    to: 'static_pages#help'
  get    '/about',   to: 'static_pages#about'
  get    '/contact', to: 'static_pages#contact'
  get    '/content', to: 'static_pages#content'
  get    '/partner', to: 'static_pages#partner'
  get   '/materials', to: 'static_pages#materials', :as => "materials"
  get    '/signup',  to: 'teachers#new'
  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'
  delete '/logout',  to: 'sessions#destroy'

  resources :admins
  resources :account_activations, only: [:edit]
  resources :checkpoints
  resources :commodities
  resources :commodity_students, only: [:index, :update]
  resources :consultancies
  resources :goal_students do
    get  'checkpoints', on: :member
    post 'update_checkpoints', on: :member
    get 'print', on: :collection
  end
  resources :goals
  resources :labels
  resources :label_objectives do
    post 'update_quantities', on: :collection
  end
  resources :objective_seminars do
    post 'update_pretests', on: :collection
    post 'update_priorities', on: :collection
  end
  resources :objective_students
  resources :objectives do
    get 'include_files', on: :member
    get 'include_labels', on: :member
    get 'include_seminars', on: :member
    get 'keys_for_objective', on: :member
    get 'pre_reqs', on: :member
    get 'quantities', on: :member
    post 'whole_class_keys', on: :member
  end
  resources :password_resets, only: [:new, :create, :edit, :update]
  resources :pictures
  resources :preconditions
  resources :questions do
    post 'details', on: :collection
    post 'create_group', on: :collection
  end
  resources :quizzes
  resources :ripostes do
    post 'teacher_grading', on: :collection
  end
  resources :seminars do
    get 'basic_info', on: :member
    get 'change_owner', on: :member
    get 'change_term', on: :member
    get 'copy_due_dates', on: :member
    get 'due_dates', on: :member
    get 'objectives', on: :member
    get 'pretests', on: :member
    get 'priorities', on: :member
    get 'quiz_grading', on: :member
    get 'remove', on: :member
    get 'reroute_to_student', on: :member
    get 'rewards', on: :member
    get 'scoresheet', on: :member
    get 'shared_teachers', on: :member
    post 'update_scoresheet', on: :member
    get 'usernames', on: :member
  end
  resources :seminar_students do
    get 'goal_reroute', on: :member
    get 'give_keys', on: :member
    get 'grades', on: :member
    get 'move_or_remove', on: :member
    get 'star_market', on: :member
    get 'quizzes', on: :member
    put 'quizzes', on: :member
  end
  resources :seminar_teachers do
    get 'accept_invitations', on: :collection
  end
  resources :schools
  resources :students do
    get 'edit_teaching_requests', on: :member
  end
  resources :teachers
  resources :worksheets
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
