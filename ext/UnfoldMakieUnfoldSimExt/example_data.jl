"""
    example_data(String; kwargs...) 

Creates example data or model. Currently, 3 datasets and 6 models are available.

Arguments:\\
- `noiselevel::Int64 = 10` - noise level for EEG data. Will be sent to `UnfoldSim.predef_eeg` function.\\

Datasets:\\
- `TopoPlots.jl` (default) - provide 2 objects from `TopoPlots.jl`:\\
    - `Array{Float32, 3}` with 64 channels, 800 ms time range and 3 types of values (mean estimate, sterror and pvalue).\\
    - `Vector{Point{2, Float32}}` with posiions for 64 electrodes.
- `UnfoldLinearModelMultiChannel` - DataFrame with 5 channels, 3 coefnames, sterror, time and estimate.
- `sort_data` - 2 DataFrames: 
    - `dat` for EEG recordings  and `evts` with event variables occured during experiment.\\
    - `evts` could be used for sorting EEG data in ERP image. 
- `bootstrap_toposeries` - DataFrame with 50 trials, 160 time points and 227 electrode positions.\\

Models:\\
- `UnfoldLinearModel` - Model with formula `1 + condition + continuous`.\\
- `UnfoldLinearModelContinuousTime` - Model with formula `timeexpand(1 + condition + continuous)` for times [0.0, 0.01 ... 0.5].\\
- `UnfoldLinearModelwith1Spline` - Model with formula `1 + condition + spl(continuous, 4)`.\\
- `UnfoldLinearModelwith2Splines` - Model with formula ` 1 + condition + spl(continuous, 4) + spl(continuous2, 6)`.\\
- `7channels` - Model with formula `timeexpand(1 + condA)` for times [-0.1, -0.09 ... 0.5].\\
- `UnfoldTimeExpanded` - Model with formula `timeexpand(1 + condition + continuous)` for times [-0.4, -0.39 ... 0.8].\\

**Return Value:** `DataFrame`.
"""
function UnfoldMakie.example_data(example = "TopoPlots.jl"; noiselevel = 10)
    if example == "UnfoldLinearModel"
        # load and generate a simulated Unfold Design
        data, evts = UnfoldSim.predef_eeg(; noiselevel = 12, return_epoched = true)
        data = reshape(data, (1, size(data)...))
        f = @formula 0 ~ 1 + condition + continuous
        # generate ModelStruct 
        se_solver = (x, y) -> Unfold.solver_default(x, y, stderror = true)
        return Unfold.fit(
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

            m = Unfold.fit(
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
        return Unfold.fit(UnfoldModel, [Any => (f, basis)], evts, data)
    elseif example == "UnfoldLinearModelwith1Spline"
        # load and generate a simulated Unfold Design
        data, evts = UnfoldSim.predef_eeg(; noiselevel = 12, return_epoched = true)
        data = reshape(data, (1, size(data)...))
        evts.continuous2 .=
            log10.(6 .+ rand(MersenneTwister(1), length(evts.continuous))) .^ 2
        f = @formula 0 ~ 1 + condition + spl(continuous, 4)
        # generate ModelStruct
        se_solver = (x, y) -> Unfold.solver_default(x, y, stderror = true)
        return Unfold.fit(
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
        return Unfold.fit(
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
        return Unfold.fit(UnfoldModel, bf_dict, evnts, df)
    elseif example == "UnfoldTimeExpanded"
        df, evts = UnfoldSim.predef_eeg()
        f = @formula 0 ~ 1 + condition + continuous
        basisfunction = firbasis(τ = (-0.4, 0.8), sfreq = 100, name = "stimulus")
        #basisfunction = firbasis(τ = (-0.4, -0.3), sfreq = 10)
        bfDict = [Any => (f, basisfunction)]
        return Unfold.fit(UnfoldModel, bfDict, evts, df)
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

        hart = headmodel() # 227 electrodes
        less_hart = magnitude(hart)[:, 1] 

        mc = UnfoldSim.MultichannelComponent(c, less_hart)

        # simulation of 3d matrix
        onset = UniformOnset(; width = 20, offset = 4)
        dat, events = simulate(
            MersenneTwister(1),
            design,
            mc,
            onset,
            PinkNoise(noiselevel = noiselevel),
            return_epoched = true,
        )

        df_toposeries = Unfold.result_to_table(
            dat,
            [DataFrame(:trial => 1:size(dat, 3))],
            [1:size(dat, 2)],
            ["myevent"],
        )
        rename!(df_toposeries, :yhat => :estimate)
        # chosing positions
        pos_toposeries =
            hart.electrodes["pos"] |>
            x -> to_positions(x') |>
            x -> [UnfoldMakie.Point2f(p[1] + 0.5, p[2] + 0.5) for p in x]
        return df_toposeries, pos_toposeries, hart.electrodes["label"]
    else
        error("unknown example data")
    end
end
