using JuMP, Gurobi, MathOptInterface
include("utils.jl")


# We will require to have both graph (undirected and directed)
function enumExPoints(cograph::SimpleGraph, diCograph::SimpleDiGraph)
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

    # outdegree
    # indegree

end