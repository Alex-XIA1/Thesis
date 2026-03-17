include("pointsGenerator.jl")

dimacsGraph = cycle_graph(6)
codimacsGraph = complement(dimacsGraph)
directedCoGraph = direct_graph(codimacsGraph)

solution = enumExPoints(codimacsGraph, directedCoGraph)
h = getHrep(solution)

println("list of variables ", solution.edgeToVarMap)

#showInequalities(h ,Dict(v => k for (k, v) in solution.edgeToVarMap))
writeHrep("Cocycle6", h, Dict(v => k for (k, v) in solution.edgeToVarMap))



#println("solution ", solution.sols)

