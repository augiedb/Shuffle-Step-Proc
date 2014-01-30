# ShuffleStep

This program is being written for an upcoming [ElixirDose.com](http://elixirdose.com) article.

This program is an update of the Shuffle_Step repo, in which we run 1000 shuffles to see if it mixes a deck of cards well.

This repo is going to do the same thing, but add multiple processes to it.

There's a mix dependence in here for Elixir 12.3-dev.  You might want to change that if you're not running the most up-to-date version of Elixir and Erlang.

## Update January 28, 2014  

Now working with a process!

Try this from inside the directory:

iex -S mix
ShuffleStepProc.schedule(3)

That will run a single process to run the three-shuffle test 1000 times.

TO DO: Add a time to see how long it takes.
Add a parameter to vary how many iterations per test
Watch how much faster it runs at large numbers of processes.  (Hopefully)

__Special thanks to Dave Thomas and his "Programming Elixir" book for teaching me this stuff, and from whom I'm probably copying too much code.  I'm learning.  It'll be more mine soon enough...__
