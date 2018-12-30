require 'spec_helper'

RSpec.describe Jaeger::Encoders::ThriftEncoder do
  let(:encoder) { described_class.new(service_name: service_name, tags: tags) }
  let(:service_name) { 'service-name' }
  let(:tags) { {} }

  context 'without custom tags' do
    it 'has jaeger.version' do
      tags = encoder.encode([]).process.tags
      version_tag = tags.detect { |tag| tag.key == 'jaeger.version' }
      expect(version_tag.vStr).to match(/Ruby-/)
    end

    it 'has hostname' do
      tags = encoder.encode([]).process.tags
      hostname_tag = tags.detect { |tag| tag.key == 'hostname' }
      expect(hostname_tag.vStr).to be_a(String)
    end

    it 'has ip' do
      tags = encoder.encode([]).process.tags
      ip_tag = tags.detect { |tag| tag.key == 'ip' }
      expect(ip_tag.vStr).to be_a(String)
    end
  end

  context 'when hostname is provided' do
    let(:tags) { { 'hostname' => hostname } }
    let(:hostname) { 'custom-hostname' }

    it 'uses provided hostname in the process tags' do
      tags = encoder.encode([]).process.tags
      hostname_tag = tags.detect { |tag| tag.key == 'hostname' }
      expect(hostname_tag.vStr).to eq(hostname)
    end
  end

  context 'when ip is provided' do
    let(:tags) { { 'ip' => ip } }
    let(:ip) { 'custom-ip' }

    it 'uses provided ip in the process tags' do
      tags = encoder.encode([]).process.tags
      ip_tag = tags.detect { |tag| tag.key == 'ip' }
      expect(ip_tag.vStr).to eq(ip)
    end
  end
end
