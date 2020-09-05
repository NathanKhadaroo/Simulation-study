# Installing packages

using Pkg
Pkg.add("Agents")
Pkg.add("AgentsPlots")


#Defining agent type

using Agents, AgentsPlots
mutable struct SchellingAgent <: AbstractAgent
    id::Int # The identifier number of the agent
    pos::Tuple{Int,Int} # The x, y location of the agent on a 2D grid
    mood::Bool # whether the agent is happy in its node. (true = happy)
    group::Int # The group of the agent,  determines mood as it interacts with neighbors
end

#creating environment

space = GridSpace((10, 10), moore = true)

#creating basic agent based model

properties = Dict(:min_to_be_happy => 3)
schelling = ABM(SchellingAgent, space; properties = properties)

# initialising abm via a funtion

function initialize(; numagents = 320, griddims = (20, 20), min_to_be_happy = 3)
    space = GridSpace(griddims, moore = true)
    properties = Dict(:min_to_be_happy => min_to_be_happy)
    model = ABM(SchellingAgent, space;
                properties = properties, scheduler = random_activation)
    # populate the model with agents, adding equal amount of the two types of agents
    # at random positions in the model
    for n in 1:numagents
        agent = SchellingAgent(n, (1, 1), false, n < numagents / 2 ? 1 : 2)
        add_agent_single!(agent, model)
    end
    return model
end

#creating step function

function agent_step!(agent, model)
    agent.mood == true && return # do nothing if already happy
    minhappy = model.min_to_be_happy
    neighbor_cells = node_neighbors(agent, model)
    count_neighbors_same_group = 0
    # For each neighbor, get group and compare to current agent's group
    # and increment count_neighbors_same_group as appropriately.
    for neighbor_cell in neighbor_cells
        node_contents = get_node_contents(neighbor_cell, model)
        # Skip iteration if the node is empty.
        length(node_contents) == 0 && continue
        # Otherwise, get the first agent in the node...
        agent_id = node_contents[1]
        # ...and increment count_neighbors_same_group if the neighbor's group is
        # the same.
        neighbor_agent_group = model[agent_id].group
        if neighbor_agent_group == agent.group
            count_neighbors_same_group += 1
        end
    end
    # After counting the neighbors, decide whether or not to move the agent.
    # If count_neighbors_same_group is at least the min_to_be_happy, set the
    # mood to true. Otherwise, move the agent to a random node.
    if count_neighbors_same_group ≥ minhappy
        agent.mood = true
    else
        move_agent_single!(agent, model)
    end
    return
end

#Initialising teh model

model = initialize()

#Moving one step

step!(model, agent_step!)

#Moving n (3) steps

step!(model, agent_step!, 3)

# running and collecting data

adata = [:pos, :mood, :group]

model = initialize()
data, _ = run!(model, agent_step!, 5; adata = adata)
data[1:10, :] # print only a few rows

#visualising

groupcolor(a) = a.group == 1 ? :blue : :orange
groupmarker(a) = a.group == 1 ? :circle : :square
plotabm(model; ac = groupcolor, am = groupmarker, as = 4)

#animating

model = initialize();
anim = @animate for i in 0:10
    p1 = plotabm(model; ac = groupcolor, am = groupmarker, as = 4)
    title!(p1, "step $(i)")
    step!(model, agent_step!, 1)
end

gif(anim, "schelling.gif", fps = 2)
