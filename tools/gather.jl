using MocosSimMCMC
using FileIO
using Glob
using ProgressMeter
using Fire

function load_samples(data_root::AbstractString; burnout::Integer=1000, decorrelation::Integer=100)
  samples = MocosSimMCMC.HistoryRecord[]
  @showprogress for path in Glob.glob("*history_*.jld2", data_root);
    append!(samples, filter!(h->h.accepted, load(path, "history"))[burnout:decorrelation:end])
  end
  samples
end

@main function main(data_root::AbstractString, output_path::AbstractString; burnout::Integer=1000, decorrelation::Integer=100 )
  samples = load_samples(data_root, burnout=burnout, decorrelation=decorrelation )
  save(output_path, "samples", samples, compress=true)
end