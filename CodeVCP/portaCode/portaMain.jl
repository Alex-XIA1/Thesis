include("pointsGenerator.jl")

csize = 11
#dimacsGraph = cycle_graph(csize)
#dimacsGraph = SimpleGraph(4)
dimacsGraph = Read_DIMACS_Instance("./portaInstances/cliqueForestInstance.col")
#codimacsGraph = complement(dimacsGraph)
codimacsGraph = dimacsGraph
directedCoGraph = direct_graph(codimacsGraph)

solution = enumExPoints(codimacsGraph, directedCoGraph)
h = getHrep(solution)

println("list of variables ", solution.edgeToVarMap)

showInequalities(h ,Dict(v => k for (k, v) in solution.edgeToVarMap))
#writeHrep("Cocycle"*string(csize), h, Dict(v => k for (k, v) in solution.edgeToVarMap))
println("solution ", solution.sols)

