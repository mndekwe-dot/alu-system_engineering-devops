# Fixes Nginx failed requests by increasing the ULIMIT of open files

exec { 'fix--for-nginx':
  command => 'sed -i "s/ULIMIT=.*/ULIMIT=\"-n 4096\"/" /etc/default/nginx && service nginx restart',
  path    => '/usr/local/bin/:/bin/:/usr/bin/:/usr/sbin/:/sbin/',
}
