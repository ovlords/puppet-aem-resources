aem_node { 'Create http OSGI config node':
  ensure => present,
  name   => 'org.apache.felix.http',
  path   => '/apps/system/config',
  type   => 'sling:OsgiConfig',
}
