require 'test/unit'
require 'redis'
require 'playlyfe'

class PlaylyfeTest < Test::Unit::TestCase

  def test_invalid_client
    begin
      Playlyfe.init(
        client_id: "wrong_id",
        client_secret: "wrong_secret",
        type: 'client'
      )
    rescue PlaylyfeError => e
      assert_equal e.name,'client_auth_fail'
      assert_equal e.message, 'Client authentication failed'
    end
  end

  def test_wrong_init
    begin
      Playlyfe.init(
        client_id: "Zjc0MWU0N2MtODkzNS00ZWNmLWEwNmYtY2M1MGMxNGQ1YmQ4",
        client_secret: "YzllYTE5NDQtNDMwMC00YTdkLWFiM2MtNTg0Y2ZkOThjYTZkMGIyNWVlNDAtNGJiMC0xMWU0LWI2NGEtYjlmMmFkYTdjOTI3"
      )
    rescue PlaylyfeError => e
      assert_equal e.name, 'init_failed'
    end
  end

  def test_wrong_api
    begin
      Playlyfe.init(
        client_id: "Zjc0MWU0N2MtODkzNS00ZWNmLWEwNmYtY2M1MGMxNGQ1YmQ4",
        client_secret: "YzllYTE5NDQtNDMwMC00YTdkLWFiM2MtNTg0Y2ZkOThjYTZkMGIyNWVlNDAtNGJiMC0xMWU0LWI2NGEtYjlmMmFkYTdjOTI3",
        type: 'client'
      )
      Playlyfe.get(route: '/gege', query: { player_id: 'student1' })
    rescue PlaylyfeError => e
      assert_equal e.name,'route_not_found'
      assert_equal e.message, 'This route does not exist'
    end
  end

  def test_init_staging
    Playlyfe.init(
      client_id: "Zjc0MWU0N2MtODkzNS00ZWNmLWEwNmYtY2M1MGMxNGQ1YmQ4",
      client_secret: "YzllYTE5NDQtNDMwMC00YTdkLWFiM2MtNTg0Y2ZkOThjYTZkMGIyNWVlNDAtNGJiMC0xMWU0LWI2NGEtYjlmMmFkYTdjOTI3",
      type: 'client'
    )
    players = Playlyfe.get(route: '/players', query: { player_id: 'student1', limit: 1 })
    assert_not_nil players["data"]
    assert_not_nil players["data"][0]

    begin
      assert_nil Playlyfe.get(route: '/player')
    rescue PlaylyfeError => e
      assert_equal e.message, "The 'player_id' parameter should be specified in the query"
    end

    player_id = 'student1'
    player = Playlyfe.get(route: '/player', query: { player_id: player_id } )
    assert_equal player["id"], "student1"
    assert_equal player["alias"], "Student1"
    assert_equal player["enabled"], true

    Playlyfe.get(route: '/definitions/processes', query: { player_id: player_id } )
    Playlyfe.get(route:'/definitions/teams', query: { player_id: player_id } )
    Playlyfe.get(route: '/processes', query: { player_id: player_id } )
    Playlyfe.get(route: '/teams', query: { player_id: player_id } )

    processes = Playlyfe.get(route: '/processes', query: { player_id: 'student1', limit: 1, skip: 4 })
    assert_equal processes["data"][0]["definition"], "module1"
    assert_equal processes["data"].size, 1

    new_process = Playlyfe.post(route: '/definitions/processes/module1', query: { player_id: player_id })
    assert_equal new_process["definition"], "module1"
    assert_equal new_process["state"], "ACTIVE"

    patched_process = Playlyfe.patch(
      route: "/processes/#{new_process['id']}",
      query: { player_id: player_id },
      body: { name: 'patched_process', access: 'PUBLIC' }
    )

    assert_equal patched_process['name'], 'patched_process'
    assert_equal patched_process['access'], 'PUBLIC'

    deleted_process = Playlyfe.delete(route: "/processes/#{new_process['id']}", query: { player_id: player_id })
    assert_not_nil deleted_process['message']
  end

  def test_init_production
    Playlyfe.init(
      client_id: "N2Y4NjNlYTItODQzZi00YTQ0LTkzZWEtYTBiNTA2ODg3MDU4",
      client_secret: "NDc3NTA0NmItMjBkZi00MjI2LWFhMjUtOTI0N2I1YTkxYjc2M2U3ZGI0MDAtNGQ1Mi0xMWU0LWJmZmUtMzkyZTdiOTYxYmMx",
      type: 'client'
    )
    #player = Playlyfe.get(route: '/players', query: { player_id: 'l54328754bddc332e0021a847', limit: 1 })
    #assert_equal player["data"][0]["email"], "peter@playlyfe.com"
  end

  def test_store
    redis = Redis.new
    Playlyfe.init(
      client_id: "Zjc0MWU0N2MtODkzNS00ZWNmLWEwNmYtY2M1MGMxNGQ1YmQ4",
      client_secret: "YzllYTE5NDQtNDMwMC00YTdkLWFiM2MtNTg0Y2ZkOThjYTZkMGIyNWVlNDAtNGJiMC0xMWU0LWI2NGEtYjlmMmFkYTdjOTI3",
      type: 'client',
      store: lambda { |token| redis.set('token', JSON.generate(token)) },
      retrieve: lambda { return JSON.parse(redis.get('token')) }
    )
    players = Playlyfe.get(route: '/players', query: { player_id: 'student1', limit: 1 })
    assert_not_nil players["data"]
    assert_not_nil players["data"][0]
  end

  def test_auth_code_error
    begin
      Playlyfe.init(
        client_id: "NGM2ZmYyNGQtNjViMy00YjQ0LWI0YTgtZTdmYWFlNDRkMmUx",
        client_secret: "ZTQ0OWI4YTItYzE4ZC00MWQ5LTg3YjktMDI5ZjAxYTBkZmRiZGQ0NzI4OTAtNGQ1My0xMWU0LWJmZmUtMzkyZTdiOTYxYmMx",
        type: 'code'
      )
    rescue PlaylyfeError => e
      assert_equal e.name, 'init_failed'
    end
  end

  def test_auth_code
    Playlyfe.init(
      client_id: "NGM2ZmYyNGQtNjViMy00YjQ0LWI0YTgtZTdmYWFlNDRkMmUx",
      client_secret: "ZTQ0OWI4YTItYzE4ZC00MWQ5LTg3YjktMDI5ZjAxYTBkZmRiZGQ0NzI4OTAtNGQ1My0xMWU0LWJmZmUtMzkyZTdiOTYxYmMx",
      type: 'code',
      redirect_uri: 'https://playlyfe.com/v1/api'
    )
  end
end
