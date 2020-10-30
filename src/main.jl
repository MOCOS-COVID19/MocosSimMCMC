using TOML
using ArgParse
using DataFrames
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
    "--output-history-dump"
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
      help = "a seed value that is added to all other seeds"
      default = 0
      arg_type = Int
	end
  parse_args(ARGS, s)
end

function loadparams(population_path, params_seed=0)
  individuals_df = load(population_path, "individuals_df");
  params_seed = 0
  rng = Random.MersenneTwister(params_seed)

  simparams = MocosSim.load_params(
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

function main()
  cmd_args = parse_commandline()
  config = merge(TOML.parsefile(cmd_args["config"]), cmd_args)
  @info "launched" config

  global_seed = config["global-seed"]

  daily = load(config["data"], "daily");
  daily7avg = running_average(daily, 7);

  simparams = loadparams(config["population"], get(config, "param_seed", 0) + global_seed)

  sampler = Sampler(
    move_seed=config["move_seed"] + global_seed,
    simparams=simparams,
    trajectory_error=NormalTrajectoryError(daily7avg, 0.1, 0.1, 0.1, 0.1, 0.1),
    moves=[
        :b => (rng)->rand(rng, Normal(0, 0.03)),
        :q => (rng)->rand(rng, Normal(0, 0.03)),
        :mlim => (rng)->rand(rng, Normal(0, 0.03))
      ],
    fitpriors=FitPriors(
        Uniform(0, 1.35),
        Uniform(0, 1),
        Uniform(0, 1),
        Geometric(1/10000),
        Geometric(1/2000),
        Uniform(0, 1)
      ),
    initial_fitparams=FitParams(1.35, 0.1, 0.1, 1000, 200, 0.1),
    num_initial=100,
    max_total_detections=10^6,
    max_daily_detections=5000,
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