module UsersController:: SpreeExtension::Migration
    def index
    end
    def create
        user = User.find_by(email: login_params[:email])
        if user.nil?
            user = User.create(email: login_params[:email], password: login_params[:password])    
        end
        if user && user.authenticate(login_params[:password])
            sign_in(user)
            redirect_to after_sign_in_path_for(user)
        else 
            flash[:login_errors] = ['Invalid credentials']
        end
    end
    private 
      def login_params
          params.require(:user).permit(:email, :password)
      end
end

Spree::Admin::UsersController.prepend SpreeOlittLoginExtension::Spree::Admin::UsersController