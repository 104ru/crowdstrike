# frozen_string_literal: true

require 'spec_helper'

describe 'crowdstrike' do
  on_supported_os.each do |os, os_facts|
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
    end
  end
end
