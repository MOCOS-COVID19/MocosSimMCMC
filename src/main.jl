using TOML
using ArgParse
using DataFrames
using Distributions
using ProgressMeter
using JLD2
using FileIO

function parse_commandline()
	s = ArgParseSettings()
	@add_arg_table! s begin
		"config"
      help = "path to a config file with the parameter settings"
      required = true
      arg_type = String

      "--output-history-dump", "-o"
      help = "path where genereated samples are saved"
      required = true

      arg_type = String
    "--population"
      help = "path to population in JLD2 format"
      required = false
      arg_type = String

    "--data"
      help = "path to file with observed detections"
      required = false
      arg_type = String

    "--global-seed"
      help = "a number value that is added to the move seed and simulation seed"
      default = UInt(0)
      arg_type = UInt
	end
  parse_args(ARGS, s)
end

function loadparams(population_path::AbstractString, params_seed::Integer=0)
  individuals_df = load(population_path, "individuals_df");
  params_seed = 0
  rng = Random.MersenneTwister(params_seed)

  MocosSim.load_params(
    population=individuals_df,
    infection_modulation_name="TanhModulation",
    infection_modulation_params=(scale=2000, loc=10000, weight_detected=1, weight_deaths=0, limit_value=0.6),
    mild_detection_prob=0.6,
    backward_tracing_prob=0.6,
    forward_tracing_prob=0.6,
    constant_kernel_param=1.35,
    household_kernel_param=0.07
  );
end

function mergearg!(config, cmd_args, name)
  if cmd_args[name] !== nothing
    config[name] = cmd_args[name]
  end
end

loadinitials(initials_config::Dict{String,T} where T) = FitParams(;map( ((k,v),)-> Symbol(k) => v, collect(initials_config))...)

loadmoves(moves_config::Dict{String,T} where T)::Array{Pair{Symbol, Function}} = map(collect(moves_config)) do (k,v)
  Symbol(k) => (rng->rand(rng, Normal(0,v)))
end

function main()
  cmd_args = parse_commandline()
  config = TOML.parsefile(cmd_args["config"])

  mergearg!(config, cmd_args, "population")
  mergearg!(config, cmd_args, "data")
  mergearg!(config, cmd_args, "output-history-dump")
  mergearg!(config, cmd_args, "global-seed")

  @info "launched" config

  global_seed = config["global-seed"]

  daily = load(config["data"], "daily");
  daily7avg = running_average(daily, 7);

  moves = loadmoves(config["moves"])
  initial_fitparams = loadinitials(config["initials"])
  simparams = loadparams(config["population"], get(config, "param_seed", 0))

  sampler = Sampler(
    move_seed=config["move_seed"] + global_seed,
    simparams=simparams,
    trajectory_error=NormalTrajectoryError(daily7avg, 0.1, 0.1, 0.1, 0.1, 0.1),
    moves=moves,
    fitpriors=FitPriors(
        Uniform(0, 1.35),
        Uniform(0, 1),
        Uniform(0, 1),
        Exponential(10000),
        Exponential(2000),
        Uniform(0, 1)
      ),
    initial_fitparams=initial_fitparams,
    num_initial=config["num_initial"],
    max_total_detections=config["max_total_detections"],
    max_daily_detections=config["max_daily_detections"],
    global_seed = global_seed
  );

  history = HistoryRecord[]
  @showprogress for i in 1:config["num_samples"]
    push!(history, nextsample!(sampler))
  end
  save(config["output-history-dump"],
    "history", history,
    compress=true)
end