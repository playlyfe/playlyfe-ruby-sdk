require 'test/unit'
require 'playlyfe'

class PlaylyfeTest < Test::Unit::TestCase

  def test_start
    Playlyfe.start(
      client_id: "MTQ5MDFiODAtYzYzNS00OTMyLTg4NDktYjliNzE0ZmZiZDBl",
      client_secret: "ZjI0YmNlNzgtNzU2ZC00NWU0LWIwZTItNjg1YjU4MTljNDRlODA4MDkyYzAtZTg3ZS0xMWUzLWE5ZTMtMzViZDM4NGNiMjQw"
    )
    puts Playlyfe.token

    players = Playlyfe.get(url: '/players')
    assert_not_nil players["data"]
    assert_not_nil players["data"][0]

    player = Playlyfe.get(url: '/player', player: 'goku')
    assert_equal player["id"], "goku"
    assert_equal player["alias"], "goku"
    assert_equal player["enabled"], true

    no_player = Playlyfe.get(url: '/player')
    assert_nil no_player

    Playlyfe.get(url: "/definitions/processes", player: 'goku')
    Playlyfe.get(url: "/definitions/teams", player: 'goku')
    Playlyfe.get(url: "/processes", player: 'goku')
    Playlyfe.get(url: "/teams", player: 'goku')
  end
end
