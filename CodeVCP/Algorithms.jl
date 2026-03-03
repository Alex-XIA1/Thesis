using Graphs

"""NOTE : This code uses the GeeksForGeeks algorithm (which is very likely the one in GraphsColoring.jl)
"""


struct DSATURNode
    sat::Int # number of colors assigned to neighboring elements
    deg::Int # number of neighbors that are uncolored (uses the GeeksForGeeks ver instead of vertex degree)
    elementid::Int
end

# equivalent to the comparator struct in c++, decide if we take a or b
function maxSat(a::DSATURNode, b::DSATURNode)
    if a.sat != b.sat
        return a.sat > b.sat
    elseif a.deg != b.deg
        return a.deg > b.deg
    # i do not know if the ordering matters, GeeksForGeeks order by descending order but we will do it by ascending order
    else
        return a.elementid < b.elementid
    end
end

# the algorithm can be found on GeeksForGeeks, this will be used for heuristics + the max number of colors in natural formulations
function DSatur(g::SimpleGraph)
    n = nv(g)
    # colors assigned, mapping vertex -> color
    c = fill(-1, n)
    # degrees, mapping vertex -> degree
    d = [degree(g, u) for u in 1:n]
    # neighbor colors, mapping vertex -> set of neighbor color
    adjCols = [Set{Int}() for _ in 1:n]
    # uncolored is used to iterate over all vertexes
    uncolored = collect(1:n)
    # tell if a color is used in the neighbor of one node. We set all used to true then revert it once we attributed a color.
    used = falses(n)

    # iterate over all vertexes
    while !isempty(uncolored)
        # Find vertex with max saturation
        max_node = DSATURNode(-1, -1, -1)
        max_index = -1
        for (i, u) in enumerate(uncolored)
            # (sat, degree of uncolored, id)
            node = DSATURNode(length(adjCols[u]), d[u], u)
            # we check depending on the function maxSat
            if maxSat(node, max_node)
                max_node = node
                max_index = i
            end
        end

        u = uncolored[max_index]
        # we pop the item at max_index since we are going to give it a color
        splice!(uncolored, max_index)

        # find the smallest available color for u 
        for v in neighbors(g, u)
            if c[v] != -1
                used[c[v]] = true
            end
        end
        # find the first false in used, it tells that no vertex nearby has the color
        color = findfirst(!, used)
        # give color to vertex u
        c[u] = color
        # Reset used array
        for v in neighbors(g, u)
            if c[v] != -1
                used[c[v]] = false
            end
        end

        # Update neighbors saturation
        for v in neighbors(g, u)
            if c[v] == -1
                # v has a new used color nearby unless it already exists
                push!(adjCols[v], color)
                # we decrease the degree of uncolored neighbors
                d[v] -= 1
            end
        end
    end
    color_map = Dict(col => Set(findall(x -> x == col, c)) for col in unique(c))

    return color_map
end