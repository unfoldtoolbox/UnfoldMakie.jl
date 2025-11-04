"""
    example_montage(String)

Creates sample channel labels and corresponding positions. There are currently 3 montages available:
- `montage_32` or `biosemi_32` - return positions and labels for 32-channel montage.\\
- `montage_64` or `biosemi_64` - return positions and labels for 64-channel montage.\\
- `labels_30` or `chanels_30` - return labels for 30-channel montage.\\


**Return Value:** `(labels, positions)::Tuple{Vector{String}`, `Vector{UnfoldMakie.Point{2,Float32}}`}:\\
    - `labels` - vector of channel names.\\
    - `positions` - vector of channel positions.
"""
function UnfoldMakie.example_montage(example = "montage_32")
    if example == "montage_32" || example == "biosemi_32"
        # Channel names
        labels_32 = [
            "Fp1","AF3","F7","F3","FC1","FC5","T7","C3","CP1","CP5","P7","P3",
            "Pz","PO3","O1","Oz","O2","PO4","P4","P8","CP6","CP2","C4","T8",
            "FC6","FC2","F4","F8","AF4","Fp2","Fz","Cz","Nz","LPA","RPA"
            ]
        # Compute positions
        positions_32 = UnfoldMakie.Point{2,Float32}.([
            (-92, -72),
            (-74, -65),
            (-92, -36),
            (-60, -51),
            (-32, -45),
            (-72, -21),
            (-92,   0),
            (-46,   0),
            (-32,  45),
            (-72,  21),
            (-92,  36),
            (-60,  51),
            (46,  -90),
            (-74,  65),
            (-92,  72),
            (92,  -90),
            (92,  -72),
            (74,  -65),
            (60,  -51),
            (92,  -36),
            (72,  -21),
            (32,  -45),
            (46,   0),
            (92,   0),
            (72,   21),
            (32,   45),
            (60,   51),
            (92,   36),
            (74,   65),
            (92,   72),
            (46,   90),
            (0,     0),
            (115,  90),
            (-115,  0),
            (115,   0)
            ])
        return labels_32, positions_32
    elseif example == "biosemi_64" || example == "montage_64"
        # Channel names
        labels_64 = [
            "Fp1","AF7","AF3","F1","F3","F5","F7","FT7","FC5","FC3","FC1",
            "C1","C3","C5","T7","TP7","CP5","CP3","CP1","P1","P3","P5","P7","P9",
            "PO7","PO3","O1","Iz","Oz","POz","Pz","CPz","Fpz","Fp2","AF8","AF4",
            "AFz","Fz","F2","F4","F6","F8","FT8","FC6","FC4","FC2","FCz","Cz",
            "C2","C4","C6","T8","TP8","CP6","CP4","CP2","P2","P4","P6","P8",
            "P10","PO8","PO4","O2",
            ]

        positions_64 = UnfoldMakie.Point{2,Float32}.([
            (-92, -72),
            (-92, -54),
            (-74, -65),
            (-50, -68),
            (-60, -51),
            (-75, -41),
            (-92, -36),
            (-92, -18),
            (-72, -21),
            (-50, -28),
            (-32, -45),
            (-23,   0),
            (-46,   0),
            (-69,   0),
            (-92,   0),
            (-92,  18),
            (-72,  21),
            (-50,  28),
            (-32,  45),
            (-50,  68),
            (-60,  51),
            (-75,  41),
            (-92,  36),
            (-115, 36),
            (-92,  54),
            (-74,  65),
            (-92,  72),
            (115, -90),
            (92,  -90),
            (69,  -90),
            (46,  -90),
            (23,  -90),
            (92,   90),
            (92,   72),
            (92,   54),
            (74,   65),
            (69,   90),
            (46,   90),
            (50,   68),
            (60,   51),
            (75,   41),
            (92,   36),
            (92,   18),
            (72,   21),
            (50,   28),
            (32,   45),
            (23,   90),
            (0,     0),
            (23,    0),
            (46,    0),
            (69,    0),
            (92,    0),
            (92,   -18),
            (72,   -21),
            (50,   -28),
            (32,   -45),
            (50,   -68),
            (60,   -51),
            (75,   -41),
            (92,   -36),
            (115,  -36),
            (92,   -54),
            (74,   -65),
            (92,   -72),
            ])            

        return labels_64, positions_64
    elseif example == "labels_30" || example == "channels_30"
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
