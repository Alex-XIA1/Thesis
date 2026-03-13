using Graphs
using Combinatorics

function is_clique(graph::SimpleGraph, vertices)
    for (i, v1) in enumerate(vertices)
        for v2 in vertices[i+1:end]
            if !has_edge(g, v1, v2)
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
            edges_subset = [(v1, v2) for (i, v1) in enumerate(subset) for v2 in subset[i+1:end] if has_edge(g, v1, v2)]
            if !is_clique(g, subset) && !isempty(edges_subset)
                push!(res, (subset, edges_subset))
            end
        end
    end
    return res
end
