import Pkg
Pkg.add("Agents")
Pkg.add("InteractiveDynamics")
Pkg.add("CairoMakie")
using Agents, Agents.Pathfinding, InteractiveDynamics, CairoMakie

struct Species
    name::Symbol
    seasonStop::Int
    devWeight_Q_PupationMin::Float64 # mg
    devWeight_Q_PupationMax::Float64 # mg
end

mutable struct Flowers
    name::Symbol
    protein_pollen_prop::Float64
    concentration::Float64 # mol/l
    season::UnitRange{Int}
    corolla_depth::Float64 # m
    inter_flower_time::Float64 # s
    pollen_production::Array{Float64,2}
    nectar_production::Array{Float64,2}
    pollen_quantities::Array{Float64,2}
    nectar_quantities::Array{Float64,2}
end

mutable struct Colony
    position::Tuple{Int,Int}
end

@agent Bees NoSpaceAgent begin
    number::Int
    colony::Union{Colony,Nothing}
    species::Species
    type::Symbol # egg, larva, pupa, male, worker, queen
    activity::Symbol # hibernate, nestConstruction, emerging, resting, searching, returningEmpty, returningUnhappyN, returningUnhappyP, nectarForaging, collectNectar, bringingNectar, expForagingN, pollenForaging, collectPollen, bringingPollen, expForagingP, egglaying, nursing
    emerging_date::Int
    weight::Float64 # mg
end

function winter_mortality_probibility(bees){
    # Winter survival (survival_probibility) is calculated from Beekman et al 1998 (Entomologia Experimentalis et Applicata 89: 207–214, 1998)
    # Fig. 1B: survival prob. is calculated from proportion of survivors to survivors + non-survivors. Using the relative weight rather than the absolute weight, we fitted a sigmoid curve (survivalProb) to the left site only,
    # as the low surv. prob. of heavy queens is an artefact of the treatment:
    # "One would expect that queens with the highest weight will survive diapause. It is therefore surprising that the initial weight distribution of dead queens exceeds that of the surviving queens (Figure 1B and 1C).
    # However, in 1993 the average initial weight of the queens was highest and in this period the most severe diapause regimes (6 or 8 months) were started. Since the majority of the queens that were given a treatment
    # with a length of 6 or 8 months died, the initial weight distribution of dead queens exceeds that of the surviving queens."
    
    relative_weight = (bees.weight - bee.species.devWeight_Q_PupationMin) / ( bee.species.devWeight_Q_PupationMax - bee.species.devWeight_Q_PupationMin )
    survival_probibility = 0.64 / (1 + ℯ ^ (-22 * (relative_weight - 0.32))) # returns survival_probibility
}

function bees_step!(bees, model)
    # kill all bees that are not hibernating at the end of the season
    if bees.species.seasonStop == model.tick % 365 && bees.activity != :hibernate
        kill_agent!(bees, model)
    end

    # new queens emerge from hibernation and found new colonies (note: most queens will still be represented as cohorts here!) 
    # Winter survival (survivalProb) is calculated from Beekman et al 1998 (Entomologia Experimentalis et Applicata 89: 207–214, 1998)
    # Fig. 1B: survival prob. is calculated from proportion of survivors to survivors + non-survivors. Fitted a sigmoid curve to the left site only, as the low surv. prob. of heavy queens
    # is an artefact of the treatment:
    # "One would expect that queens with the highest weight will survive diapause. It is therefore surprising that the initial weight distribution of dead queens exceeds that of the surviving queens (Figure 1B and 1C).
    # However, in 1993 the average initial weight of the queens was highest and in this period the most severe diapause regimes (6 or 8 months) were started. Since the majority of the queens that were given a treatment
    # with a length of 6 or 8 months died, the initial weight distribution of dead queens exceeds that of the surviving queens."
    if bees.emerging_date == model.tick
        bees.activity = :emerging
        # clone cohort based queens to become individuals
        for _ ∈ 2:bees.number
            add_agent!(Bees(1, bees.colony, bees.species, bees.type, bees.activity, bees.emerging_date, bees.weight), model)
        end
        bees.number = 1
    end
    if bees.activity == :emerging
        # WINTER MORTALITY:
        # Queen has a risk of dying over winter:
        if rand() < winter_mortality_probibility(bees)
            kill_agent!(bees, model)
        end
    end
end

function world_step!(model)
    # update food in tiles
    for flowers ∈ model.flowers
        if model.tick % 365 ∈ flowers.season
            flowers.pollen_quantities += flower.pollen_production
            flowers.nectar_quantities += flower.nectar_production
        end
    end

    # kill males in autumn if all queens are in hibernation and no brood is left
    if !any(bees -> bees.type == :queen && bees.activity != :hibernate, model) && !any(bees -> bees.type == :egg || bees.type == :larva || bees.type == :pupa, model)
        for bees ∈ model
            if bees.type == :male
                kill_agent!(bees, model)
            end
        end
    end

    model.tick += 1
end

function create_word(
    flowers::Vector{Flowers}=[
        Flowers(
            :dandelion,
            0.091663467,
            1.294673289,
            1:364,
            0.0012,
            0.6,
            ones(100, 100) * 0.000433333,
            ones(100, 100) * 0.000000470167,
            zeros(100, 100),
            zeros(100, 100)
        )
    ],
    land_type::Array{Symbol,2}=fill(:grass_land, 100, 100),
    tile_size::Float64=1.0, # m
    forging_time::Int=8 * 60 * 60 # seconds per day
)
    properties = Dict(
        :flowers => flowers,
        :land_type => land_type,
        :tile_size => tile_size,
        :forging_time => forging_time,
        :tick => 0,
    )
    model = ABM(Bees, properties)
    return model
end

create_word()