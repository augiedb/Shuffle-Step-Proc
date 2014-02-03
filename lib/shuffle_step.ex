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


#------------------------------------------------------------------------

defmodule ShuffleStep do
  use Application.Behaviour

  # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
  # for more information on OTP Applications
  def start(_type, _args) do
    ShuffleStep.Supervisor.start_link
  end


  @doc """

    Given a number of times to shuffle the deck, runs 1000 tests with that many.

    Takes one parameter:
      - Number of times to shuffle the deck
  
  """

  def run(shuffle_occurences) do
    test_frequency = 1000
    total_matches = shuffle_test(shuffle_occurences, test_frequency, 0)
    total_matches / test_frequency
  end


  @doc """
    This is the function that will run as multiple processes
  """

  def create_processes do
    receive do
      { sender, shuffles_happen } ->

        :random.seed(:erlang.now)
 
        value = run(shuffles_happen)
        IO.puts "VALUE INSIDE create_processes: #{value}"
        send sender, { :ok, value }
    end
  end


## Shuffle_Test---------------------------

  @doc """

  Runs the actual test we created this whole app for.  Shuffle the deck,
  count how many matches it has.

  Takes three parameters: 
    - how many times to shuffle the deck 
    - how many times to run this test
    - an accumulator
  """

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
  @doc """
    
    Shuffles a deck of cards

    Takes two parameters:
      - a Deck of cards
      - an accumulator which keeps track of how many times the deck should be shuffled
  """

  def multi_shuffle(deck, 0) do
    deck
  end

  def multi_shuffle(deck, acc) do
    multi_shuffle( Enum.shuffle(deck), acc-1 ) 
  end


## Count Matches in a Deck--------------

  @doc """
    Counts how many matches show up in a deck of cards.  Continuously compares the top card in the deck to the next one, looking for a match.

    Takes three parameters:
      - The first card
      - The rest of the deck
      - An accumulator total the matches

  """

  def count_matches(card1, [ card2 | [] ], acc) do
    acc + Deck.is_a_match(card1, card2)
  end

  def count_matches(card1, [ card2 | tail ], acc) do
    count_matches(card2, tail, acc + Deck.is_a_match(card1, card2))
  end
end



defmodule ShuffleStepProc do

  @doc"""
  This function runs existing processes, passing along specific values.

  Takes two parameters:
    - The PID of the process to be called
    - Number of shuffles to make
  """

  defp run_processes(pid, num_shuffles) do
   
    send pid, {self, num_shuffles}

    receive do
      {:ok, sum_shuffle} ->
        IO.puts sum_shuffle
        sum_shuffle
    end

  end



  @deck """
  The main driver of the test.  It will create the processes, run them, and then report back the answer.

  Takes two parameters:
    - Number of processes to run this test with (defaults to 100)
    - Number of times to shuffle the deck (defaults to 1)
  """

  def schedule( num_processes // 100, num_shuffles // 1 ) do

    final_total =
      (1..num_processes)
      |> Enum.map(fn(_)-> spawn(ShuffleStep, :create_processes, []) end)      # Create x processes, ready to run
      |> Enum.map(fn(x) -> run_processes(x,num_shuffles) end)   # Run them with arguments passed
      |> Enum.reduce(0, fn(x, acc) -> x + acc end)                   # Add up the return values 
      
    IO.puts "-----------------"
    IO.puts (final_total / num_processes)
    IO.puts "-----------------"

  end


  @doc """

  Alternate entry point for when you want to time out how long this takes.
  Takes the same parameter list as the schedule function above and then passes that one.
  This is an OK kind of redundancy, as this is an alternate path to the core functionality.

  Takes two parameters:
    - Number of processes to run this test with (defaults to 100)
    - Number of times to shuffle the deck (defaults to 1)
  """
  
  def time_it( num_processes // 100, num_shuffles // 1 ) do
    :timer.tc( ShuffleStepProc, :schedule, [num_processes, num_shuffles] )
  end

end
