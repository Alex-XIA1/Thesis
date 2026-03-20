include("../utils.jl")
include("../InOutStream.jl")

struct allSolutions
    sols # all the feasible points found by gurobi
    edgeToVarMap # mapping from edges to var (for easier access to needed edge), it has a mapping, (vertex1, vertex2) : index in sol
end

# We will require to have both graph (undirected and directed)
function enumExPoints(cograph::SimpleGraph, diCograph::SimpleDiGraph)
    nEdges = ne(cograph)
    edgesSet = collect(edges(cograph))
    arcSet = collect(edges(diCograph))
    edge_to_var = Dict{Tuple{Int,Int},Int}()
    # each element is form (vertices, edges)
    uSubsets = enum_noncliques(cograph)

    # This allows a mapping from edge to variables
    for (ind, e) in enumerate(edgesSet)
        i,j = src(e), dst(e)
        # min and max to always have it ordered
        edge_to_var[(min(i,j), max(i,j))] = ind
    end

    # create an lp model with Gurobi
    lpModel = Model(Gurobi.Optimizer)

    # variables used in the model (one per edge)
    @variable(lpModel, x[1:nEdges], Bin)

    # sum of taken edges 
    @objective(lpModel, Max, sum(x[i] for i = 1:nEdges))

    # outdegree, nv is the same for diCograph and cograph
    for i in 1:nv(diCograph)
        outneighs = outneighbors(diCograph, i)
        # a small optimization for the length(outneighs) > 1 because trivial inequalities takes care of length <= 1
        if (length(outneighs) >= 2)
            @constraint(lpModel, sum(x[edge_to_var[min(i,j), max(i,j)]] for j in outneighs) <= 1)
        end
    end
    # indegree
    for i in 1:nv(diCograph)
        inneighs = inneighbors(diCograph, i)
        if (length(inneighs) >= 2)
            @constraint(lpModel, sum(x[edge_to_var[min(i,j), max(i,j)]] for j in inneighs) <= 1)
        end
    end

    # form (vertex, edges) for each pair
    allU = enum_noncliques(cograph)

    for U in allU
        # get the edgeset of U
        edgeSetU = U[2]
        println("U is ",U)
        # enum should have removed all edgeset of size 0 so no need to check
        @constraint(lpModel, sum(x[edge_to_var[e]] for e in edgeSetU) <= length(U[1]) - 2)
    end
    println(lpModel)

    # set the solver for enumeration
    gurobi_allowEnum(lpModel)
    pool_size = (nv(cograph) + nEdges)*10
    gurobi_setEnum(lpModel, pool_size)
    
    println("Début d'énumération des points")
	optimize!(lpModel)
   	println("Fin d'énumération des points")

    solutions = get_solutions(result_count(lpModel), x)

    return allSolutions(solutions, edge_to_var)
end