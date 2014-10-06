require 'test/unit'
require 'redis'
require 'playlyfe'

class PlaylyfeTest < Test::Unit::TestCase

  def test_invalid_client
    Playlyfe.init(
      client_id: "wrong_id",
      client_secret: "wrong_secret",
      test: true
    )
  end

  def test_wrong_api
    Playlyfe.init(
      client_id: "Zjc0MWU0N2MtODkzNS00ZWNmLWEwNmYtY2M1MGMxNGQ1YmQ4",
      client_secret: "YzllYTE5NDQtNDMwMC00YTdkLWFiM2MtNTg0Y2ZkOThjYTZkMGIyNWVlNDAtNGJiMC0xMWU0LWI2NGEtYjlmMmFkYTdjOTI3",
      test: true
    )
    Playlyfe.get('/gege', player_id: 'student1')
  end

  def test_init_staging
    Playlyfe.init(
      client_id: "Zjc0MWU0N2MtODkzNS00ZWNmLWEwNmYtY2M1MGMxNGQ1YmQ4",
      client_secret: "YzllYTE5NDQtNDMwMC00YTdkLWFiM2MtNTg0Y2ZkOThjYTZkMGIyNWVlNDAtNGJiMC0xMWU0LWI2NGEtYjlmMmFkYTdjOTI3",
      #store: lambda { |access_token| redis.hmset "store" },
      #retrieve: lambda { return Marshal.load(Marshal.dump(access_token.to_hash)) },
      test: true
    )
    players = Playlyfe.get('/players', player_id: 'student1', limit: 1)
    assert_not_nil players["data"]
    assert_not_nil players["data"][0]

    assert_nil Playlyfe.get('/player')

    player_id = 'student1'
    player = Playlyfe.get( '/player', player_id: player_id)
    assert_equal player["id"], "student1"
    assert_equal player["alias"], "Student1"
    assert_equal player["enabled"], true

    Playlyfe.get('/definitions/processes', player_id: player_id)
    Playlyfe.get('/definitions/teams', player_id: player_id)
    Playlyfe.get('/processes', player_id: player_id)
    Playlyfe.get('/teams', player_id: player_id)

    processes = Playlyfe.get('/processes', player_id: 'student1', limit: 1, skip: 4)
    assert_equal processes["data"][0]["definition"], "module1"
    assert_equal processes["data"].size, 1

    new_process = Playlyfe.post('/definitions/processes/module1', { player_id: 'student1' })
    assert_equal new_process["definition"], "module1"
    assert_equal new_process["state"], "ACTIVE"
  end

  def test_init_production
    Playlyfe.init(
      client_id: "N2Y4NjNlYTItODQzZi00YTQ0LTkzZWEtYTBiNTA2ODg3MDU4",
      client_secret: "NDc3NTA0NmItMjBkZi00MjI2LWFhMjUtOTI0N2I1YTkxYjc2M2U3ZGI0MDAtNGQ1Mi0xMWU0LWJmZmUtMzkyZTdiOTYxYmMx",
      test: true
    )
    #player = Playlyfe.get('/players', player_id: 'l54328754bddc332e0021a847', limit: 1)
    #puts player
    #assert_equal player["data"][0]["email"], "peter@playlyfe.com"
  end

  def test_store
    redis = Redis.new
    Playlyfe.init(
      client_id: "Zjc0MWU0N2MtODkzNS00ZWNmLWEwNmYtY2M1MGMxNGQ1YmQ4",
      client_secret: "YzllYTE5NDQtNDMwMC00YTdkLWFiM2MtNTg0Y2ZkOThjYTZkMGIyNWVlNDAtNGJiMC0xMWU0LWI2NGEtYjlmMmFkYTdjOTI3",
      store: lambda { |token| puts redis.set('token', JSON.generate(token)) },
      retrieve: lambda { return JSON.parse(redis.get('token')) }
    )
    players = Playlyfe.get('/players', player_id: 'student1', limit: 1)
    assert_not_nil players["data"]
    assert_not_nil players["data"][0]
  end

  # def test_auth_code
  #   # Playlyfe.init(
  #   #   client_id: "Zjc0MWU0N2MtODkzNS00ZWNmLWEwNmYtY2M1MGMxNGQ1YmQ4",
  #   #   client_secret: "YzllYTE5NDQtNDMwMC00YTdkLWFiM2MtNTg0Y2ZkOThjYTZkMGIyNWVlNDAtNGJiMC0xMWU0LWI2NGEtYjlmMmFkYTdjOTI3",
  #   #   type: 'code'
  #   #   #redirect_uri: 'https://playlyfe.com/v1/api'
  #   # )
  # end
end
