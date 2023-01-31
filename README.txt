---- Init:
	
	c(simulator).
	c(simulator_util).
	c(main).


---- Running using custom graph file:

	main:test_with_file("PATH/TO/FILE").


---- Running using simulator directly ('Graph' needs to be undirected graph):

	simulator:start(Graph, main, main).