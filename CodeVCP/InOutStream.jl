import Cairo
import Fontconfig
using Graphs
using Random
using GraphPlot
using Compose
using Colors

Random.seed!(42)

struct Graphdata
	#nb_sommets    # size of instance (points)
    #nb_aretes    # number of edges
	G            # Graph (SimpleGraph())
end

global const eps = 0.001

function Read_DIMACS_Instance(filename)
    # we don't know the initial size but we'll get it from the DIMACS file
    g = nothing

    open(filename) do f

        # enumerates lines (line number, content)
        for (i, line) in enumerate(eachline(f))

            # separation of the elements with space separator
            x = split(line, " ")

            """fetch the number of vertexes and edges and initialize 
            the simple graph (no multiple edge and self loops). the line containing p as first letter
            """
            if (x[1] == "p")
                nbvert = parse(Int, x[3])
                g = SimpleGraph(nbvert)
            # for the rest of the file we have all edges (letter e)
            elseif (x[1] == "e")
            # fetch the vertexes and add the edge to the graph
                v1 = parse(Int,x[2])
                v2 = parse(Int,x[3])
                # if edge v2-v1 exists, it's not gonna be added due to it being a simplegraph
                add_edge!(g, v1, v2)
            end
        end
    end

    # maybe a cleaner way to do it, === is specific for singleton type things
    if (g === nothing)
        throw(ArgumentError("Make sure your file is a DIMACS instance and check its content because no graph was constructed"))
    end

    return g
end

# Takes a DIMACS file instance .dim ("0005_test.dim" for example if it exists) 
function Read_DIMACS_Instance_Using_AdjMatrix(filename)

    # we don't know the initial size but we'll get it from the DIMACS file
    incidenceMat = nothing

    open(filename) do f

        # enumerates lines (line number, content)
        for (i, line) in enumerate(eachline(f))

            # separation of the elements with space separator
            x = split(line, " ")

            """We skip until we find p
            """
            if (length(x) == 0 || x[1] != "p")
                continue
            end

            """fetch the number of vertexes and edges and initialize 
            incidence matrix to make the graph. the line containing p as first letter
            """
            if (x[1] == "p")
                nbvert = parse(Int, x[3])
                incidenceMat = zeros(Int8, (nbvert, nbvert))
            # for the rest of the file we have all edges (letter e)
            else 
            # fetch the vertexes and add the edge in the incidence matrix
                v1 = parse(Int,x[2])
                v2 = parse(Int,x[3])
                # incidenceMat must be symmetric
                incidenceMat[v1, v2] = 1
                incidenceMat[v2, v1] = 1
            end
        end
    end

    # maybe a cleaner way to do it, === is specific for singleton type things
    if (incidenceMat === nothing)
        throw(ArgumentError("Make sure your file is a DIMACS instance and check its content because no graph was constructed"))
    end

    return SimpleGraph(incidenceMat)

end

"""
Write the hrep into a file
"""
function writeHrep(graphName::String, hspace, mapVar_to_edge)
    filename = graphName*".txt"
    open(filename, "w") do io
        println(io, "Graph is ",graphName)
        for h in Polyhedra.halfspaces(hspace)
            acoefs = h.a
            beta = h.β
            ineqString = String[]

            for (i,coef) in enumerate(acoefs)
                if coef != 0
                    tmp = mapVar_to_edge[i]
                    varString = "_"*string(tmp[1])*"_"*string(tmp[2])
                    push!(ineqString, string(coef, "x", varString))
                end
            end

            ineqString = join(ineqString, " + ") * " <= " * string(beta)
            
            println(io, "inequality : ",ineqString)
        end

        for h in Polyhedra.hyperplanes(hspace)
            acoefs = h.a
            beta = h.β
            ineqString = String[]
            for (i,coef) in enumerate(acoefs)
                if coef != 0
                    push!(ineqString, string(coef, " x", mapVar_to_edge[i]))
                end
            end
            ineqString = join(ineqString, " + ") * " = " * string(beta)
            println(io, "equality : ",ineqString)
        end
    end
end

"""
Write the hrep into a file with sorted inequalities
"""
function writeHrepSorted(graphName::String, hspace, mapVar_to_edge)
    filename = graphName*".txt"
    open(filename, "w") do io
        println(io, "Graph is ",graphName)
        halfspaces = collect(Polyhedra.halfspaces(hspace))
        vecs = [vcat(hs.a, hs.β) for hs in halfspaces]
        sorted_vecs = sort(vecs, by = v -> count(>(0), v[1:end-1]))

        for h in sorted_vecs
            supOrlow = nothing
            if (sum(h[1:end-1]) < 0)
                supOrlow = " >= "
                h[1:end-1] = -h[1:end-1]
            else
                supOrlow = " <= "
            end
            ineqString = String[]

            for (i,coef) in enumerate(h[1:end-1])
                if coef != 0
                    tmp = mapVar_to_edge[i]
                    varString = "_"*string(tmp[1])*"_"*string(tmp[2])
                    push!(ineqString, string(coef, "x", varString))
                end
            end

            ineqString = join(ineqString, " + ") * supOrlow * string(h[end])
            
            println(io, "inequality : ",ineqString)
        end


        halfspaces = collect(Polyhedra.hyperplanes(hspace))
        vecs = [vcat(hs.a, hs.β) for hs in halfspaces]
        sorted_vecs = sort(vecs, by = v -> count(>(0), v[1:end-1]))

        for h in sorted_vecs
            ineqString = String[]

            for (i,coef) in enumerate(h[1:end-1])
                if coef != 0
                    tmp = mapVar_to_edge[i]
                    varString = "_"*string(tmp[1])*"_"*string(tmp[2])
                    push!(ineqString, string(coef, "x", varString))
                end
            end

            ineqString = join(ineqString, " + ") * "=" * string(h[end])
            
            println(io, "equality : ",ineqString)
        end
    end
end


function saveGraph(graph, outFilename)
    coloration = fill(RGBA(1,0,0,1), nv(graph))
    nodelabel = [i for i in 1:nv(graph)]
    println(nodelabel)
    println(coloration)
    draw(PNG(outFilename, 16cm, 16cm), gplot(graph, nodelabel = nodelabel, nodefillc = coloration, layout=spring_layout))
end

function colorGraph(stablesSets, graph, outFilename)
    stableColors = distinguishable_colors(length(stablesSets))
    coloration = fill("white", nv(graph))
    for (i, s) in enumerate(stablesSets)
        for v in s
            coloration[v] = stableColors[i]
        end
    end
    draw(PNG(outFilename, 16cm, 16cm), gplot(graph, nodefillc = coloration, layout=spectral_layout))
end

# color the edges of a cograph depending on the solution taken 
function colorEdgesofCograph(solution, cograph, outFilename)
    _, xvec, edgeVarMap = solution
    # base coloration, everything is white with no transparency
    edgeColoration = fill(RGBA(1,1,1,1), ne(cograph))
    # everything is at max width, since there is no way to make dashed lines.
    edgeWidth = fill(1.0, ne(cograph))

    for e in edges(cograph)
        # we take the edges
        i, j = src(e), dst(e)
        # we take the index in the solution vector
        indMap = edgeVarMap[(min(i,j), max(i,j))]
        # i do not know if values = 1 are actually 1 in julia
        if (xvec[indMap] >= 1 - eps)
            edgeColoration[indMap] = colorant"blue"
        # if value = 0
        elseif (xvec[indMap] <= eps)
            edgeColoration[indMap] = RGBA(0, 0, 1, 0.3)
        # else the values are decimal
        else
            edgeColoration[indMap] = colorant"blue"
            edgeWidth[indMap] = 0.1
        end
    end

    draw(PNG(outFilename, 16cm, 16cm), gplot(cograph, edgestrokec = edgeColoration, edgelinewidth = edgeWidth, layout=spectral_layout))
end