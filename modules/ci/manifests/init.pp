class ci {
  class { 'apt':
    always_apt_update => true,
  }

  Class['apt'] -> Package <| |>

  package { ['vim', 'git', 'rubygems']:
    ensure => 'installed'
  }

  package { ['fpm', 'bundler']:
    ensure   => 'installed',
    provider => 'gem',
    require  => Package['rubygems']
  }
}
