include("InOutStream.jl")
include("NaturalVertexColoring.jl")
include("PalubeckisFormulation.jl")
include("Algorithms.jl")

#filename = "./Instances/DIMACS/0005_test.dim"
#filename = "./Instances/DIMACS/0011_myciel3.dim"
filename = "./Instances/DIMACS/0030_1-FullIns_3.dim"
dimacsGraph = Read_DIMACS_Instance(filename)
codimacsGraph = complement(dimacsGraph)

dsatur_coloration = DSatur(dimacsGraph)
dsatur_bound = length(dsatur_coloration)

#println(dimacsGraph)
#palubeckisSets = makePalubeckisSets(codimacsGraph)

#NaturalColoringMILP(dimacsGraph, dsatur_bound)
#NaturalColoringLP(dimacsGraph, dsatur_bound)

#solStruct = PalubeckisPLNE(codimacsGraph, palubeckisSets)
#solStruct = PalubeckisPL(codimacsGraph, palubeckisSets)


#colorEdgesofCograph(solStruct, codimacsGraph, "./solutionTest.png")
#saveGraph(dimacsGraph, "./test.png")