using TikzPictures: PopplerBackend, TikzPicture
using Poppler_jll: pdftocairo

function _mkTempSvg(backend::PopplerBackend, tp::TikzPicture, temp_dir::AbstractString, temp_filename::AbstractString)
    _mkTempPdf(tp, temp_dir, temp_filename) # convert to PDF and then to SVG
    # convert PDF file in tmpdir to SVG file in tmpdir
    return success(`$(pdftocairo()) -svg $(temp_filename).pdf $(temp_filename).svg`)
end
