Deface.new(
  virtual_path: 'admin/auto_login',
  name: 'olitt_login',
  replace: '[data-hook]=login',
  partial: 'users/index'
)
