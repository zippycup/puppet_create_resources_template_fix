# Using puppet create_resources to support resource file template

## Description

create_resources is the most fantastic utility to make use of of hiera yaml instead of the native puppet langauge. 

With create_resources, you can make puppet be ansible like by declaring everything in yaml.

For the most part, it works quite well. One of the biggest issues
involves the following resource example:

```
file { '/usr/lib/systemd/system/httpd.service' : 
  content => template('httpd/httpd.service.erb'),
  owner   => 'root',
  group   => 'root',
}
```

This translate to hiera:

```
/usr/lib/systemd/system/httpd.service:
  content: template('httpd/httpd.service.erb')
  owner: root
  group: root
```

Puppet does not understand the 'template' object when it is define in the yaml as text.
This module attempts to make it easier to call define resource easier.

Note, normally you can reference a local scoped variable to pass to a file template such as

``
myvariable=<%=@myvariable%>
``

Please use the full path to the variable in the template as the scope of local variable will not exist.

```
myvariable=<%= scope.lookupvar("[fullpath_to_variable]::myvariable") %>
```

## Requirements

puppet 3 +

## Installation

copy call_define.pp to [path_to_module]/hiera_util/manifests

## Example

hiera data
Note in that in the call_define section there are two types of define resources file and apache::vhost
```
profile_web:

  apache:
    servername: www.mydomain.com
    max_keepalive_requests: 0
    timeout: 60
    vhost_root: /var/www/vhost

  call_define:

    file:
      /usr/lib/systemd/system/httpd.service:
        content: template('httpd/httpd.service.erb')
        owner: root
        group: root

      /var/log/httpd:
        ensure: directory
        owner: root
        group: root
  

    apache::vhost:
      mydomain.com:
        port: 80
        docroot: /var/www/vhost/mydomain.com
        docroot_owner: apache
        docroot_group: apache
        manage_docroot: true
        scriptalias: /var/www/cgi-bin

        directories:
          path: /var/www/vhost/mydomain.com
          options:
            - FollowSymLinks
          allow_override: None
          directoryindex: index.php index.htm default.htm index.html

```

puppet code
```
class profile::web ( $hiera_key = 'profile_web' ) {

  $conf = hiera_hash( $hiera_key )

  $servername             = $conf['apache']['servername']
  $timeout                = $conf['apache']['timeout']
  $max_keepalive_requests = $conf['apache']['max_keepalive_requests']
  $allow_from             = $conf['apache']['status']['allow_from']
  $vhost_root             = $conf['apache']['vhost_root']

  class { 'apache':
    servername             => $servername,
    mpm_module             => false,
    default_vhost          => false,
    timeout                => $timeout,
    max_keepalive_requests => $max_keepalive_requests,
  }

  hiera_util::call_define { 'apache::vhost':
    conf     => $conf,
  } ->

  hiera_util::call_define { 'file':
    conf     => $conf,
  }
  
```
