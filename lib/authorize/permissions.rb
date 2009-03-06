module Authorize
  module Permissions
    class Builder
      attr_accessor :permissions
      
      def initialize
        @permissions = HashWithIndifferentAccess.new
        # set default in case there are no permissions
        # set for a specific action
        @permissions.default = Levels.default
      end
      
      # creates a new builder and evaulates
      # the given block
      def self.build(&block)
        builder = self.new
        builder.instance_eval(&block)
        builder.permissions
      end
      
      # defines a method for each level of permission
      # and assigns that level of permission to the
      # given list of actions passed in
      Levels.constants.each do |permission|
        define_method(permission.downcase) do |*args|
          add_permission(Levels.get(permission), *args)
        end
      end
      
    private
      # adds permission to an action
      def add_permission(role, *args)
        args.each do |action|
          @permissions[action] = role
        end
      end
    end
    
    module ClassMethods
      # builds the permissions lookup table based on
      # given block (returns current lookup table if no block)
      # 
      # the block is passed to Builder.build for actual construction
      # a before_filter is also registered
      # 
      # Example:
      #   class Application < ActionController::Base
      #     permissions do
      #       manager :new, :edit
      #       administrator :destroy
      #     end
      #     ...
      #   end
      def permissions(&block)
        return @permissions unless block_given?
        @permissions = Builder.build(&block)
        before_filter :ensure_permission
      end
    end
    
    module Helpers
      # provide block helpers for each defined role that
      # will only yield if the current_user has that role
      #
      # Ex:
      #   module Levels
      #     AUTHOR = 0
      #     EDITOR = 1
      #   end
      #
      #   would result in having ...
      #
      #   <% author do %>
      #     # stuff only an author would see/access
      #   <% end %>
      Levels.constants.each do |level|
        # can't use define_method because we need
        # to pass a block as a parameter; so use eval:
        eval <<-METHOD
          def #{level.downcase}(&block)
            yield if current_user.send("#{level.downcase}?")
          end
        METHOD
      end
      
      def super_user(&block)
        yield if current_user.respond_to?(:super_user?) && current_user.super_user?
      end
    end
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    protected
      # before_filter method added when permissions are
      # created for a controller - ensures that the current
      # user has permission on the current action, halting
      # with an error message if necessary
      def ensure_permission
        has_permission? :halt => true
      end
  
      # checks to see if the current user has permission
      # on the given action (or current action if nil)
      # by comparing the required access role with the 
      # user's assigned role
      #
      # Ex:
      # 
      #   def destroy
      #     @entry = Entry.find(params[:id])
      #     if has_permission? :destroy
      #       @entry.destroy
      #     end
      #   end
      # 
      # Options: 
      #   :halt => true will render an error mesage and
      #     abort the current action
      def has_permission?(action=nil, options={})
        return true if current_user.respond_to?(:super_user?) && current_user.super_user?
      
        options, action = action, nil if action.is_a?(Hash)
        action = (action || action_name).to_s
  
        permission = self.class.permissions[action]
        allowed = (permission == Levels.lowest || permission <= current_user.role.to_i)
      
        invalid_permission if !allowed && options[:halt]
      
        allowed
      end
    
      # when permission is denied
      # (modify to fit your situation)
      def invalid_permission
        flash[:warning] = "Sorry, you don't have permission to perform that action"
        redirect_to root_path
      end
  end
end