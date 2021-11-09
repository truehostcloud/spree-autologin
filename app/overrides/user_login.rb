Deface::new(
    :virtual_path => 'admin/login',
    :name => 'olitt_login',
    :replace => '[data-hook]=login',
    :partial => 'users/index'
)