include("pointsGenerator.jl")

dimacsGraph = cycle_graph(6)
codimacsGraph = complement(dimacsGraph)
directedCoGraph = direct_graph(codimacsGraph)

solution = enumExPoints(codimacsGraph, directedCoGraph)
h = getHrep(solution)

