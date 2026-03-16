using Graphs
using Combinatorics
using JuMP, Gurobi, MathOptInterface
using Polyhedra
import CDDLib

function is_clique(graph::SimpleGraph, vertices)
    for (i, v1) in enumerate(vertices)
        for v2 in vertices[i+1:end]
            if !has_edge(graph, v1, v2)
                return false
            end
        end
    end
    return true
end

function enum_noncliques(graph::SimpleGraph)
    all_vertices = vertices(graph)
    # of form [(vertices1, edges1), ...]
    res = []

    for k in 3:nv(graph)
        # combinations comes from Combinatorics basically C(n,k)
        for subset in combinations(all_vertices, k)
            # keep smaller vertex -> bigger one
            edges_subset = [(min(v1,v2), max(v1,v2)) for (i, v1) in enumerate(subset) for v2 in subset[i+1:end] if has_edge(graph, v1, v2)]
            # if it is not a clique and of size at least 2 (otherwise it's not really needed)
            if !is_clique(graph, subset) && length(edges_subset) >= 2
                push!(res, (subset, edges_subset))
            end
        end
    end
    return res
end

function gurobi_allowEnum(model)
    set_optimizer_attribute(model, "Presolve", 0)
    set_optimizer_attribute(model, "Cuts", 0)
    set_optimizer_attribute(model, "Heuristics", 0)
    set_optimizer_attribute(model, "Symmetry", 0)
end

function gurobi_setEnum(model, maxSolutions)
    set_optimizer_attribute(model, "PoolSearchMode", 2)
    set_optimizer_attribute(model, "PoolSolutions", maxSolutions)
end

""" function to give an orientation graph from a undirected graph with orientation i -> if i < j
"""

function direct_graph(graph::SimpleGraph)
    directed_graph = SimpleDiGraph(nv(graph))

    for e in edges(graph)
        # graphs.jl will always have orientation from smaller to bigger
        add_edge!(directed_graph, src(e), dst(e))
    end

    return directed_graph
end

function get_solutions(nbSols, xvec)
    return [round.(Int, value.(xvec; result = i)) for i in 1:nbSols];
end

function solution_to_polyhedron(solution)
    v = vrep(solution.sols)
    return polyhedron(v, CDDLib.Library())
end

function getHrep(solution)
    pol = solution_to_polyhedron(solution)
    return hrep(pol)
end

