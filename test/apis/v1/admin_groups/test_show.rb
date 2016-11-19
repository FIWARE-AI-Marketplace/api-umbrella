require_relative "../../../test_helper"

class TestApisV1AdminGroupsShow < Minitest::Capybara::Test
  include ApiUmbrellaTestHelpers::AdminAuth
  include ApiUmbrellaTestHelpers::Setup

  def setup
    setup_server
    AdminGroup.delete_all
  end

  def test_admins_in_group_metadata
    group = FactoryGirl.create(:admin_group)
    admin_in_group = FactoryGirl.create(:limited_admin, :last_sign_in_at => Time.now.utc, :groups => [
      group,
    ])

    response = Typhoeus.get("https://127.0.0.1:9081/api-umbrella/v1/admin_groups/#{group.id}.json", http_options.deep_merge(admin_token))

    assert_equal(200, response.code, response.body)
    data = MultiJson.load(response.body)
    assert_equal([
      {
        "id" => admin_in_group.id,
        "username" => admin_in_group.username,
        "last_sign_in_at" => admin_in_group.last_sign_in_at.utc.iso8601,
      },
    ], data["admin_group"]["admins"])
  end

  def test_admins_in_group_sorted_alpha
    group = FactoryGirl.create(:admin_group)
    admin_in_group1 = FactoryGirl.create(:limited_admin, :username => "b", :groups => [
      group,
    ])
    admin_in_group2 = FactoryGirl.create(:limited_admin, :username => "a", :groups => [
      group,
    ])

    response = Typhoeus.get("https://127.0.0.1:9081/api-umbrella/v1/admin_groups/#{group.id}.json", http_options.deep_merge(admin_token))

    assert_equal(200, response.code, response.body)
    data = MultiJson.load(response.body)
    assert_equal([
      admin_in_group2.id,
      admin_in_group1.id,
    ], data["admin_group"]["admins"].map { |admin| admin["id"] })
  end

  def test_admins_in_group_empty
    group = FactoryGirl.create(:admin_group)

    response = Typhoeus.get("https://127.0.0.1:9081/api-umbrella/v1/admin_groups/#{group.id}.json", http_options.deep_merge(admin_token))

    assert_equal(200, response.code, response.body)
    data = MultiJson.load(response.body)
    assert_equal([], data["admin_group"]["admins"])
  end
end
