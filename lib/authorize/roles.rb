module Authorize
  module Roles
    class Role
      require 'ostruct'
      
      # a hash of all available roles, as
      # according to Authorize::Levels
      def self.roles
        returning({}) do |levels|
          Levels.constants.each do |level|
            levels.merge!(Levels.get(level) => OpenStruct.new(:name => format(level), :role => Levels.get(level)))
          end
        end
      end
      
      # returns the roles as a list of options for a drop down
      def self.to_options(include_default = true, options = {})
        select_options = Hash[*roles.values.collect { |e| [e.name, e.role] }.flatten].sort { |a, b| a[1] <=> b[1] }
        include_default ? [[(options[:default_text] || '-- Choose Role --'), nil]] + select_options : select_options
      end
      
    private
      # if you have specific formatting rules/conditions
      # for how the role name is presented, modify the
      # format() method
      def self.format(level)
        level.titleize
      end
    end
    
    # defining instance methods for the "user" model
    # as according to Authorize::Levels
    # 
    # Ex:
    #   module Authorize
    #     module Levels
    #       PUBLIC_USER   = 0 unless const_defined?(:PUBLIC_USER)
    #       ADMINISTRATOR = 1 unless const_defined?(:ADMINISTRATOR)
    #     end
    #   end
    #
    #   current_user.public_user?     # => true/false
    #   current_user.administrator?   # => true/false
    Levels.constants.each do |level|
      define_method("#{level.downcase}?") do
        return true if self.respond_to?(:super_user?) && self.super_user?
        self.role.to_i >= Levels.get(level)
      end
    end
    
    # used to manage an inactive role/state
    # note: must check == over >= because
    #   escalating permissions will return
    #   a false positive otherwise
    #
    # also: a super_user is always active
    def inactive?
      return false if self.respond_to?(:super_user?) && self.super_user?
      self.role.to_i == Levels.get(:inactive)
    end
    
    # compliments inactive?
    def active?
      !inactive?
    end
    
    # used for displaying the current users role
    # Ex:
    #   current_user.role_name # => 'Administrator'
    #   current_user.role = nil
    #   current_user.role_name # => 'Not Specified'
    def role_name
      return 'Super User' if self.respond_to?(:super_user?) && self.super_user?
      return 'Not Specified' unless self.role.is_a?(Integer)
      Role.roles[self.role].name
    end
    
    module ClassMethods
      # returns a list of all available role names
      def available_roles
        Role.roles.values.map(&:name)
      end
    end
    
    def self.included(base)
      base.extend ClassMethods
      
      # define named scopes for each permission level
      base.class_eval do
        Levels.constants.each do |level|
          # remove the following line if you're not
          # making use of the 'INACTIVE' role/state
          next if level.downcase.to_sym == :inactive
          
          # defining the named scopes
          named_scope level.downcase.pluralize.to_sym,
            :conditions => ["role >= ?", Levels.get(level)]
        end
      end
    end
  end
end