module Authorize
  # used to store the different "levels" of permission
  # note: changing these constants will automatically
  #   change the methods available; use this to manage
  #   all desired levels of permission
  module Levels
    INACTIVE      = 0 unless const_defined?(:INACTIVE)
    PUBLIC_USER   = 1 unless const_defined?(:PUBLIC_USER)
    AUTHOR        = 2 unless const_defined?(:AUTHOR)
    EDITOR        = 3 unless const_defined?(:EDITOR)
    PUBLISHER     = 4 unless const_defined?(:PUBLISHER)
    ADMINISTRATOR = 5 unless const_defined?(:ADMINISTRATOR)
    
    # maintains the default level
    # tip: use with a before_create filter
    #   within the including module, and set
    #   the role field to the default
    def self.default
      INACTIVE
    end
    
    # if the inactive role is not used, this
    # method becomes synonymous with default()
    #
    # the idea is to provide access to the lowest
    # level of permissions, assuming the user has
    # already been activated
    def self.lowest
      PUBLIC_USER
    end
    
    # due to the meta-programming used to generate
    # methods on the fly, there needed to be a 
    # consistent way to access the value of a level
    # Ex: 
    #   Level.get('INACTIVE') # => 0
    #   Level.get('Inactive') # => 0
    #   Level.get(:INACTIVE)  # => 0
    #   Level.get(:inactive)  # => 0
    def self.get(level)
      raise "Invalid Permissions Level" unless constants.include?(level.to_s.upcase)
      eval(level.to_s.upcase)
    end
  end
end