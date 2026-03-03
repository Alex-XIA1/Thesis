using JuMP
using CPLEX


# Const for solution status
# const OPTIMAL = MathOptInterface.OPTIMAL
# const INFEASIBLE = MathOptInterface.INFEASIBLE
# const UNBOUNDED = MathOptInterface.DUAL_INFEASIBLE;

"""
Takes a graph made from Graphs.jl in entry give a coloring according to the natural formulation
"""
function NaturalColoringMILP(graph, maxColors)

    # we are taking nbVertex = nbColors, TODO use Dsatur to get a better value for K
    nbVertex = nv(graph)
    nbColors = maxColors
    # create an lp model with Cplex
    lpModel = Model(CPLEX.Optimizer)

    # variables used for coloring (variables of form x_vk, with v vertex and k color)
    @variable(lpModel, x[1:nbVertex, 1:nbVertex], Bin)
    # variables w_k for each color
    @variable(lpModel, w[1:nbColors], Bin)

    # sum of w_k
    @objective(lpModel, Min, sum(w[i] for i = 1:nbColors))

    # Constraints 
    # constraints sum_k x_vk = 1 (max 1 color per vertex)
    for v in 1:nbVertex
        @constraint(lpModel, sum(x[v, k] for k in 1:nbColors) == 1)
    end

    # constraints x_uk + x_vk <= 1
    for v in edges(graph)
        for k in 1:nbColors
            @constraint(lpModel, x[src(v), k] + x[dst(v), k] <= w[k])
        end
    end

	println(lpModel)
	
	println("Résolution du PLNE par le solveur")
	optimize!(lpModel)
   	println("Fin de la résolution du PLNE par le solveur")
end

"""
Takes a graph made from Graphs.jl in entry give a fractional coloring according to the natural formulation
If no issues, it should give 2 independently of the graph which is very weak
"""
function NaturalColoringLP(graph, maxColors)

    # we are taking nbVertex = nbColors
    nbVertex = nv(graph)
    nbColors = maxColors
    # create an lp model with Cplex
    lpModel = Model(CPLEX.Optimizer)

    # variables used for coloring (variables of form x_vk, with v vertex and k color)
    @variable(lpModel, x[1:nbVertex, 1:nbVertex] >= 0)
    # variables w_k for each color
    @variable(lpModel, w[1:nbColors] >= 0)

    # sum of w_k
    @objective(lpModel, Min, sum(w[i] for i = 1:nbColors))

    # Constraints 
    # constraints sum_k x_vk = 1 (max 1 color per vertex)
    for v in 1:nbVertex
        @constraint(lpModel, sum(x[v, k] for k in 1:nbColors) == 1)
    end

    # constraints x_uk + x_vk <= 1
    for v in edges(graph)
        for k in 1:nbColors
            @constraint(lpModel, x[src(v), k] + x[dst(v), k] <= w[k])
        end
    end

	println(lpModel)
	
	println("Résolution du PL par le solveur")
	optimize!(lpModel)
   	println("Fin de la résolution du PL par le solveur")
end