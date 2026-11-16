# Canonical text exports for selectable region geometry.

function svg_polygon_line(region; stroke_width = 0.9, fill = "white", stroke = "black")
    length(region.polygon) < 3 && return ""
    return @sprintf(
        "<polygon points=\"%s\" data-region=\"%s\" fill=\"%s\" stroke=\"%s\" stroke-width=\"%.2f\" />",
        region.points,
        region.label,
        fill,
        stroke,
        stroke_width,
    )
end

function socsi_svg_text(layout::RegionLayout64, cfg::RegionGrid64Config)
    width, height = cfg.canvas_size
    lines = [
        @sprintf("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 %d %d\">", width, height),
    ]
    append!(
        lines,
        [
            "  " * line for
            line in (svg_polygon_line(region; stroke_width = cfg.stroke_width) for region in layout.regions) if
            !isempty(line)
        ],
    )
    push!(lines, "</svg>")
    return join(lines, "\n")
end

function php_svg_function_text(svg::AbstractString, function_name::AbstractString)
    php_svg = replace(svg, "\\" => "\\\\", "'" => "\\'")
    return join(
        [
            "<?php",
            "",
            "function $(function_name)() {",
            "    return '$php_svg';",
            "}",
        ],
        "\n",
    )
end

function php_svg_function_text(layout::RegionLayout64, cfg::RegionGrid64Config)
    return php_svg_function_text(socsi_svg_text(layout, cfg), cfg.php_function_name)
end
