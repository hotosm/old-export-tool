class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable

   devise :database_authenticatable, :confirmable, :recoverable, :registerable, # XXX :lockable
      :validatable, :suspendable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation
  # attr_accessible :title, :body

   def active_for_authentication?
     super && !self.suspended?
   end


   has_many :uploads
   has_many :jobs
   has_many :runs

end
