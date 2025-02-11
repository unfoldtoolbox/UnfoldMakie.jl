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
- `montage_32` - return positions and channel names for 32-channel montage.

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
            PinkNoise(noiselevel = 10.5),
            return_epoched = true,
        )

        # Create the DataFrame
        #= Unfold.result_to_table(eff::Vector{<:AbstractArray}, events::Vector{<:DataFrame},
            times::Vector, eventnames::Vector)
        Unfold.result_to_table(rand(5,11,13), [DataFrame(:trial=>1:13)], [1:11], ["myevent"]) =#
        df_toposeries = Unfold.result_to_table(
            dat,
            [DataFrame(:trial => 1:size(dat, 3))],
            [1:size(dat, 2)],
            ["myevent"],
        )
        rename!(df_toposeries, :yhat => :estimate)
        # chosing positions
        pos3d = hart.electrodes["pos"]
        pos2d = to_positions(pos3d')
        pos_toposeries = [Point2f(p[1] + 0.5, p[2] + 0.5) for p in pos2d]
        return df_toposeries, pos_toposeries

    elseif example == "montage_32"
        # Channel names
        channels_32 = [
            "Fp1", "Fp2", "F7", "F3", "Fz", "F4", "F8",
            "FC5", "FC1", "FC2", "FC6",
            "T7", "C3", "Cz", "C4", "T8",
            "CP5", "CP1", "CP2", "CP6",
            "P7", "P3", "Pz", "P4", "P8",
            "O1", "Oz", "O2",
            "F9", "F10", "P9", "P10",
        ]
        # Compute positions
        positions_32 = [
            Point{2,Float32}(-0.5, 1.0),   # Fp1
            Point{2,Float32}(0.5, 1.0),   # Fp2
            Point{2,Float32}(-0.9, 0.6),   # F7
            Point{2,Float32}(-0.3, 0.6),   # F3
            Point{2,Float32}(0.0, 0.6),   # Fz
            Point{2,Float32}(0.3, 0.6),   # F4
            Point{2,Float32}(0.9, 0.6),   # F8
            Point{2,Float32}(-0.7, 0.3),   # FC5
            Point{2,Float32}(-0.2, 0.3),   # FC1
            Point{2,Float32}(0.2, 0.3),   # FC2
            Point{2,Float32}(0.7, 0.3),   # FC6
            Point{2,Float32}(-1.0, 0.0),   # T7
            Point{2,Float32}(-0.5, 0.0),   # C3
            Point{2,Float32}(0.0, 0.0),   # Cz
            Point{2,Float32}(0.5, 0.0),   # C4
            Point{2,Float32}(1.0, 0.0),   # T8
            Point{2,Float32}(-0.7, -0.3),   # CP5
            Point{2,Float32}(-0.2, -0.3),   # CP1
            Point{2,Float32}(0.2, -0.3),   # CP2
            Point{2,Float32}(0.7, -0.3),   # CP6
            Point{2,Float32}(-0.9, -0.6),   # P7
            Point{2,Float32}(-0.3, -0.6),   # P3
            Point{2,Float32}(0.0, -0.6),   # Pz
            Point{2,Float32}(0.3, -0.6),   # P4
            Point{2,Float32}(0.9, -0.6),   # P8
            Point{2,Float32}(-0.5, -0.9),   # O1
            Point{2,Float32}(0.0, -0.9),   # Oz
            Point{2,Float32}(0.5, -0.9),   # O2
            Point{2,Float32}(-1.1, 0.8),   # F9
            Point{2,Float32}(1.1, 0.8),   # F10
            Point{2,Float32}(-1.1, -0.8),   # P9
            Point{2,Float32}(1.1, -0.8),    # P10
        ]
        return channels_32, positions_32
    elseif example == "montage_64"
        # Channel names
        channels_64 = [
            "Fp1", "Fp2", "F7", "F3", "Fz", "F4", "F8",
            "FC5", "FC1", "FC2", "FC6",
            "T7", "C3", "Cz", "C4", "T8",
            "CP5", "CP1", "CP2", "CP6",
            "P7", "P3", "Pz", "P4", "P8",
            "POz", "O1", "Oz", "O2",
            "AF7", "AF3", "AF4", "AF8",
            "F5", "F1", "F2", "F6",
            "FT7", "FC3", "FC4", "FT8",
            "C5", "C1", "C2", "C6",
            "TP7", "CP3", "CP4", "TP8",
            "P5", "P1", "P2", "P6",
            "PO7", "PO3", "PO4", "PO8",
            "I1", "Iz", "I2",
            "FT9", "FT10", "TP9", "TP10"
        ]
        positions_64 = [
            Point{2,Float32}(-0.5, 1.0),   # Fp1
            Point{2,Float32}(0.5, 1.0),    # Fp2
            Point{2,Float32}(-0.9, 0.8),   # AF7
            Point{2,Float32}(-0.3, 0.8),   # AF3
            Point{2,Float32}(0.3, 0.8),    # AF4
            Point{2,Float32}(0.9, 0.8),    # AF8
            Point{2,Float32}(-1.0, 0.6),   # F7
            Point{2,Float32}(-0.5, 0.6),   # F5
            Point{2,Float32}(-0.2, 0.6),   # F3
            Point{2,Float32}(0.2, 0.6),    # F4
            Point{2,Float32}(0.5, 0.6),    # F6
            Point{2,Float32}(1.0, 0.6),    # F8
            Point{2,Float32}(-1.1, 0.4),   # FT7
            Point{2,Float32}(-0.6, 0.4),   # FC5
            Point{2,Float32}(-0.3, 0.4),   # FC3
            Point{2,Float32}(0.0, 0.4),    # FCz
            Point{2,Float32}(0.3, 0.4),    # FC4
            Point{2,Float32}(0.6, 0.4),    # FC6
            Point{2,Float32}(1.1, 0.4),    # FT8
            Point{2,Float32}(-1.2, 0.2),   # T7
            Point{2,Float32}(-0.7, 0.2),   # C5
            Point{2,Float32}(-0.4, 0.2),   # C3
            Point{2,Float32}(0.0, 0.2),    # Cz
            Point{2,Float32}(0.4, 0.2),    # C4
            Point{2,Float32}(0.7, 0.2),    # C6
            Point{2,Float32}(1.2, 0.2),    # T8
            Point{2,Float32}(-1.1, 0.0),   # TP7
            Point{2,Float32}(-0.6, 0.0),   # CP5
            Point{2,Float32}(-0.3, 0.0),   # CP3
            Point{2,Float32}(0.0, 0.0),    # CPz
            Point{2,Float32}(0.3, 0.0),    # CP4
            Point{2,Float32}(0.6, 0.0),    # CP6
            Point{2,Float32}(1.1, 0.0),    # TP8
            Point{2,Float32}(-1.0, -0.2),  # P7
            Point{2,Float32}(-0.5, -0.2),  # P5
            Point{2,Float32}(-0.2, -0.2),  # P3
            Point{2,Float32}(0.0, -0.2),   # Pz
            Point{2,Float32}(0.2, -0.2),   # P4
            Point{2,Float32}(0.5, -0.2),   # P6
            Point{2,Float32}(1.0, -0.2),   # P8
            Point{2,Float32}(-0.9, -0.4),  # PO7
            Point{2,Float32}(-0.3, -0.4),  # PO3
            Point{2,Float32}(0.0, -0.4),   # POz
            Point{2,Float32}(0.3, -0.4),   # PO4
            Point{2,Float32}(0.9, -0.4),   # PO8
            Point{2,Float32}(-0.5, -0.6),  # O1
            Point{2,Float32}(0.0, -0.6),   # Oz
            Point{2,Float32}(0.5, -0.6),   # O2
            Point{2,Float32}(-0.8, -0.8),  # Iz
            Point{2,Float32}(0.8, -0.8),   # I2
            Point{2,Float32}(-0.7, 0.9),   # FT9
            Point{2,Float32}(0.7, 0.9),    # FT10
            Point{2,Float32}(-0.6, -0.9),  # TP9
            Point{2,Float32}(0.6, -0.9)    # TP10
        ]
        return channels_64, positions_64
    elseif example == "raw_ch_names" # rename to channels_30
        return [
            "FP1", "F3", "F7", "FC3", "C3", "C5",
            "P3", "P7", "P9", "PO7", "PO3", "O1",
            "Oz", "Pz", "CPz", "FP2", "Fz", "F4",
            "F8", "FC4", "FCz", "Cz", "C4", "C6",
            "P4", "P8", "P10", "PO8", "PO4", "O2",
        ]
    else
        error("unknown example data")
    end
end
