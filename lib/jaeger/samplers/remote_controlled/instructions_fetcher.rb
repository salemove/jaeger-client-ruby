# frozen_string_literal: true

module Jaeger
  module Samplers
    class RemoteControlled
      class InstructionsFetcher
        FetchFailed = Class.new(StandardError)

        def initialize(host:, port:, service_name:)
          @host = host
          @port = port
          @service_name = service_name
        end

        def fetch
          http = Net::HTTP.new(@host, @port)
          path = "/sampling?service=#{CGI.escape(@service_name)}"
          response =
            begin
              http.request(Net::HTTP::Get.new(path))
            rescue StandardError => e
              raise FetchFailed, e.inspect
            end

          unless response.is_a?(Net::HTTPSuccess)
            raise FetchFailed, "Unsuccessful response (code=#{response.code})"
          end

          JSON.parse(response.body)
        end
      end
    end
  end
end
