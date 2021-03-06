# See README.md for details.
class openldap::server::config {

  if ! defined(Class['openldap::server']) {
    fail 'class ::openldap::server has not been evaluated'
  }

  if $::openldap::server::provider == 'augeas' {
    $ensure = $::openldap::server::ensure ? {
      present => present,
      default => absent,
    }
    file { $::openldap::server::file:
      ensure => $ensure,
      owner  => $::openldap::server::owner,
      group  => $::openldap::server::group,
      mode   => '0640',
    }
  }

  if ($::openldap::server::ssl) and ($::openldap::server::ensure == present) {
    validate_absolute_path($::openldap::server::ssl_cert)
    validate_absolute_path($::openldap::server::ssl_key)
    openldap::server::globalconf { 'TLSCertificateFile':
      value => $::openldap::server::ssl_cert,
    }
    ->
    openldap::server::globalconf { 'TLSCertificateKeyFile':
      value => $::openldap::server::ssl_key,
    }
    if $::openldap::server::ssl_ca {
      validate_absolute_path($::openldap::server::ssl_ca)
      openldap::server::globalconf { 'TLSCACertificateFile':
        value => $::openldap::server::ssl_ca,
      }
    }
  }

  case $::osfamily {
    Debian: {
      $slapd_services = $::openldap::server::ssl ? {
        true  => 'ldap:/// ldaps:/// ldapi:///',
        false => 'ldap:/// ldapi:///',
      }

      shellvar { 'slapd':
        ensure   => present,
        target   => '/etc/default/slapd',
        variable => 'SLAPD_SERVICES',
        value    => $slapd_services,
      }
    }
    RedHat: {
      shellvar { 'SLAPD_LDAP':
        ensure   => present,
        target   => '/etc/sysconfig/ldap',
        variable => 'SLAPD_LDAP',
        value    => 'yes',
      }
      $slapd_ldaps_ensure = $::openldap::server::ssl ? {
        true  => present,
        false => absent,
      }
      shellvar { 'SLAPD_LDAPS':
        ensure    => $slapd_ldaps_ensure,
        target    => '/etc/sysconfig/ldap',
        variable  => 'SLAPD_LDAPS',
        value     => $::openldap::server::ssl ? {
          true    => 'yes',
          default => 'no',
        },
      }
      shellvar { 'SLAPD_LDAPI':
        ensure   => present,
        target   => '/etc/sysconfig/ldap',
        variable => 'SLAPD_LDAPI',
        value    => 'yes',
      }
    }
    default: {
      fail "Operating System Family ${::osfamily} not yet supported"
    }
  }

  create_resources('openldap::server::database', $::openldap::server::databases)
}
