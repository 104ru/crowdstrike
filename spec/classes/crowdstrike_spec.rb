# frozen_string_literal: true

require 'spec_helper'

just_debian_and_redhat = { supported_os: [
  { 'operatingsystem' => 'Debian', 'operatingsystemrelease' => ['10'] },
  { 'operatingsystem' => 'RedHat', 'operatingsystemrelease' => ['8'] },
] }

describe 'crowdstrike' do
  on_supported_os(just_debian_and_redhat).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with ensure => present' do
        let :params do
          { 'ensure' => 'present',
            'cid' => 'AAAAAAAAAAAAA-BBB', }
        end

        it {
          is_expected.to contain_package('falcon-sensor').with(
            'ensure' => 'present',
          )
        }

        it {
          is_expected.to contain_service('falcon-sensor').with(
            'name' => 'falcon-sensor',
            'ensure' => 'running',
            'enable' => 'true',
          )
        }

        context 'with cid => undef' do
          let :params do
            { 'cid' => :undef }
          end

          it { is_expected.to compile.and_raise_error(%r{CID parameter must be specified}) }
        end

        it { is_expected.to compile }
      end

      context 'with ensure => absent' do
        let :params do
          { 'ensure' => 'absent',
            'cid' => :undef, }
        end

        if os_facts[:osfamily] == 'RedHat'
          it {
            is_expected.to contain_package('falcon-sensor').with(
              'ensure' => 'absent',
            )
          }
        end

        if os_facts[:osfamily] == 'Debian'
          it {
            is_expected.to contain_package('falcon-sensor').with(
              'ensure' => 'purged',
            )
          }
        end

        it { is_expected.not_to contain_service('falcon-sensor') }
        it { is_expected.to compile }
      end

      context 'facter parsing failure' do
        let(:facts) do
          { falcon_sensor: 'parsing_error' }
        end

        it { is_expected.to compile.and_raise_error(%r{unalbe to parse falconctl}) }
      end

      context 'facter falconctl run failure' do
        let(:facts) do
          { falcon_sensor: 'falconctl_error' }
        end

        it { is_expected.to compile.and_raise_error(%r{error while executing falconctl}) }
      end

      context 'with package source and provider' do
        let :params do
          {
            package_source: '/my/package',
            package_provider: 'rpm',
            cid: 'AAAAAAAAAAAAA-BBB'
          }
        end

        it do
          is_expected.to contain_package('falcon-sensor').with(
            source: '/my/package',
            provider: 'rpm',
          )
        end
      end

      context 'when cid is unconfigured and no fact deployed' do
        let(:params) do
          {
            cid: 'AAAAAAAAAAAAA-BBB'
          }
        end

        it { is_expected.not_to contain_exec('update-falcon-settings') }
        it { is_expected.to compile }

        context 'no proxy or tags' do
          it { is_expected.to contain_exec('register-crowdstrike').with_command('falconctl -sf --cid=AAAAAAAAAAAAA-BBB --apd=TRUE') }
        end

        context 'proxy set' do
          let(:params) do
            super().merge(proxy_host: 'server.example.com', proxy_port: 3128)
          end

          it { is_expected.to contain_exec('register-crowdstrike').with_command('falconctl -sf --cid=AAAAAAAAAAAAA-BBB --apd=FALSE --aph=server.example.com --app=3128') }
        end

        context 'tags set' do
          let(:params) do
            super().merge(tags: ['org', 'suborg'])
          end

          it { is_expected.to contain_exec('register-crowdstrike').with_command('falconctl -sf --cid=AAAAAAAAAAAAA-BBB --apd=TRUE --tags=org,suborg') }
        end

        ### Interesting case if cid has already been set, but fact is not there yet. How to test?
      end

      context 'when cid is unconfigured and fact has been deployed' do
        let(:facts) do
          super().merge(falcon_sensor: { cid: false })
        end
        let(:params) do
          { cid: 'AAAAAAAAAAAAA-BBB' }
        end

        it { is_expected.not_to contain_exec('update-falcon-settings') }
        it { is_expected.to compile }

        context 'proxy or tags not set' do
          it { is_expected.to contain_exec('register-crowdstrike').with_command('falconctl -sf --cid=AAAAAAAAAAAAA-BBB --apd=TRUE') }
        end

        context 'proxy is set' do
          let(:params) do
            super().merge(proxy_host: 'server.example.com', proxy_port: 3128)
          end

          it { is_expected.to contain_exec('register-crowdstrike').with_command('falconctl -sf --cid=AAAAAAAAAAAAA-BBB --apd=FALSE --aph=server.example.com --app=3128') }
        end

        context 'tags are set' do
          let(:params) do
            super().merge(tags: ['org', 'suborg'])
          end

          it { is_expected.to contain_exec('register-crowdstrike').with_command('falconctl -sf --cid=AAAAAAAAAAAAA-BBB --apd=TRUE --tags=org,suborg') }
        end
      end

      context 'when cid is configured and fact has been deployed.' do
        let(:facts) do
          super().merge(falcon_sensor: { cid: true })
        end
        let(:params) do
          { cid: 'AAAAAAAAAAAAA-BBB' }
        end

        it { is_expected.not_to contain_exec('register-crowdstrike') }
        it { is_expected.to compile }

        context 'when tags unconfigured and undefined' do
          let(:params) do
            super().merge(tags: :undef)
          end

          it { is_expected.not_to contain_exec('update-falcon-settings') }
        end

        context 'when proxy is unconfigured and undefined' do
          let(:params) do
            super().merge(proxy_host: :undef, proxy_port: :undef)
          end

          it { is_expected.not_to contain_exec('update-falcon-settings') }
        end

        context 'when proxy is configured and defined as the same' do
          let(:facts) do
            super().merge(falcon_sensor: {
                            cid: true,
                            proxy_disable: false,
                            proxy_host: 'server.example.com',
                            proxy_port: 3128,
                          })
          end
          let(:params) do
            super().merge(proxy_host: 'server.example.com', proxy_port: 3128)
          end

          it { is_expected.not_to contain_exec('update-falcon-settings') }
        end

        context 'when tags are configured and defined as the same' do
          let(:facts) do
            super().merge(falcon_sensor: {
                            cid: true,
                            tags: ['org', 'suborg'],
                          })
          end
          let(:params) do
            super().merge(tags: ['org', 'suborg'])
          end

          it { is_expected.not_to contain_exec('update-falcon-settings') }
        end

        context 'when tags are configured, but need to be changed' do
          let(:facts) do
            super().merge(falcon_sensor: {
                            cid: true,
                            tags: ['org'],
                          })
          end
          let(:params) do
            super().merge(tags: ['org', 'suborg'])
          end

          it { is_expected.to contain_exec('update-falcon-settings').with_command('falconctl -sf --tags=org,suborg') }
        end

        context 'when proxy is configured, but port needs to be changed' do
          let(:facts) do
            super().merge(falcon_sensor: {
                            cid: true,
                            proxy_disable: false,
                            proxy_host: 'server.example.com',
                            proxy_port: 3128
                          })
          end
          let(:params) do
            super().merge(proxy_host: 'server.example.com', proxy_port: 8080)
          end

          it { is_expected.to contain_exec('update-falcon-settings').with_command('falconctl -sf --apd=FALSE --aph=server.example.com --app=8080') }
        end

        context 'when proxy is configured, but server needs to be changed' do
          let(:facts) do
            super().merge(falcon_sensor: {
                            cid: true,
                            proxy_disable: false,
                            proxy_host: 'server.example.com',
                            proxy_port: 3128,
                          })
          end
          let(:params) do
            super().merge(proxy_host: 'proxy.example.com', proxy_port: 3128)
          end

          it { is_expected.to contain_exec('update-falcon-settings').with_command('falconctl -sf --apd=FALSE --aph=proxy.example.com --app=3128') }
        end

        context 'when proxy server is undefined, but port is' do
          let(:params) do
            super().merge(proxy_host: :undef, proxy_port: 3128)
          end

          it { is_expected.not_to contain_exec('update-falcon-settings') }
        end

        context 'when proxy server is defined, but port is not' do
          let(:params) do
            super().merge(proxy_host: 'proxy.example.com', proxy_port: :undef)
          end

          it { is_expected.not_to contain_exec('update-falcon-settings') }
        end

        context 'when proxy is unconfigured, but needs to be.' do
          let(:facts) do
            super().merge(falcon_sensor: {
                            cid: true,
                            proxy_disable: true,
                            proxy_host: 'proxy.example.com',
                            proxy_port: 8080,
                          })
          end
          let(:params) do
            super().merge(proxy_host: 'server.example.com', proxy_port: 3128)
          end

          it { is_expected.to contain_exec('update-falcon-settings').with_command('falconctl -sf --apd=FALSE --aph=server.example.com --app=3128') }
        end

        context 'when tags are unconfigured, but needs to be.' do
          let(:facts) do
            super().merge(falcon_sensor: {
                            cid: true,
                          })
          end
          let(:params) do
            super().merge(tags: ['org', 'suborg'])
          end

          it { is_expected.to contain_exec('update-falcon-settings').with_command('falconctl -sf --tags=org,suborg') }
        end
      end
    end
  end
end
