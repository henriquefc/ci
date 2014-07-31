class ci::server (
  $maven_version     = '3.2.1',
  $nexus_version     = '2.8.1',
  $sonarqube_version = '4.3.2'
) {
  include ci

  ###################################
  # Install maven ###################
  ###################################
  class { 'maven::maven':
    version => "${maven_version}"
  }

  ###################################
  # Install jenkins #################
  ###################################
  class { 'jenkins':
    config_hash => {
      'HTTP_PORT'    => { 'value' => '18080' },     
      'JAVA_ARGS'    => { 'value' => '-Xmx256m' },
      'JENKINS_ARGS' => { 'value' => '--webroot=/var/cache/jenkins/war --httpPort=$HTTP_PORT --ajp13Port=$AJP_PORT --prefix=$PREFIX --httpListenAddress=127.0.0.1' }
    }
  }

  $jenkins_plugins = [
    'ssh-credentials',
    'credentials',
    'scm-api',
    'git-client',
    'git',
    'maven-plugin',
    'javadoc',
    'mailer',
    'greenballs',
    'ws-cleanup',
    'token-macro',
    'nodelabelparameter',
    'parameterized-trigger',
    'copyartifact',
    'jquery',
    'build-pipeline-plugin',
    'groovy',
    'chromedriver',
    'xvnc'  
  ]
  jenkins::plugin { $jenkins_plugins: }

  file { '/var/lib/jenkins/hudson.tasks.Maven.xml':
    mode    => 0644,
    owner   => 'jenkins',
    group   => 'jenkins',
    content => template('ci/jenkins/hudson.tasks.Maven.xml'),
    require => Class['jenkins::package'],
    notify  => Service['jenkins']
  }

  ###################################
  # Install nexus ###################
  ###################################
  class { 'nexus':
    version    => "${nexus_version}",
    nexus_host => '127.0.0.1',
    nexus_port => '18081'
  }

  ###################################
  # Install sonarqube ###############
  ###################################
  class { 'sonarqube':
    version      => "${sonarqube_version}",
    host         => '127.0.0.1',
    port         => '18082',
    context_path => '/sonar'
  }

  ###################################
  # Install apache ##################
  ###################################
  class { 'apache':
    default_vhost => false
  }

  $apache_mods = [
    'proxy',
    'proxy_http'
  ]
  apache::mod { $apache_mods: }
  apache::listen { '80': }

  file { ['/var', '/var/htdocs', '/var/htdocs/ci.srv.intranet']:
    ensure  => 'directory',
  }

  file { '/etc/apache2/conf.d/ci.srv.intranet.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/ci/apache/ci.srv.intranet.conf',
    require => Class['apache'],
    notify  => Service['httpd']
  }
}
