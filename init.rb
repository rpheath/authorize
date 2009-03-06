ActionController::Base.send(:include, Authorize::Permissions)
ActionView::Base.send(:include, Authorize::Permissions::Helpers)