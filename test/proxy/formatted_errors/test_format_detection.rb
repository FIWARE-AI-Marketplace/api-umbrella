require_relative "../../test_helper"

class TestProxyFormattedErrorsFormatDetection < Minitest::Test
  include ApiUmbrellaTestHelpers::Setup
  include ApiUmbrellaTestHelpers::FormattedErrors
  parallelize_me!

  def setup
    setup_server
  end

  def test_first_priority_path_extension
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello.xml?format=json", http_options.except(:headers).deep_merge({
      :headers => {
        "Accept" => "application/json",
      },
    }))
    assert_xml_error(response)
  end

  def test_second_priority_query_param
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello?format=xml", http_options.except(:headers).deep_merge({
      :headers => {
        "Accept" => "application/json",
      },
    }))
    assert_xml_error(response)
  end

  def test_third_priority_content_negotiation
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello", http_options.except(:headers).deep_merge({
      :headers => {
        "Accept" => "application/json;q=0.5,application/xml;q=0.9",
      },
    }))
    assert_xml_error(response)
  end

  def test_defaults_to_json_when_no_format_detected
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello", http_options.except(:headers))
    assert_json_error(response)
  end

  def test_defaults_to_json_when_unsupported_format_detected
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello.mov", http_options.except(:headers))
    assert_json_error(response)
  end

  def test_defaults_to_json_when_unknown_format_detected
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello.zzz", http_options.except(:headers))
    assert_json_error(response)
  end

  def test_uses_path_extension_despite_invalid_query_params
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello.xml?format=json&test=test&url=%ED%A1%BC", http_options.except(:headers))
    assert_xml_error(response)
  end

  def test_gracefully_handles_array_format_query_param
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello?format[]=xml", http_options.except(:headers))
    assert_json_error(response)
  end

  def test_gracefully_handles_duplicate_format_query_param
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello?format=xml&format=csv", http_options.except(:headers))
    assert_xml_error(response)
  end

  def test_gracefully_handles_hash_format_query_param
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello?format[key]=xml", http_options.except(:headers))
    assert_json_error(response)
  end

  def test_gracefully_handles_empty_array_format_query_param
    response = Typhoeus.get("http://127.0.0.1:9080/api/hello?format[]=", http_options.except(:headers))
    assert_json_error(response)
  end
end
