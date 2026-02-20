using JuMP
using CPLEX
using MathOptInterface

# Formulation of Palubeckis in the article of 2008 : On the recursive largest first algorithm for graph colouring.

struct TandPI
	PI # PI set in Palubeckis formulation
    T # T set in Palubeckis formulation
end

struct solution
    obj # objective value, should be a real value
    sol # the values of xij, a vector [x1, x2, ..., xn]
    edgeToVarMap # mapping from edges to var (for easier access to needed edge), it has a mapping, (vertex1, vertex2) : index in sol
end

"""
Function that enumerates all triangles (K3) of a graph
and adds them twice in order (u,v,w) and (u,w,v) with u being a smaller index graph
in the paper it represents the T set
"""
function enumerate_Triangles(graph)

    T = Tuple{Int, Int, Int}[]

    for i in vertices(graph)
        for j in neighbors(graph, i)
            # we check if v is smaller than u since we want an ordering for adding the triangles
            if (i < j)
                # we use the common neighbors of u and v to enumerates triangles
                for k in common_neighbors(graph, i, j)
                    # if i < j and i < k then i < min(j,k), faster to check this way.
                    if (i < k)
                        # (i,k,j) will be added when we reach k = j in the loop
                        push!(T, (i,j,k))
                    end
                end
            end
        end
    end

    if (size(T) == 0)
        println("Empty set T, either the graph has no K3 or there is an issue with it")
    end

    return T
end


"""
Function that makes both T and PI sets of the Palubeckis formulation from a given graph
"""
function makePalubeckisSets(graph)

    PI = Tuple{Int, Int, Int}[]
    T = Tuple{Int, Int, Int}[]

    for i in vertices(graph)
        for j in neighbors(graph, i)
            for k in neighbors(graph, j)
                if (i != k)
                    # if it has edge ik then it is a clique we add it, it should add (i,j,k) and (i,k,j)
                    if (has_edge(graph, i, k))
                        # we add it if i < min{j,k}
                        if (i < min(j, k))
                            push!(T, (i,j,k))
                        end
                    """
                    triplet without triangle, we want to avoid having duplicates and the only duplicate that is possible
                    should be the reverse of one triplet
                    """
                    elseif (i < k)
                        push!(PI, (i,j,k))
                    end
                end
            end
        end
    end

    return TandPI(PI, T)
end

"""
Formulation of Palubeckis (MILP) taking PI, T and the cograph
"""
function PalubeckisPLNE(cograph, PIandT)
    PIset = PIandT.PI
    Tset = PIandT.T
    nEdges = ne(cograph)
    edgesSet = collect(edges(cograph))
    edge_to_var = Dict{Tuple{Int,Int},Int}()

    solution = nothing

    # This allows a mapping from edge to variables
    for (ind, e) in enumerate(edgesSet)
        i,j = src(e), dst(e)
        # min and max to always have it ordered
        edge_to_var[(min(i,j), max(i,j))] = ind
    end

    # create an lp model with Cplex
    lpModel = Model(CPLEX.Optimizer)

    # variables used in the model (one per edge)
    @variable(lpModel, x[1:nEdges], Bin)

    # sum of taken edges 
    @objective(lpModel, Max, sum(x[i] for i = 1:nEdges))
    
    # Constraints
    # xij + xjk <= 1 for triples in PI
    for (i,j,k) in PIset
        xij = edge_to_var[(min(i,j), max(i,j))]
        xjk = edge_to_var[(min(k,j), max(k,j))]

        @constraint(lpModel, x[xij] + x[xjk] <= 1)
    end

    # same thing as PI but for T
    for (i,j,k) in Tset
        xij = edge_to_var[(min(i,j), max(i,j))]
        xjk = edge_to_var[(min(k,j), max(k,j))]

        @constraint(lpModel, x[xij] + x[xjk] <= 1)
    end

    println(lpModel)

    println("Résolution du PLNE par le solveur")
	optimize!(lpModel)
   	println("Fin de la résolution du PLNE par le solveur")

    if (termination_status(lpModel) == MathOptInterface.OPTIMAL)
        println(objective_value(lpModel))
        println("variables values ", value.(x))
        solution = (objective_value(lpModel), value.(x), edge_to_var)
    end

    return solution
end

"""
Formulation of Palubeckis (LP) taking PI, T and the cograph
"""
function PalubeckisPL(cograph, PIandT)
    PIset = PIandT.PI
    Tset = PIandT.T
    nEdges = ne(cograph)
    edgesSet = collect(edges(cograph))
    edge_to_var = Dict{Tuple{Int,Int},Int}()

    solution = nothing

    # This allows a mapping from edge to variables
    for (ind, e) in enumerate(edgesSet)
        i,j = src(e), dst(e)
        # min and max to always have it ordered
        edge_to_var[(min(i,j), max(i,j))] = ind
    end

    # create an lp model with Cplex
    lpModel = Model(CPLEX.Optimizer)

    # variables used in the model (one per edge)
    @variable(lpModel, x[1:nEdges] >= 0)

    # sum of taken edges 
    @objective(lpModel, Max, sum(x[i] for i = 1:nEdges))
    
    # Constraints
    # xij + xjk <= 1 for triples in PI
    for (i,j,k) in PIset
        xij = edge_to_var[(min(i,j), max(i,j))]
        xjk = edge_to_var[(min(k,j), max(k,j))]

        @constraint(lpModel, x[xij] + x[xjk] <= 1)
    end

    # same thing as PI but for T
    for (i,j,k) in Tset
        xij = edge_to_var[(min(i,j), max(i,j))]
        xjk = edge_to_var[(min(k,j), max(k,j))]

        @constraint(lpModel, x[xij] + x[xjk] <= 1)
    end

    println(lpModel)

    println("Résolution du PL par le solveur")
	optimize!(lpModel)
   	println("Fin de la résolution du PL par le solveur")

    if (termination_status(lpModel) == MathOptInterface.OPTIMAL)
        println(objective_value(lpModel))
        println("variables values ", value.(x))
        solution = (objective_value(lpModel), value.(x), edge_to_var)
    end

    return solution
end