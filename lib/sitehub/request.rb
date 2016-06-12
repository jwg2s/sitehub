require 'rack/request'
require 'sitehub/string_sanitiser'
require 'sitehub/http_headers'

class SiteHub
  class Request
    include StringSanitiser, Constants, HttpHeaders

    extend Forwardable

    def_delegator :@rack_request, :params
    def_delegator :@rack_request, :url
    def_delegator :@rack_request, :path

    attr_reader :env, :rack_request

    def initialize(env)
      @rack_request = Rack::Request.new(env)
      @env = filter_http_headers(extract_http_headers_from_rack_env(env))
    end

    def request_method
      @request_method ||= rack_request.request_method.downcase.to_sym
    end

    def body
      @body ||= rack_request.body.read
    end

    def headers
      @env.tap do |headers|
        # x-forwarded-for
        headers[X_FORWARDED_FOR_HEADER] = x_forwarded_for

        # x-forwarded-host
        headers[X_FORWARDED_HOST_HEADER] = x_forwarded_host
      end
    end

    private

    def remote_address
      rack_request.env[RackHttpHeaderKeys::REMOTE_ADDRESS_ENV_KEY]
    end

    def x_forwarded_host
      split(env[HttpHeaderKeys::X_FORWARDED_HOST_HEADER])
        .push(env[HttpHeaderKeys::HOST_HEADER])
        .join(COMMA)
    end

    def x_forwarded_for
      split(env[HttpHeaderKeys::X_FORWARDED_FOR_HEADER]).push(remote_address).join(COMMA)
    end
  end
end
