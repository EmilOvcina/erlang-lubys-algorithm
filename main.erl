%%----------------------------------------------------------------------------
%% @doc The module runs Luby's algorithm for Maximal Independent Set on a Graph. This is used in together
%%        with simulator and simulator_util modules.
%% @see simulator
%% @see simulator_util
%% @author emovc18@student.sdu.dk
%% @end
%%----------------------------------------------------------------------------
-module(main).
-export([main/3, test_with_file/1]).
-import(rand, [uniform/0]).

-define(TIMEOUT, 2000).

%%----------------------------------------------------------------------------
%% @doc Reads a file containing an adjancency map representing an
%%            undirected graph and feeds it to the simulator and runs Luby's
%%            algorithm.
%% @param X path to a file containing an adjancency map representing an
%%            undirected graph.
%% @end
%%----------------------------------------------------------------------------
-spec test_with_file(file:name_all()) -> none().
test_with_file(X) ->
  Graph = simulator_util:read_from_file(X),
  simulator:start(Graph, main, main).

%%----------------------------------------------------------------------------
%% @doc Main function running Luby's algorithm. This prints the id if the node 
%%		  is selected for the MIS. Should be used with the simulator module. 
%%        The simulator:start function should be provided an UNDIRECTED 
%%        Graph since this algorithm assumes that all graphs are undirected.
%% @param Vertex id of vertex in a graph.
%% @param Neighbours is list of ids of vertices, which corresponds 
%%        to the neighbours of the vertex.
%% @param Nodes is a list of tuples mapping vertex ids to pids.
%% @end
%%----------------------------------------------------------------------------
-spec main(X, [X],[{X,pid()}]) -> none() | ok.
main(Vertex, Neighbours, Nodes) ->
  Result = loop(Vertex, Neighbours, Nodes),
  if
    Result ->
      io:fwrite("Node ~p Selected.~n", [Vertex]);
    true ->
      ok
  end.

%%----------------------------------------------------------------------------
%% @doc Luby's algorithm written using the pseudo-code from chapter 5.7 in the
%%        book Distributed Computing: Principles, Algorithms, and Systems by
%%        Ajay D. Kshemkalyani and Mukesh Singhal
%% @param Vertex id of vertex in a graph.
%% @param Neighbours is list of ids of vertices, which corresponds 
%%        to the neighbours of the vertex.
%% @param Nodes is a list of tuples mapping vertex ids to pids.
%% @returns true if node is selected for maximal independent set.
%% @end
%%----------------------------------------------------------------------------
-spec loop(X, [X],[{X,pid()}]) -> boolean().
loop(_, Neighbours, _) when Neighbours == [] ->
  true;
loop(Vertex, Neighbours, Nodes) ->
  RandomNum = rand:uniform(),
  send_to_neighbours(Neighbours, Nodes, random_number, RandomNum),
  Randoms = wait_for_neighbours(Neighbours, [], random_number),
  MinR = lists:min(Randoms),
  if 
    RandomNum < MinR ->  % smallest random value
      send_to_neighbours(Neighbours, Nodes, selected, {self(), true}),
      true;
    true ->                     % else
      send_to_neighbours(Neighbours, Nodes, selected, {self(), false}),
      Selects = wait_for_neighbours(Neighbours, [], selected),
      GotSelected = lists:search(fun(N) -> {_, B} = N, B == true end, Selects),
      if 
        GotSelected =/= false ->  % a neighbour has been selected
          NotSelectedNeighbours = lists:map(fun(N) -> {Pid, _} = N, Pid end, lists:filter(fun(N) -> {_, B} = N, B == false end, Selects)),
          send_to_pids(NotSelectedNeighbours, eliminated, {self(), true}),
          false;
        true ->                   % no neighbours have been selected
          send_to_neighbours(Neighbours, Nodes, eliminated, {self(), false}),
          Eliminated = wait_for_neighbours(Neighbours, [], eliminated),
          NewNeighbourPids = lists:map(fun(N) -> {Pid, _} = N, Pid end, lists:filter(fun(N) -> {_, B} = N, B == false end, Eliminated)),
          % Convert list of pids to vertex ids.
          NewNeighbourList = lists:map(fun(N) -> 
            {V, _} = N, V
          end, lists:filter(fun(N) -> 
            {_, Pid} = N, lists:any(fun(N2) -> N2 == Pid end, NewNeighbourPids)
          end, Nodes)),
          loop(Vertex, NewNeighbourList, Nodes)
      end
  end.

%%----------------------------------------------------------------------------
%% @doc Generic function to send a message with payload to a list of pids.
%% @param Pids is a list of pids 
%% @param Request is an atom which corresponds with the message type.
%% @param Payload is whatever should be sent in the message.
%% @end
%%----------------------------------------------------------------------------
-spec send_to_pids([pid()], atom(), any()) -> ok.
send_to_pids(Pids, Request, Payload) ->
  lists:foreach(fun(Pid) ->
    Pid ! {Request, Payload}
  end, Pids),
  ok.

%%----------------------------------------------------------------------------
%% @doc Send a message with payload to all neighbours of a vertex. Uses Nodes
%%        to get the pids which to send the messages to.
%% @param Neighbours is list of ids of vertices, which corresponds 
%%        to the neighbours of the vertex.
%% @param Nodes is a list of tuples mapping vertex ids to pids.
%% @param Request is an atom which corresponds with the message type.
%% @param Payload is whatever should be sent in the message.
%% @end
%%----------------------------------------------------------------------------
-spec send_to_neighbours([X],[{X,pid()}], atom(), any()) -> ok.
send_to_neighbours(Neighbours, Nodes, Request, Payload) ->
  lists:foreach(fun(N) ->
    {_, Pid} = lists:keyfind( N, 1, Nodes ),
    Pid ! {Request, Payload}
  end, Neighbours),
  ok.

%%----------------------------------------------------------------------------
%% @doc Wait for messages from all neighbours, and putting all messages into 
%%        List and returning the list.
%% @param Vertex id of vertex in a graph.
%% @param Neighbours is list of ids of vertices, which corresponds 
%%        to the neighbours of the vertex.
%% @param Nodes is a list of tuples mapping vertex ids to pids.
%% @param Request is an atom which corresponds with the message type.
%% @param Payload is whatever should be sent in the message.
%% @returns List of messages from all neighbours that sent a message.
%% @end
%%----------------------------------------------------------------------------
-spec wait_for_neighbours([any()], [any()], atom()) -> [any()].
wait_for_neighbours(Neighbours, List, _) when length(List) == length(Neighbours) ->
  List;
wait_for_neighbours(Neighbours, List, Request) ->
  receive
    {Request, PL} ->
      Tmp = lists:append([List, [PL]]),
      wait_for_neighbours(Neighbours, Tmp, Request)
  after ?TIMEOUT -> List %In case of a node dying, it cannot be selected, so return List as is.
  end.