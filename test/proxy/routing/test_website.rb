require_relative "../../test_helper"

class TestProxyRoutingWebsite < Minitest::Test
  include ApiUmbrellaTestHelpers::Setup
  parallelize_me!

  def setup
    setup_server
  end

  def test_default_website
    response = Typhoeus.get("http://127.0.0.1:9080/", http_options.except(:headers))
    assert_equal(200, response.code, response.body)
    assert_match("Your API Site Name", response.body)

    response = Typhoeus.get("https://127.0.0.1:9081/signup/", http_options.except(:headers))
    assert_equal(200, response.code, response.body)
    assert_match("API Key Signup", response.body)
  end

  def test_signup_https_redirect
    response = Typhoeus.get("http://127.0.0.1:9080/signup/", http_options.except(:headers))
    assert_equal(301, response.code, response.body)
    assert_equal("https://127.0.0.1:9081/signup/", response.headers["location"])
  end

  def test_signup_https_redirect_wildcard_host
    response = Typhoeus.get("http://127.0.0.1:9080/signup/", http_options.except(:headers).deep_merge({
      :headers => {
        "Host" => "unknown.foo",
      },
    }))
    assert_equal(301, response.code, response.body)
    assert_equal("https://unknown.foo:9081/signup/", response.headers["location"])
  end

  def test_signup_missing_trailing_slash
    http_opts = http_options.except(:headers)

    response = Typhoeus.get("http://127.0.0.1:9080/signup", http_opts)
    assert_equal(301, response.code, response.body)
    assert_equal("https://127.0.0.1:9081/signup", response.headers["location"])

    response = Typhoeus.get("https://127.0.0.1:9081/signup", http_opts)
    assert_equal(301, response.code, response.body)
    assert_equal("https://127.0.0.1:9081/signup/", response.headers["location"])
  end

  def test_signup_missing_trailing_slash_wildcard_host
    http_opts = http_options.except(:headers).deep_merge({
      :headers => {
        "Host" => "unknown.foo",
      },
    })

    response = Typhoeus.get("http://127.0.0.1:9080/signup", http_opts)
    assert_equal(301, response.code, response.body)
    assert_equal("https://unknown.foo:9081/signup", response.headers["location"])

    response = Typhoeus.get("https://127.0.0.1:9081/signup", http_opts)
    assert_equal(301, response.code, response.body)
    assert_equal("https://unknown.foo:9081/signup/", response.headers["location"])
  end
end
