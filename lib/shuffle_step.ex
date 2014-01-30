defrecord Card, suit: nil, rank: nil, points: nil do

  def describe(record) do
    "#{record.rank} of #{record.suit} (#{record.points})"
  end

end


defmodule Deck do

  def create do
    lc rank inlist ['Ace',2,3,4,5,6,7,8,9,10,'Jack','Queen','King'], 
       suit inlist ['Hearts','Clubs','Diamonds','Spades'], 
    do: Card.new rank: rank, suit: suit, points: init_points(rank)
  end

  def init_points(points) when is_number(points), do: points
  def init_points(points) when points == 'Ace', do: 1
  def init_points(_), do: 10 

  def is_a_match(card1, card2) do
    results = (card1.suit == card2.suit) or (card1.rank == card2.rank)
    if results, do: 1, else: 0
  end

end


defmodule ShuffleStep do
  use Application.Behaviour

  # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
  # for more information on OTP Applications
  def start(_type, _args) do
    ShuffleStep.Supervisor.start_link
  end

  def run(shuffle_occurences) do
    test_frequency = 1000
    total_matches = shuffle_test(shuffle_occurences, test_frequency, 0)
    total_matches / test_frequency
  end

  def runproc do
    receive do
      { sender, shuffles_happen } ->
          send sender, { :ok, run(shuffles_happen) }
    end
  end


## Shuffle_Test---------------------------
  def shuffle_test(_, 0, acc) do
    acc
  end

  def shuffle_test(shuffle_total, frequency, acc) do
    deck = Deck.create()
    shuffled_deck = multi_shuffle(deck, shuffle_total)
    [ first_card | rest ] = shuffled_deck
    total_matches = count_matches(first_card, rest, 0)
    shuffle_test(shuffle_total, frequency-1, acc + total_matches)    
  end


## Shuffle Multiple Times---------------
  def multi_shuffle(deck, 0) do
    deck
  end

  def multi_shuffle(deck, acc) do
    multi_shuffle( Enum.shuffle(deck), acc-1 ) 
  end


## Count Matches in a Deck--------------
  def count_matches(card1, [ card2 | [] ], acc) do
    acc + Deck.is_a_match(card1, card2)
  end

  def count_matches(card1, [ card2 | tail ], acc) do
    count_matches(card2, tail, acc + Deck.is_a_match(card1, card2))
  end
end



defmodule ShuffleStepProc do

  defp schedule_processes(pid, num_shuffles) do
    send pid, {self, num_shuffles}

IO.puts "Now running PID" 
IO.inspect pid

    receive do
      {:ok, sum_shuffle} ->
        IO.puts sum_shuffle
        sum_shuffle
    end

  end


  def schedule( num_processes // 100, num_shuffles // 1 ) do
    
    final_total =
      (1..num_processes)
      |> Enum.map(fn(_)-> spawn(ShuffleStep, :runproc, []) end)
      |> Enum.map(fn(x) -> schedule_processes(x,num_shuffles) end)
      |> Enum.reduce(0, fn(x, acc) -> x + acc end)    
      
    IO.puts "-----------------"
    IO.puts final_total
    IO.puts "-----------------"

  end

end
