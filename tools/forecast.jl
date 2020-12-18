using MocosSimMCMC
using Dates
using FileIO
using DataFrames
using FixedPointNumbers
using PyPlot
using Glob
using ProgressMeter
using Fire
using StatsBase

function load_samples(data_root::AbstractString; burnout::Integer=1000, decorrelation::Integer=100)
  samples = MocosSimMCMC.HistoryRecord[]
  @showprogress for path in Glob.glob("*history_*.jld2", data_root);
    append!(samples, filter!(h->h.accepted, load(path, "history"))[burnout:decorrelation:end])
  end
  samples
end

function plot_trajectory(daily::AbstractVector{T} where T<: Integer, averaged::AbstractVector{T} where T <: Real; avg_offset::Real=3, fig=figure())
  plot(1-length(daily):0, daily, "ks", label="historic (daily)")
  plot((1-length(averaged):0) .- avg_offset, averaged, label="historic (centered 7 day average)")
  legend()
  xlim(-28, 0)
  ylim(bottom=0)
  fig
end

function plot_bundle(samples::AbstractVector{MocosSimMCMC.HistoryRecord},
  daily::AbstractVector{T} where T <: Integer,
  daily_averaged::AbstractVector{T} where T <: Real,
  ;fig=figure(figsize=(10,8)), avg_offset::Real=3, past_days=56, future_days=56)
  for history in samples
    traj = history.trajectory
    off = history.offset
    plot(1-avg_offset-off:length(traj)-avg_offset-off, traj, linewidth=0.5)
  end
  plot(1-length(daily):0, daily, "ks", label="daily")
  plot(1-length(daily_averaged)-avg_offset:-avg_offset, daily_averaged, "k-", label="centered 7-day average")
  legend()
  xlim(left=-past_days, right=future_days)
  fig
end

function plot_marginals(samples::AbstractVector{MocosSimMCMC.HistoryRecord}; fig = figure(figsize=(10,8)))
  df = MocosSimMCMC.history2df(samples);

  subplot(321)
  hist(df.b, 0:0.025:1, density=true)
  ylabel("pdf")
  xlabel("b")

  subplot(322)
  hist(df.q, 0:0.025:1, density=true)
  ylabel("pdf")
  xlabel("q")

  subplot(323)
  hist(df.c, range(0,1.35, length=41), density=true)
  ylabel("pdf")
  xlabel("c")

  subplot(324)
  hist(df.mlim, 0:0.025:1, density=true)
  ylabel("pdf")
  xlabel("mlim")

  subplot(325)
  hist(df.mloc, 0:100:5000, density=true)
  ylabel("pdf")
  xlabel("mloc")

  subplot(326)
  hist(df.msca, 0:10:500, density=true)
  ylabel("pdf")
  xlabel("msca")

  fig.tight_layout()
  #savefig("marginals.png", bbox_inches="tight")
  fig
end

getrelative(record::MocosSimMCMC.HistoryRecord, idx::Integer) = idx + record.offset > length(record.trajectory) ? 0 : record.trajectory[idx+record.offset]

function compute_quantiles(samples::AbstractVector{MocosSimMCMC.HistoryRecord}, days::AbstractVector{T} where T<:Integer; quantiles=0:0.05:1)
  mat = getrelative.(samples, (days)')
  quantile.(eachcol(mat), (quantiles)')
end

function plot_quantiles( samples::AbstractVector{MocosSimMCMC.HistoryRecord}, daily::AbstractVector{T} where T<: Real, daily7::AbstractVector{T} where T<:Real, date0::Date;
  fig=figure(figsize=(10,8)), avg_offset::Integer=3, pastdays=21, futuredays=56
)
  quantiles = 0:0.05:1
  forecast_days = avg_offset:futuredays
  quantile_trajectories = compute_quantiles(samples, forecast_days, quantiles=quantiles)

  daily7 = MocosSimMCMC.running_average(daily, 7)
  plot(1-length(daily):0, daily, "ks", label="historic daily")
  plot((1-length(daily7):0) .- avg_offset, daily7, label="historic 7 day average (centered)")

  plot(forecast_days .- avg_offset, (@view quantile_trajectories[:, begin+1 : end-1]), "b-", linewidth=0.5)
  plot(forecast_days .- avg_offset, (@view quantile_trajectories[:, (begin+end)÷2]), "g-", label="forecasted 7 day average: median")

  plot(forecast_days .- avg_offset, (@view quantile_trajectories[:, begin]), "r-", linewidth=0.5, label="forecasted 7 day average: min")
  plot(forecast_days .- avg_offset, (@view quantile_trajectories[:, end]), "r-", linewidth=0.5, label="forecasted 7 day average: max")

  legend()

  alldays = -pastdays : futuredays
  tickdays = alldays[begin:7:end]
  ticklabels = date0 .+ Dates.Day.(tickdays)
  xticks(tickdays, ticklabels, rotation=60)
  ylim(bottom=0)
  xlim(-pastdays, futuredays)

  #savefig("prediction.png", bbox_inches="tight")
  fig
end


@main function main(data_root::AbstractString, trajectory_path::AbstractString, plot_dir::AbstractString; burnout::Integer=1000, decorrelation::Integer=100 )
  daily = load(trajectory_path, "daily")
  averaged_daily = MocosSimMCMC.running_average(daily, 7)

  plot_trajectory(daily, averaged_daily, avg_offset=3)
  savefig(plot_dir * "/trajectory.png", bbox_inches="tight")

  samples = load_samples(data_root, burnout=burnout, decorrelation=decorrelation )
  plot_bundle(samples, daily, averaged_daily, avg_offset=3)
  savefig(plot_dir * "/bundle.png", bbox_inches="tight")

  plot_marginals(samples)
  savefig(plot_dir * "/marginals.png", bbox_inches="tight")

  date0 = Date(2020,12,07)
  plot_quantiles(samples, daily, averaged_daily, date0)
  savefig(plot_dir * "/prediction_quantiles.png", bbox_inches="tight")
end