class composer(
  $target_dir      = '/usr/local/bin',
  $composer_file   = 'composer',
  $download_method = 'curl',
  $php_package     = 'php_cli',
  $logoutput       = false) {

  include augeas

  package { "$php_package":ensure => present, }

  $download_url = 'http://getcomposer.org/installer'
  $tmp_path     = '/home/vagrant'

  # download composer
  if $download_method == 'curl' {

    package { 'curl': ensure => present, }

    exec { 'download_composer':
      command     => "curl -s $download_url | php",
      cwd         => $tmp_path,
      require     => [
        Package['curl', "$php_package"],
        Augeas['whitelist_phar', 'allow_url_fopen'], ],
      creates     => "$tmp_path/composer.phar",
      logoutput   => $logoutput,
    }
  }
  elseif $download_method == 'wget' {

    package {'wget': ensure => present, }

    exec { 'download_composer':
      command     => 'wget http://getcomposer.org/composer.phar -O composer.phar',
      cwd         => $tmp_path,
      require     => [
        Package['wget'],
        Augeas['whitelist_phar', 'allow_url_fopen'], ],
      creates     => "$tmp_path/composer.phar",
      logoutput   => $logoutput,
    }
  }
  else {
    notify('please set valid $download_method to curl or wget')
  }


  # check if directory exists
  file { $target_dir:
    ensure      => directory,
  }

  # move file to target_dir
  file { "$target_dir/$composer_file":
    ensure      => present,
    source      => "$tmp_path/composer.phar",
    require     => [ Exec['download_composer'], File[$target_dir], ],
    group       => 'staff',
    mode        => '0755',
  }

  # run composer self-update
  exec { 'update_composer':
    command     => "$target_dir/$composer_file self-update",
    require     => File["$target_dir/$composer_file"],
  }

  # set /etc/php5/cli/php.ini/suhosin.executor.include.whitelist = phar
  augeas { 'whitelist_phar':
    context     => '/files/etc/php5/conf.d/suhosin.ini/suhosin',
    changes     => 'set suhosin.executor.include.whitelist phar',
    require     => Package["$php_package"],
  }

  augeas{ 'allow_url_fopen':
    context     => '/files/etc/php5/cli/php.ini/PHP',
    changes     => 'set allow_url_fopen On',
    require     => Package["$php_package"],
  }
}