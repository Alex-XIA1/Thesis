include("InOutStream.jl")
include("NaturalVertexColoring.jl")
include("PalubeckisFormulation.jl")

#filename = "./Instances/DIMACS/0005_test.dim"
filename = "./Instances/DIMACS/0011_myciel3.dim"
dimacsGraph = Read_DIMACS_Instance(filename)
codimacsGraph = complement(dimacsGraph)
println(dimacsGraph)
palubeckisSets = makePalubeckisSets(codimacsGraph)

#NaturalColoringMILP(dimacsGraph)
#NaturalColoringLP(dimacsGraph)

#solStruct = PalubeckisPLNE(codimacsGraph, palubeckisSets)
solStruct = PalubeckisPL(codimacsGraph, palubeckisSets)


colorEdgesofCograph(solStruct, codimacsGraph, "./solutionTest.png")
#saveGraph(dimacsGraph, "./test.png")