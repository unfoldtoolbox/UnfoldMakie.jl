using UnfoldSim
using TopoPlots
using Unfold
using Random

"""
    example_data(String) 

Creates example data or model. Currently, 3 datasets and 6 models are available.

Datasets:
- `TopoPlots.jl` (default) - provide 2 outputs from `TopoPlots.jl`:\\
    - `Array{Float32, 3}` with 64 channels, 800 ms time range and 3 types of values (estimate, sterror and pvalue).\\
    - `Vector{Point{2, Float32}}` with posiions for 64 electrodes.
- `UnfoldLinearModelMultiChannel` - DataFrame with 5 channels, 3 coefnames, sterror, time and estimate.
- `sort_data` - 2 DataFrames: 
    - `dat` for EEG recordings  and `evts` with event variables occured during experiment.\\
    - `evts` could be used for sorting EEG data in ERP image. 

Models:
- `UnfoldLinearModel` - Model with formula `1 + condition + continuous`.
- `UnfoldLinearModelContinuousTime` - Model with formula `timeexpand(1 + condition + continuous)` for times [0.0, 0.01 ... 0.5].
- `UnfoldLinearModelwith1Spline` - Model with formula `1 + condition + spl(continuous, 4)`.
- `UnfoldLinearModelwith2Splines` - Model with formula ` 1 + condition + spl(continuous, 4) + spl(continuous2, 6)`.
- `7channels` - Model with formula `timeexpand(1 + condA)` for times [-0.1, -0.09 ... 0.5].
- `UnfoldTimeExpanded` - Model with formula `timeexpand(1 + condition + continuous)` for times [-0.4, -0.39 ... 0.8].

**Return Value:** `DataFrame`.
"""
function example_data(example = "TopoPlots.jl")
    if example == "UnfoldLinearModel"
        # load and generate a simulated Unfold Design
        data, evts = UnfoldSim.predef_eeg(; noiselevel = 12, return_epoched = true)
        data = reshape(data, (1, size(data)...))
        f = @formula 0 ~ 1 + condition + continuous
        # generate ModelStruct 
        se_solver = (x, y) -> Unfold.solver_default(x, y, stderror = true)
        return fit(
            UnfoldModel,
            [Any => (f, range(0, length = size(data, 2), step = 1 / 100))],
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
                [(Any => (f, range(0, length = size(data, 2), step = 1 / 100)))],
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
        return fit(UnfoldModel, [Any => (f, basis)], evts, data)
    elseif example == "UnfoldLinearModelwith1Spline"
        # load and generate a simulated Unfold Design
        data, evts = UnfoldSim.predef_eeg(; noiselevel = 12, return_epoched = true)
        data = reshape(data, (1, size(data)...))
        evts.continuous2 .=
            log10.(6 .+ rand(MersenneTwister(1), length(evts.continuous))) .^ 2
        f = @formula 0 ~ 1 + condition + spl(continuous, 4)
        # generate ModelStruct
        se_solver = (x, y) -> Unfold.solver_default(x, y, stderror = true)
        return fit(
            UnfoldModel,
            [Any => (f, range(0, length = size(data, 2), step = 1 / 100))],
            evts,
            data;
            solver = se_solver,
        )
    elseif example == "UnfoldLinearModelwith2Splines"
        # load and generate a simulated Unfold Design
        data, evts = UnfoldSim.predef_eeg(; noiselevel = 12, return_epoched = true)
        data = reshape(data, (1, size(data)...))
        evts.continuous2 .=
            log10.(6 .+ rand(MersenneTwister(1), length(evts.continuous))) .^ 2
        f = @formula 0 ~ 1 + condition + spl(continuous, 4) + spl(continuous2, 6)
        # generate ModelStruct
        se_solver = (x, y) -> Unfold.solver_default(x, y, stderror = true)
        return fit(
            UnfoldModel,
            [Any => (f, range(0, length = size(data, 2), step = 1 / 100))],
            evts,
            data;
            solver = se_solver,
        )
    elseif example == "7channels"
        design =
            SingleSubjectDesign(conditions = Dict(:condA => ["levelA", "levelB"])) |>
            x -> RepeatDesign(x, 20)
        c = LinearModelComponent(;
            basis = p100(),
            formula = @formula(0 ~ 1 + condA),
            β = [1, 0.5],
        )
        mc = MultichannelComponent(c, [1, 2, -1, 3, 5, 2.3, 1])
        onset = UniformOnset(; width = 20, offset = 4)
        df, evnts =
            simulate(MersenneTwister(1), design, [mc], onset, PinkNoise(noiselevel = 0.05))
        basisfunction = firbasis((-0.1, 0.5), 100)
        f = @formula 0 ~ 1 + condA
        bf_dict = [Any => (f, basisfunction)]
        return fit(UnfoldModel, bf_dict, evnts, df)
    elseif example == "UnfoldTimeExpanded"
        df, evts = UnfoldSim.predef_eeg()
        f = @formula 0 ~ 1 + condition + continuous
        basisfunction = firbasis(τ = (-0.4, 0.8), sfreq = 100, name = "stimulus")
        #basisfunction = firbasis(τ = (-0.4, -0.3), sfreq = 10)
        bfDict = [Any => (f, basisfunction)]
        return fit(UnfoldModel, bfDict, evts, df)
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
        evts, dat_e = Unfold.drop_missing_epochs(evts, dat_e)
        evts.Δlatency = vcat(diff(evts.latency), 0)
        dat_e = dat_e[1, :, :]
        #evts = filter(row -> row.Δlatency > 0, evts)
        return dat_e, evts, times
    elseif example == "bootstrap_toposeries"
        trials = 50
        time_padding = 100
        component = n400()
        design = UnfoldSim.SingleSubjectDesign(conditions = Dict(:condA => ["levelA"])) # design with one condition
        design = UnfoldSim.RepeatDesign(design, trials)
        generate_events(design)

        time1 = vcat(rand(time_padding), component) # 500 msec = randiom 100 msec and 400 msec of n400
        c = UnfoldSim.LinearModelComponent(;
            basis = time1,
            formula = @formula(0 ~ 1),
            β = [1],
        )

        hart = headmodel(type = "hartmut") # 227 electrodes
        less_hart = magnitude(hart)[:, 1] # extract 1 lead field and 64 electrodes

        mc = UnfoldSim.MultichannelComponent(c, less_hart)

        # simulation of 3d matrix
        onset = UniformOnset(; width = 20, offset = 4)
        dat, events = simulate(
            MersenneTwister(1),
            design,
            mc,
            onset,
            PinkNoise(noiselevel = 0.05),
            return_epoched = true,
        )

        # Create the DataFrame
        df = DataFrame(
            :estimate => dat[:],
            :channel =>
                repeat(1:size(dat, 1), outer = Int(length(dat[:]) / size(dat, 1))),
            :time => repeat(1:size(dat, 2), outer = Int(length(dat[:]) / size(dat, 2))),
            :trial =>
                repeat(1:size(dat, 3), outer = Int(length(dat[:]) / size(dat, 3))),
        )

        # chosing positions
        pos3d = hart.electrodes["pos"]
        pos2d = to_positions(pos3d')
        pos2d = [Point2f(p[1] + 0.5, p[2] + 0.5) for p in pos2d]
        return df, pos2d
    elseif example == "raw_ch_names"
        return [
            "FP1",
            "F3",
            "F7",
            "FC3",
            "C3",
            "C5",
            "P3",
            "P7",
            "P9",
            "PO7",
            "PO3",
            "O1",
            "Oz",
            "Pz",
            "CPz",
            "FP2",
            "Fz",
            "F4",
            "F8",
            "FC4",
            "FCz",
            "Cz",
            "C4",
            "C6",
            "P4",
            "P8",
            "P10",
            "PO8",
            "PO4",
            "O2",
        ]
    else
        error("unknown example data")
    end
end
