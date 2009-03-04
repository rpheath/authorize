require File.join(File.dirname(__FILE__), 'test_helper')

class AuthorizeLevelsTest < Test::Unit::TestCase
  test "should return a default level" do
    assert 0, Authorize::Levels.default
  end
  
  test "should return the lowest level" do
    assert 1, Authorize::Levels.lowest
  end
  
  test "should get a level by string or symbol (case insensitive)" do
    assert 0, Authorize::Levels.get('INACTIVE')
    assert 1, Authorize::Levels.get('public_user')
    assert 2, Authorize::Levels.get(:author)
    assert 3, Authorize::Levels.get(:EDITOR)
  end
  
  test "should raise invalid permissions level error appropriately" do
    begin
      Authorize::Levels.get('UNDEFINED_LEVEL')
    rescue Exception => e
      assert 'Invalid Permissions Level', e.message
    end
  end
end