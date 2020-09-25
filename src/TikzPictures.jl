module TikzPictures

export TikzPicture, PDF, TEX, TIKZ, SVG, save, tikzDeleteIntermediate, tikzCommand, TikzDocument, push!
import Base: push!
import LaTeXStrings: LaTeXString, @L_str, @L_mstr
export LaTeXString, @L_str, @L_mstr

_tikzDeleteIntermediate = true
_tikzCommand = "lualatex"

mutable struct TikzPicture
    data::AbstractString
    options::AbstractString
    preamble::AbstractString
    environment::AbstractString
    width::AbstractString
    height::AbstractString
    keepAspectRatio::Bool
    enableWrite18::Bool
    TikzPicture(data::AbstractString; options="", preamble="", environment="tikzpicture", width="", height="", keepAspectRatio=true, enableWrite18=true) = new(data, options, preamble, environment, width, height, keepAspectRatio, enableWrite18)
end

mutable struct TikzDocument
    pictures::Vector{TikzPicture}
    captions::Vector{AbstractString}
end
TikzDocument() = TikzDocument(TikzPicture[], String[])


# svg handling
include("svg.jl")
__init__() = __init__svg()

tikzUsePoppler() = svgBackend() == PopplerBackend()
tikzUsePoppler(value::Bool) = svgBackend(value ? PopplerBackend() : DVIBackend())

# standalone workaround:
# see http://tex.stackexchange.com/questions/315025/lualatex-texlive-2016-standalone-undefined-control-sequence
_standaloneWorkaround = false

function standaloneWorkaround()
    global _standaloneWorkaround
    _standaloneWorkaround
end

function standaloneWorkaround(value::Bool)
    global _standaloneWorkaround
    _standaloneWorkaround = value
    nothing
end

function tikzDeleteIntermediate(value::Bool)
    global _tikzDeleteIntermediate
    _tikzDeleteIntermediate = value
    nothing
end

function tikzDeleteIntermediate()
    global _tikzDeleteIntermediate
    _tikzDeleteIntermediate
end

function tikzCommand(value::AbstractString)
    global _tikzCommand
    _tikzCommand = value
    nothing
end

function tikzCommand()
    global _tikzCommand
    _tikzCommand
end

function push!(td::TikzDocument, tp::TikzPicture; caption="")
    push!(td.pictures, tp)
    push!(td.captions, caption)
end

function removeExtension(filename::AbstractString, extension::AbstractString)
    if endswith(filename, extension) || endswith(filename, uppercase(extension))
        return filename[1:(end - length(extension))]
    else
        return filename
    end
end

abstract type SaveType end

mutable struct PDF <: SaveType
    filename::AbstractString
    PDF(filename::AbstractString) = new(removeExtension(filename, ".pdf"))
end

mutable struct TEX <: SaveType
    filename::AbstractString
    limit_to::Symbol
    TEX(filename::AbstractString; include_preamble::Bool=true, limit_to::Symbol=(include_preamble ? :all : :picture)) =
        new(removeExtension(filename, ".tex"), limit_to)
end

mutable struct TIKZ <: SaveType
    filename::AbstractString
    limit_to::Symbol
    TIKZ(filename::AbstractString) = new(removeExtension(filename, ".tikz"), :all)
end

mutable struct SVG <: SaveType
    filename::AbstractString
    SVG(filename::AbstractString) = new(removeExtension(filename, ".svg"))
end

extension(f::SaveType) = lowercase(split("$(typeof(f))",".")[end])

resize(tp::TikzPicture) = !isempty(tp.width) || !isempty(tp.height)

function write_adjustbox_options(tex::IO, tp::TikzPicture)
    adjustbox_options = []
    if !isempty(tp.width)
        push!(adjustbox_options, "width=$(tp.width)")
    end
    if !isempty(tp.height)
        push!(adjustbox_options, "height=$(tp.height)")
    end
    if tp.keepAspectRatio
        push!(adjustbox_options, "keepaspectratio")
    end
    adjustbox_option_string = join(adjustbox_options, ',')
    println(tex, "\\begin{adjustbox}{$adjustbox_option_string}")
end


showable(::MIME"image/svg+xml", tp::TikzPicture) = true

function save(f::Union{TEX,TIKZ}, tp::TikzPicture)
    if !in(f.limit_to, [:all, :picture, :data])
        throw(ArgumentError("limit_to must be one of :all, :picture, and :data"))
    end
    filename = f.filename
    ext = extension(f)
    tex = open("$(filename).$(ext)", "w")
    if f.limit_to in [:all, :picture]
        if f.limit_to == :all
            if standaloneWorkaround()
                println(tex, "\\RequirePackage{luatex85}")
            end
            if resize(tp)
                # [tikz] class option has to be moved to a \usepackage
                # https://tex.stackexchange.com/questions/455546/can-i-resize-a-tikz-picture-to-have-certain-dimensions-width-height
                println(tex, "\\documentclass{standalone}")
                println(tex, "\\usepackage{tikz}")
                println(tex, "\\usepackage{adjustbox}")
            else
                println(tex, "\\documentclass[tikz]{standalone}")
            end
            println(tex, tp.preamble)
            println(tex, "\\begin{document}")
        end

        if resize(tp)
            write_adjustbox_options(tex, tp)
        end
        print(tex, "\\begin{$(tp.environment)}[")
        print(tex, tp.options)
        println(tex, "]")
    end
    println(tex, tp.data)
    if f.limit_to in [:all, :picture]
        println(tex, "\\end{$(tp.environment)}")
        if resize(tp)
            println(tex, "\\end{adjustbox}")
        else
            print(tex, "\n")
        end
        if f.limit_to == :all
            println(tex, "\\end{document}")
        end
    end
    close(tex)
end

function save(f::TEX, td::TikzDocument)
    if isempty(td.pictures)
        throw(ArgumentError("TikzDocument does not contain pictures"))
    elseif !in(f.limit_to, [:all, :picture])
        throw(ArgumentError("limit_to must be either :all or :picture"))
    end
    filename = f.filename
    tex = open("$(filename).tex", "w")
    if f.limit_to == :all
        println(tex, "\\documentclass{article}")
        println(tex, "\\usepackage{caption}")
        println(tex, "\\usepackage{tikz}")
        println(tex, td.pictures[1].preamble)
        println(tex, "\\begin{document}")
    end
    println(tex, "\\centering")
    @assert length(td.pictures) == length(td.captions)
    i = 1
    for tp in td.pictures
        println(tex, "\\centering")
        if resize(tp)
            write_adjustbox_options(tex, tp)
        end
        print(tex, "\\begin{$(tp.environment)}[")
        print(tex, tp.options)
        println(tex, "]")
        println(tex, tp.data)
        println(tex, "\\end{$(tp.environment)}")
        if resize(tp)
            println(tex, "\\end{adjustbox}")
        end
        print(tex, "\\captionof{figure}{")
        print(tex, td.captions[i])
        println(tex, "}")
        println(tex, "\\vspace{5ex}")
        println(tex)
        i += 1
    end
    if f.limit_to == :all
        println(tex, "\\end{document}")
    end
    close(tex)
end

function latexerrormsg(s)
    beginError = false
    for l in split(s, '\n')
        if beginError
            if !isempty(l) && l[1] == '?'
                return
            else
                println(l)
            end
        else
            if !isempty(l) && l[1] == '!'
                println(l)
                beginError = true
            end
        end
    end
end

_joinpath(a, b) = "$a/$b"

function save(f::PDF, tp::TikzPicture)

    # Isolate basename and foldername of file
    basefilename = basename(f.filename)
    working_dir = dirname(abspath(f.filename))

    # Call anonymous function to do task and automatically return
    cd(working_dir) do
        temp_dir = mktempdir("./")
        temp_filename = _joinpath(temp_dir,basefilename)

        # Save the TEX file in tmp dir
        save(TEX(temp_filename * ".tex"), tp)

        # From the .tex file, generate a pdf within the tmp folder
        latexCommand = ``
        if tp.enableWrite18
            latexCommand = `$(tikzCommand()) --enable-write18 --output-directory=$(temp_dir) $(temp_filename*".tex")`
        else
            latexCommand = `$(tikzCommand()) --output-directory=$(temp_dir) $(temp_filename*".tex")`
        end

        latexSuccess = success(latexCommand)

        tex_log = ""
        try
            tex_log = read(temp_filename * ".log", String)
        catch
            tex_log = read(_joinpath(temp_dir,"texput.log"), String)
        end

        if occursin("LaTeX Warning: Label(s)", tex_log)
            latexSuccess = success(latexCommand)
        end

        # Move PDF out of tmpdir regardless
        # Give warning if PDF file already exists
        if isfile("$(basefilename).pdf")
            @warn "$(basefilename).pdf already exists, overwriting!"
        end
        if latexSuccess
            mv("$(temp_filename).pdf", "$(basefilename).pdf",force=true)
        end

        try
            # Shouldn't need to be try-catched anymore, but best to be safe
            # This failing is NOT critical either, so just make it a warning
            if tikzDeleteIntermediate()
                # Delete tmp dir
                rm(temp_dir, recursive=true)
            end
        catch
            @warn "TikzPictures: Your intermediate files are not being deleted."
        end

        if !latexSuccess
            # Remove failed attempt.
            if !standaloneWorkaround() && occursin("\\sa@placebox ->\\newpage \\global \\pdfpagewidth", tex_log)
                standaloneWorkaround(true)
                save(f, tp)
                return
            end
            latexerrormsg(tex_log)
            error("LaTeX error")
        end
    end
end


function save(f::PDF, td::TikzDocument)
    # Isolate basename and foldername of file
    basefilename = basename(f.filename)
    working_dir = dirname(abspath(f.filename))

    # Call anonymous function to do task and automatically return
    cd(working_dir) do
        # Create tmp dir in working directory
        temp_dir = mktempdir("./")
        temp_filename = _joinpath(temp_dir,basefilename)

        try
            save(TEX(temp_filename * ".tex"), td)
            if td.pictures[1].enableWrite18
                success(`$(tikzCommand()) --enable-write18 --output-directory=$(temp_dir) $(temp_filename)`)
            else
                success(`$(tikzCommand()) --output-directory=$(temp_dir) $(temp_filename)`)
            end

            # Move PDF out of tmpdir regardless
            if isfile("$(basefilename).pdf")
                @warn "$(basefilename).pdf already exists, overwriting!"
            end
            mv("$(temp_filename).pdf", "$(basefilename).pdf",force=true)

            try
                # Shouldn't need to be try-catched anymore, but best to be safe
                # This failing is NOT critical either, so just make it a warning
                if tikzDeleteIntermediate()
                    # Delete tmp dir
                    rm(temp_dir, recursive=true)
                end
            catch
                @warn "TikzPictures: Your intermediate files are not being deleted."
            end
        catch
            @warn "Error saving as PDF."
            rethrow()
        end
    end
end

function save(f::SVG, tp::TikzPicture)
    basefilename = basename(f.filename)
    working_dir = dirname(abspath(f.filename))

    # Call anonymous function to do task and automatically return
    cd(working_dir) do
        # Create tmp dir in working directory
        temp_dir = mktempdir("./")
        temp_filename = _joinpath(temp_dir,basefilename)

        # Save the TEX file in tmp dir, then convert to SVG
        save(TEX(temp_filename * ".tex"), tp)
        _mkTempSvg(tp, temp_dir, temp_filename)

        # Move SVG out of tmpdir into working dir and give warning if overwriting
        if isfile("$(basefilename).svg")
            @warn "$(basefilename).svg already exists, overwriting!"
        end
        mv("$(temp_filename).svg", "$(basefilename).svg",force=true)

        try
            # Shouldn't need to be try-catched anymore, but best to be safe
            # This failing is NOT critical either, so just make it a warning
            if tikzDeleteIntermediate()
                # Delete tmp dir
                rm(temp_dir, recursive=true)
            end
        catch
            @warn "TikzPictures: Your intermediate files are not being deleted."
        end
    end
end

# this is needed to work with multiple images in ijulia (kind of a hack)
global _tikzid = round(UInt64, time() * 1e6)


function Base.show(f::IO, ::MIME"image/svg+xml", tp::TikzPicture)
    global _tikzid
    filename = "tikzpicture"
    save(SVG(filename), tp)
    s = read("$filename.svg", String)
    s = replace(s, "glyph" => "glyph-$(_tikzid)-")
    s = replace(s, "\"clip" => "\"clip-$(_tikzid)-")
    s = replace(s, "#clip" => "#clip-$(_tikzid)-")
    s = replace(s, "\"image" => "\"image-$(_tikzid)-")
    s = replace(s, "#image" => "#image-$(_tikzid)-")
    s = replace(s, "linearGradient id=\"linear" => "linearGradient id=\"linear-$(_tikzid)-")
    s = replace(s, "#linear" => "#linear-$(_tikzid)-")
    s = replace(s, "image id=\"" => "image style=\"image-rendering: pixelated;\" id=\"")
    _tikzid += 1
    println(f, s)
    if tikzDeleteIntermediate()
        rm("$filename.svg")
    end
end

end # module
