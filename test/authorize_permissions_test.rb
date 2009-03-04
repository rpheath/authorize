require File.join(File.dirname(__FILE__), 'test_helper')

class MockActionController
  def self.before_filter(*args)
  end
end

class TestController < MockActionController
  include Authorize::Permissions
  
  permissions do
    public_user :index
    editor :edit, :update
    publisher :new, :create
    administrator :destroy
  end
end

def set_user_role(role)
  eval <<-METHOD
    @controller.class_eval do
      def current_user
        User.new(:role => Authorize::Levels.get('#{role}'))
      end
    end
  METHOD
end

class AuthorizePermissionsTest < Test::Unit::TestCase
  setup do
    @controller = TestController
    @levels = Authorize::Levels
  end
  
  test "should include Authorize::Permissions module" do
    assert @controller.included_modules.include?(Authorize::Permissions)
  end
  
  test "should respond to permissions" do
    assert @controller.respond_to?(:permissions)
  end
  
  test "should return permissions" do
    permissions = @controller.permissions
    assert_equal permissions[:index],   @levels.get(:public_user)
    assert_equal permissions[:edit],    @levels.get(:editor)
    assert_equal permissions[:update],  @levels.get(:editor)
    assert_equal permissions[:new],     @levels.get(:publisher)
    assert_equal permissions[:create],  @levels.get(:publisher)
    assert_equal permissions[:destroy], @levels.get(:administrator)
  end
  
  test "administrator should have access to everything" do
    set_user_role(:administrator)
    controller = @controller.new
    
    [:index, :edit, :update, :new, :create, :destroy].each do |action|
      assert controller.send(:has_permission?, action)
    end
  end
  
  test "publisher should have access to everything except for destroy" do
    set_user_role(:publisher)
    controller = @controller.new
    
    [:index, :edit, :update, :new, :create].each do |action|
      assert controller.send(:has_permission?, action)
    end
    assert !controller.send(:has_permission?, :destroy)
  end
  
  test "editor should have access to index, edit, update" do
    set_user_role(:editor)
    controller = @controller.new
    
    [:index, :edit, :update].each do |action|
      assert controller.send(:has_permission?, action)
    end
    
    [:new, :create, :destroy].each do |action|
      assert !controller.send(:has_permission?, action)
    end
  end
  
  test "public user should only have access to index" do
    set_user_role(:public_user)
    controller = @controller.new
    
    [:edit, :update, :new, :create, :destroy].each do |action|
      assert !controller.send(:has_permission?, action)
    end
    assert controller.send(:has_permission?, :index)
  end
end