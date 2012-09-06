class composer(
  $target_dir      = '/usr/local/bin',
  $composer_file   = 'composer',
  $download_method = 'curl',
  $logoutput       = false) {

  include augeas

  $php_package     = 'php-cli'
  $tmp_path        = '/home/vagrant'

  package { $php_package:ensure => present, }

  # download composer
  if $download_method == 'curl' {

    package { 'curl': ensure => present, }

    exec { 'download_composer':
      command     => 'curl -s http://getcomposer.org/installer | php',
      cwd         => $tmp_path,
      require     => [
        Package['curl', $php_package] ],
      creates     => "$tmp_path/composer.phar",
      logoutput   => $logoutput,
    }
  }
  elsif $download_method == 'wget' {

    package {'wget': ensure => present, }

    exec { 'download_composer':
      command     => 'wget http://getcomposer.org/composer.phar -O composer.phar',
      cwd         => $tmp_path,
      require     => [
        Package['wget'] ],
      creates     => "$tmp_path/composer.phar",
      logoutput   => $logoutput,
    }
  }
  else {
    fail("The param download_method $download_method is not valid. Please set download_method to curl or wget.")
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
}
