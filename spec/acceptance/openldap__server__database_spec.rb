require 'spec_helper_acceptance'

describe 'openldap::server::database define' do
  describe 'creating a database' do
    it 'should work with no errors' do
      pp = <<-EOS
        class { 'openldap::server':
          databases => {
            'dc=foo,dc=example,dc=com' => {
              directory => '/var/lib/ldap/foo',
            },
          },
        }
        openldap::server::database { 'dc=bar,dc=example,dc=com':
          directory => '/var/lib/ldap/bar',
        }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end
  end
end
