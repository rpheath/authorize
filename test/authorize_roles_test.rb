require File.join(File.dirname(__FILE__), 'test_helper')

class AuthorizeRolesTest < Test::Unit::TestCase
  setup do
    @user = User.new
  end
  
  def expects_role(role)
    @user.expects(:role).at_least(1).returns(role)
  end
  
  test "should include the Authorize::Roles module" do
    assert User.included_modules.include?(Authorize::Roles)
  end
  
  test "should return a hash of OpenStructs with all available roles" do
    roles = User::Role.roles
    
    assert roles.is_a?(Hash)
    assert roles.values.all? { |val| val.is_a?(OpenStruct) }
    assert roles.values.first.name.is_a?(String)
    assert roles.values.first.role.is_a?(Integer)
  end
    
  test "should return an array of all available role names" do
    assert User.available_roles.is_a?(Array)
    assert_equal 6, User.available_roles.size
  end
  
  test "should format the role names" do
    @user.expects(:role).at_least(1).returns(4)
    assert_equal 'Publisher', @user.role_name
  end
  
  test "should format the role names with underscores" do
    @user.expects(:role).at_least(1).returns(1)
    assert_equal 'Public User', @user.role_name
  end
  
  test "should return roles as select (drop down) options" do
    options = User::Role.to_options
    assert_equal 7, options.size
    assert options.all? { |o| o.is_a?(Array) }
  end
  
  test "should return a default select option as first option" do
    assert_equal ['-- Choose Role --', nil], User::Role.to_options.first
  end
  
  test "should not return a default select option" do
    assert_equal ['Inactive', 0], User::Role.to_options(false).first
  end
  
  test "should allow for custom text on default select option" do
    assert_equal ['--', nil], User::Role.to_options(true, :default_text => '--').first
  end
  
  test "should create instance methods for each permission level" do
    assert @user.respond_to?(:inactive?)
    assert @user.respond_to?(:public_user?)
    assert @user.respond_to?(:author?)
    assert @user.respond_to?(:editor?)
    assert @user.respond_to?(:publisher?)
    assert @user.respond_to?(:administrator?)
  end
  
  test "should permit escalating permissions" do
    expects_role(3) # => editor
    
    assert @user.public_user?
    assert @user.author?
    assert @user.editor?
    assert !@user.publisher?
    assert !@user.administrator?
  end
  
  test "should be inactive if no role is specified" do
    expects_role(nil) # => not specified
    assert @user.inactive?
  end
  
  test "inactive? should bypass escalating permissions structure" do
    expects_role(1) # => public user
    assert !@user.inactive?
  end
  
  test "should return the proper role name" do
    expects_role(0) # => inactive
    assert 'Inactive', @user.role_name
    
    expects_role(1) # => public user
    assert 'Public User', @user.role_name
    
    expects_role(2) # => author
    assert 'Author', @user.role_name
    
    expects_role(3) # => editor
    assert 'Editor', @user.role_name
    
    expects_role(4) # => publisher
    assert 'Publisher', @user.role_name
    
    expects_role(5) # => administrator
    assert 'Administrator', @user.role_name
  end
  
  test "should return 'Super User' appropriately, regardless of set role" do
    @user.stubs(:super_user?).returns(true)
    assert 'Super User', @user.role_name
  end
  
  test "should return 'Not Specified' if no role is set" do
    @user.stubs(:role).returns(nil)
    assert 'Not Specified', @user.role_name
  end
  
  test "should create named_scope methods for each permission level" do
    assert User.respond_to?(:public_users)
    assert User.respond_to?(:authors)
    assert User.respond_to?(:editors)
    assert User.respond_to?(:publishers)
    assert User.respond_to?(:administrators)
  end
  
  test "should not create a named_scope for inactive role" do
    assert !User.respond_to?(:inactives)
  end
end