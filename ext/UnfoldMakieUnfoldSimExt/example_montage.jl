"""
    example_montage(String)

Creates sample channel labels and corresponding positions. There are currently 3 montages available:
- `montage_32` - return positions and channel names for 32-channel montage.\\
- `montage_64` - return positions and channel names for 64-channel montage.\\
- `channels_30` - return channel names for 30-channel montage.\\


**Return Value:** `(channels, positions)::Tuple{Vector{String}`, `Vector{UnfoldMakie.Point{2,Float32}}`}:\\
    - `channels` - vector of channel names.\\
    - `positions` - vector of channel positions.
"""
function UnfoldMakie.example_montage(example = "montage_32")
    if example == "montage_32"
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
            UnfoldMakie.Point{2,Float32}(-0.5, 1.0),   # Fp1
            UnfoldMakie.Point{2,Float32}(0.5, 1.0),   # Fp2
            UnfoldMakie.Point{2,Float32}(-0.9, 0.6),   # F7
            UnfoldMakie.Point{2,Float32}(-0.3, 0.6),   # F3
            UnfoldMakie.Point{2,Float32}(0.0, 0.6),   # Fz
            UnfoldMakie.Point{2,Float32}(0.3, 0.6),   # F4
            UnfoldMakie.Point{2,Float32}(0.9, 0.6),   # F8
            UnfoldMakie.Point{2,Float32}(-0.7, 0.3),   # FC5
            UnfoldMakie.Point{2,Float32}(-0.2, 0.3),   # FC1
            UnfoldMakie.Point{2,Float32}(0.2, 0.3),   # FC2
            UnfoldMakie.Point{2,Float32}(0.7, 0.3),   # FC6
            UnfoldMakie.Point{2,Float32}(-1.0, 0.0),   # T7
            UnfoldMakie.Point{2,Float32}(-0.5, 0.0),   # C3
            UnfoldMakie.Point{2,Float32}(0.0, 0.0),   # Cz
            UnfoldMakie.Point{2,Float32}(0.5, 0.0),   # C4
            UnfoldMakie.Point{2,Float32}(1.0, 0.0),   # T8
            UnfoldMakie.Point{2,Float32}(-0.7, -0.3),   # CP5
            UnfoldMakie.Point{2,Float32}(-0.2, -0.3),   # CP1
            UnfoldMakie.Point{2,Float32}(0.2, -0.3),   # CP2
            UnfoldMakie.Point{2,Float32}(0.7, -0.3),   # CP6
            UnfoldMakie.Point{2,Float32}(-0.9, -0.6),   # P7
            UnfoldMakie.Point{2,Float32}(-0.3, -0.6),   # P3
            UnfoldMakie.Point{2,Float32}(0.0, -0.6),   # Pz
            UnfoldMakie.Point{2,Float32}(0.3, -0.6),   # P4
            UnfoldMakie.Point{2,Float32}(0.9, -0.6),   # P8
            UnfoldMakie.Point{2,Float32}(-0.5, -0.9),   # O1
            UnfoldMakie.Point{2,Float32}(0.0, -0.9),   # Oz
            UnfoldMakie.Point{2,Float32}(0.5, -0.9),   # O2
            UnfoldMakie.Point{2,Float32}(-1.1, 0.8),   # F9
            UnfoldMakie.Point{2,Float32}(1.1, 0.8),   # F10
            UnfoldMakie.Point{2,Float32}(-1.1, -0.8),   # P9
            UnfoldMakie.Point{2,Float32}(1.1, -0.8),    # P10
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
            "FT9", "FT10", "TP9", "TP10",
        ]
        positions_64 = [
            UnfoldMakie.Point{2,Float32}(-0.5, 1.0),   # Fp1
            UnfoldMakie.Point{2,Float32}(0.5, 1.0),    # Fp2
            UnfoldMakie.Point{2,Float32}(-0.9, 0.8),   # AF7
            UnfoldMakie.Point{2,Float32}(-0.3, 0.8),   # AF3
            UnfoldMakie.Point{2,Float32}(0.3, 0.8),    # AF4
            UnfoldMakie.Point{2,Float32}(0.9, 0.8),    # AF8
            UnfoldMakie.Point{2,Float32}(-1.0, 0.6),   # F7
            UnfoldMakie.Point{2,Float32}(-0.5, 0.6),   # F5
            UnfoldMakie.Point{2,Float32}(-0.2, 0.6),   # F3
            UnfoldMakie.Point{2,Float32}(0.2, 0.6),    # F4
            UnfoldMakie.Point{2,Float32}(0.5, 0.6),    # F6
            UnfoldMakie.Point{2,Float32}(1.0, 0.6),    # F8
            UnfoldMakie.Point{2,Float32}(-1.1, 0.4),   # FT7
            UnfoldMakie.Point{2,Float32}(-0.6, 0.4),   # FC5
            UnfoldMakie.Point{2,Float32}(-0.3, 0.4),   # FC3
            UnfoldMakie.Point{2,Float32}(0.0, 0.4),    # FCz
            UnfoldMakie.Point{2,Float32}(0.3, 0.4),    # FC4
            UnfoldMakie.Point{2,Float32}(0.6, 0.4),    # FC6
            UnfoldMakie.Point{2,Float32}(1.1, 0.4),    # FT8
            UnfoldMakie.Point{2,Float32}(-1.2, 0.2),   # T7
            UnfoldMakie.Point{2,Float32}(-0.7, 0.2),   # C5
            UnfoldMakie.Point{2,Float32}(-0.4, 0.2),   # C3
            UnfoldMakie.Point{2,Float32}(0.0, 0.2),    # Cz
            UnfoldMakie.Point{2,Float32}(0.4, 0.2),    # C4
            UnfoldMakie.Point{2,Float32}(0.7, 0.2),    # C6
            UnfoldMakie.Point{2,Float32}(1.2, 0.2),    # T8
            UnfoldMakie.Point{2,Float32}(-1.1, 0.0),   # TP7
            UnfoldMakie.Point{2,Float32}(-0.6, 0.0),   # CP5
            UnfoldMakie.Point{2,Float32}(-0.3, 0.0),   # CP3
            UnfoldMakie.Point{2,Float32}(0.0, 0.0),    # CPz
            UnfoldMakie.Point{2,Float32}(0.3, 0.0),    # CP4
            UnfoldMakie.Point{2,Float32}(0.6, 0.0),    # CP6
            UnfoldMakie.Point{2,Float32}(1.1, 0.0),    # TP8
            UnfoldMakie.Point{2,Float32}(-1.0, -0.2),  # P7
            UnfoldMakie.Point{2,Float32}(-0.5, -0.2),  # P5
            UnfoldMakie.Point{2,Float32}(-0.2, -0.2),  # P3
            UnfoldMakie.Point{2,Float32}(0.0, -0.2),   # Pz
            UnfoldMakie.Point{2,Float32}(0.2, -0.2),   # P4
            UnfoldMakie.Point{2,Float32}(0.5, -0.2),   # P6
            UnfoldMakie.Point{2,Float32}(1.0, -0.2),   # P8
            UnfoldMakie.Point{2,Float32}(-0.9, -0.4),  # PO7
            UnfoldMakie.Point{2,Float32}(-0.3, -0.4),  # PO3
            UnfoldMakie.Point{2,Float32}(0.0, -0.4),   # POz
            UnfoldMakie.Point{2,Float32}(0.3, -0.4),   # PO4
            UnfoldMakie.Point{2,Float32}(0.9, -0.4),   # PO8
            UnfoldMakie.Point{2,Float32}(-0.5, -0.6),  # O1
            UnfoldMakie.Point{2,Float32}(0.0, -0.6),   # Oz
            UnfoldMakie.Point{2,Float32}(0.5, -0.6),   # O2
            UnfoldMakie.Point{2,Float32}(-0.8, -0.8),  # Iz
            UnfoldMakie.Point{2,Float32}(0.8, -0.8),   # I2
            UnfoldMakie.Point{2,Float32}(-0.7, 0.9),   # FT9
            UnfoldMakie.Point{2,Float32}(0.7, 0.9),    # FT10
            UnfoldMakie.Point{2,Float32}(-0.6, -0.9),  # TP9
            UnfoldMakie.Point{2,Float32}(0.6, -0.9),    # TP10
        ]
        return channels_64, positions_64
    elseif example == "channels_30"
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