using UnfoldSim
using TopoPlots
using Unfold
"""
Makes use of TopoPlots example data (originating from eegvis matlab toolbox).
type ==
"TopoPlots.jl"(default) Returns tidy DataFrame with two conditions, 64 channels and 800ms of data. This is an average over many subjects.
"""

function example_data(example = "TopoPlots.jl")

    if example == "UnfoldLinearModel"
        # load and generate a simulated Unfold Design
        data, evts = UnfoldSim.predef_eeg(; noiselevel = 10, return_epoched = true)
        data = reshape(data, 1, size(data)...)
        f = @formula 0 ~ 1 + condition + continuous
        # generate ModelStruct
        se_solver = (x, y) -> Unfold.solver_default(x, y, stderror = true)
        return fit(
            UnfoldModel,
            (Dict(Any => (f, range(0, length = size(data, 2), step = 1 / 100)))),
            evts,
            data;
            solver = se_solver,
        )
    elseif example == "UnfoldLinearModelMultiChannel"
        # load and generate a simulated Unfold Design
        cAll = DataFrame()
        sfreq = 100
        for ch = 1:5
            data, evts = UnfoldSim.predef_eeg(;
                p1 = (p100(; sfreq = sfreq), @formula(0 ~ 1), [5], Dict()),
                n1 = (
                    n170(; sfreq = sfreq),
                    @formula(0 ~ 1 + condition),
                    [5, -ch * 0.5],
                    Dict(),
                ),
                p3 = (p300(; sfreq = sfreq), @formula(0 ~ 1 + continuous), [ch, 1], Dict()),
                return_epoched = true,
            )
            data = reshape(data, 1, size(data)...)
            f = @formula 0 ~ 1 + condition + continuous
            # generate ModelStruct

            m = fit(
                UnfoldModel,
                (Dict(Any => (f, range(0, length = size(data, 2), step = 1 / 100)))),
                evts,
                data,
            )
            d = coeftable(m)
            d.channel .= ch
            cAll = append!(cAll, d)
        end
        return cAll

    elseif example == "UnfoldLinearModelContinuousTime"
        # load and generate a simulated Unfold Design
        data, evts = UnfoldSim.predef_eeg(;)
        data = reshape(data, 1, size(data)...)
        f = @formula 0 ~ 1 + condition + continuous
        basis = firbasis([0, 0.5], 100)
        # generate ModelStruct
        return fit(UnfoldModel, Dict(Any => (f, basis)), evts, data)

    elseif example == "TopoPlots.jl"
        data, chanlocs = TopoPlots.example_data()
        df = DataFrame(
            estimate = Float64[],
            time = Float64[],
            channel = Int64[],
            coefname = String[],
            topo_positions = [],
            se = Float64[],
            pval = Float64[],
        )
        pos = TopoPlots.points2mat(chanlocs)
        for ch = 1:size(data, 1)
            for t = 1:size(data, 2)
                append!(
                    df,
                    DataFrame(
                        estimate = data[ch, t, 1],
                        se = data[ch, t, 2],
                        pval = data[ch, t, 3],
                        time = t,
                        channel = ch,
                        coefname = "A",
                        topo_positions = (pos[1, ch], pos[2, ch]),
                    ),
                )
            end
        end
        df.time = range(-0.3, 0.5, step = 1 / 500)[Int.(df.time)]
        return df, chanlocs
    elseif example == "sort_data" #this should be reviewed
        dat, evts =
            UnfoldSim.predef_eeg(; onset = LogNormalOnset(μ = 3.5, σ = 0.4), noiselevel = 5)
        dat_e, times = Unfold.epoch(dat, evts, [-0.1, 1], 100)
        evts, dat_e = Unfold.dropMissingEpochs(evts, dat_e)
        evts.Δlatency = vcat(diff(evts.latency), 0)
        dat_e = dat_e[1, :, :]
        return dat_e, evts, times
    else
        error("unknown example data")
    end
end
