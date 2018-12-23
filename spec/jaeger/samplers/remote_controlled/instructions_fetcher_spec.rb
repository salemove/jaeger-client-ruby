require 'spec_helper'

RSpec.describe Jaeger::Samplers::RemoteControlled::InstructionsFetcher do
  let(:fetcher) { described_class.new(host: host, port: port, service_name: service_name) }
  let(:host) { 'some-host' }
  let(:port) { 1234 }
  let(:service_name) { 'test-service' }

  it 'returns parsed response on success' do
    body = { 'foo' => 'bar' }
    serialized_body = body.to_json

    stub_request(:get, "http://#{host}:#{port}/sampling?service=#{service_name}")
      .to_return(status: 200, body: serialized_body, headers: {})

    expect(fetcher.fetch).to eq(body)
  end

  it 'raises FetchFailed when http code is not 2xx' do
    stub_request(:get, "http://#{host}:#{port}/sampling?service=#{service_name}")
      .to_return(status: 400, body: 'Bad Request', headers: {})

    expect { fetcher.fetch }
      .to raise_error(described_class::FetchFailed, 'Unsuccessful response (code=400)')
  end

  it 'raises FetchFailed when request throws an exception' do
    stub_request(:get, "http://#{host}:#{port}/sampling?service=#{service_name}")
      .to_raise(StandardError.new('some error'))

    expect { fetcher.fetch }
      .to raise_error(described_class::FetchFailed, '#<StandardError: some error>')
  end
end
