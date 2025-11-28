using Requires
export SVGBackend, PdfToSvgBackend, PopplerBackend, DVIBackend, svgBackend

# types of backends that convert PDFs to SVGs
abstract type SVGBackend end
struct PdfToSvgBackend <: SVGBackend end
struct PopplerBackend <: SVGBackend end
struct DVIBackend <: SVGBackend end

# the current backend with a getter and a setter
const _svgBackend = Ref{SVGBackend}()

svgBackend() = _svgBackend[]
function svgBackend(backend::SVGBackend)
    _initialize(backend)
    _svgBackend[] = backend
end

# call this function from __init__
function __init__svg()

    # determine the backend to use
    if Sys.which("pdf2svg") !== nothing
        svgBackend(PdfToSvgBackend())
    else
        try
            svgBackend(PopplerBackend())
        catch cause
            @warn "Failed to load PopplerBackend; falling back on DVIBackend" cause
            svgBackend(DVIBackend())
        end
    end

    # define a new implementation for PopplerBackend, but only after `import Poppler_jll`
    @require Poppler_jll="9c32591e-4766-534b-9725-b71a8799265b" begin
        function _mkTempSvg(backend::PopplerBackend, tp::TikzPicture, temp_dir::AbstractString, temp_filename::AbstractString)
            _mkTempPdf(tp, temp_dir, temp_filename) # convert to PDF and then to SVG
            # convert PDF file in tmpdir to SVG file in tmpdir
            return success(`$(Poppler_jll.pdftocairo()) -svg $(temp_filename).pdf $(temp_filename).svg`)
        end
    end

end

#
# This function is the one used by save(::SVG); produce an SVG file in the temporary directory
#
function _mkTempSvg(tp::TikzPicture, temp_dir::AbstractString, temp_filename::AbstractString)
    backend = svgBackend()
    if !_mkTempSvg(backend, tp, temp_dir, temp_filename)
        if tikzDeleteIntermediate()
            rm(temp_dir, force=true, recursive=true)
        end
        error("$backend failed. Consider using another backend.")
    end # otherwise, everything is fine
end

# backend initialization
_initialize(backend::SVGBackend) = nothing # default
_initialize(backend::PopplerBackend) =
    if !Requires.isprecompiling()
        @eval TikzPictures begin
            try
                import Poppler_jll # will trigger @require in __init__svg
            catch
                error("Unable to import Poppler_jll") # should not happen as long as Poppler_jll is a dependency
            end
        end
    end

# compile a temporary PDF file that can be converted to SVG
function _mkTempPdf(tp::TikzPicture, temp_dir::AbstractString, temp_filename::AbstractString; dvi::Bool=false)
    latexSuccess, texlog = _run(tp, temp_dir, temp_filename; dvi=dvi)
    if occursin("LaTeX Warning: Label(s)", texlog)
        latexSuccess, texlog = _run(tp, temp_filename, temp_dir, dvi=dvi)
    end # second run
    if !latexSuccess
        latexerrormsg(texlog)
        error("LaTeX error")
    end
end

# compile temporary SVGs with different backends
_mkTempSvg(backend::SVGBackend, tp::TikzPicture, temp_dir::AbstractString, temp_filename::AbstractString) =
    return false # always fail

function _mkTempSvg(backend::PdfToSvgBackend, tp::TikzPicture, temp_dir::AbstractString, temp_filename::AbstractString)
    _mkTempPdf(tp, temp_dir, temp_filename) # convert to PDF and then to SVG
    return success(`pdf2svg $(temp_filename).pdf $(temp_filename).svg`)
end

function _mkTempSvg(backend::DVIBackend, tp::TikzPicture, temp_dir::AbstractString, temp_filename::AbstractString)
    _mkTempPdf(tp, temp_dir, temp_filename; dvi=true) # convert to DVI and then to SVG
    cd(temp_dir) do
        return success(`dvisvgm --no-fonts --output=$(basename(temp_filename)*".svg") $(basename(temp_filename)*".dvi")`)
    end
end
