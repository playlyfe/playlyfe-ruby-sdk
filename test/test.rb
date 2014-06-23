require 'test/unit'
require 'playlyfe'

class PlaylyfeTest < Test::Unit::TestCase

  def test_start
    Playlyfe.init(
      client_id: "NjZlZWFiMWEtN2ZiOC00YmVmLTk2YWMtNDEyYTNmMjQ5NDBl",
      client_secret: "NGRhMWJlYzUtODJiNS00ZTdkLTgzNTctMTQyMGEzNTljN2MwMTU2MGM3NTAtZjZiZS0xMWUzLTgxZjYtNmZhMGYyMzRkZGU3"
    )
    puts Playlyfe.token.to_hash

    players = Playlyfe.get(url: '/players')
    assert_not_nil players["data"]
    assert_not_nil players["data"][0]

    player_id = 'student1'
    player = Playlyfe.get(url: '/player', player: player_id)
    assert_equal player["id"], "student1"
    assert_equal player["alias"], "Student1"
    assert_equal player["enabled"], true

    no_player = Playlyfe.get(url: '/player')
    assert_nil no_player

    Playlyfe.get(url: "/definitions/processes", player: player_id)
    Playlyfe.get(url: "/definitions/teams", player: player_id)
    Playlyfe.get(url: "/processes", player: player_id)
    Playlyfe.get(url: "/teams", player: player_id)
  end
end
