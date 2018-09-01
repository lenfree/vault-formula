describe command('/usr/local/bin/vault -version') do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should be_empty }
  its(:stdout) { should match(/^Vault v[0-9\.]+ \('[0-9a-f]+'\)/) }
end

describe file('/etc/vault/config/server.hcl') do
  it { should be_a_file }
  expected =<<-EOF

storage "s3" {
  bucket = "com-saltstack-vault"
}
ui = true
telemetry {
  dogstatsd_addr = "localhost:8125"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 0

}

default_lease_ttl="24h"
max_lease_ttl="24h"
EOF
  its(:content) { should eq(expected) }
end

describe file('/etc/systemd/system/vault.service') do
  it { should be_a_file }
  its(:content) { should_not match /syslog/ }
end

describe file('/etc/init/vault.conf') do
  it { should_not be_a_file }
end

describe service('vault') do
  it { should be_enabled }
  it { should be_running }
end

describe command('journalctl -u vault') do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should be_empty }
  its(:stdout) { should match(/WARNING! dev mode is enabled! In this mode, Vault runs entirely in-memory/) }
end

