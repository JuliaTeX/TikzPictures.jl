module TikzPictures

export TikzPicture, PDF, TEX, SVG, save, tikzDeleteIntermediate, TikzDocument, push!
import Base: push!
import LaTeXStrings: LaTeXString, @L_str, @L_mstr
export LaTeXString, @L_str, @L_mstr

_tikzDeleteIntermediate = true

function tikzDeleteIntermediate(value::Bool)
  global _tikzDeleteIntermediate
  _tikzDeleteIntermediate = value
  nothing
end

function tikzDeleteIntermediate()
  global _tikzDeleteIntermediate
  _tikzDeleteIntermediate
end

type TikzPicture
  data::String
  options::String
  preamble::String
  usePDF2SVG::Bool
  enableWrite18::Bool
  TikzPicture(data::String; options="", preamble="", usePDF2SVG=true, enableWrite18=true) = new(data, options, preamble, usePDF2SVG, enableWrite18)
end

type TikzDocument
  pictures::Vector{TikzPicture}
  captions::Vector{ASCIIString}
end

TikzDocument() = TikzDocument(TikzPicture[], ASCIIString[])

function push!(td::TikzDocument, tp::TikzPicture; caption="")
  push!(td.pictures, tp)
  push!(td.captions, caption)
end

function removeExtension(filename::String, extension::String)
  if endswith(filename, extension) || endswith(filename, uppercase(extension))
    return filename[1:(end - length(extension))]
  else
    return filename
  end
end

type PDF
  filename::String
  PDF(filename::String) = new(removeExtension(filename, ".pdf"))
end

type TEX
  filename::String
  TEX(filename::String) = new(removeExtension(filename, ".tex"))
end

type SVG
  filename::String
  SVG(filename::String) = new(removeExtension(filename, ".svg"))
end

Base.mimewritable(::MIME"image/svg+xml", tp::TikzPicture) = true

function save(f::TEX, tp::TikzPicture)
  filename = f.filename
  tex = open("$(filename).tex", "w")
  println(tex, "\\documentclass[tikz]{standalone}")
  println(tex, tp.preamble)
  println(tex, "\\begin{document}")
  print(tex, "\\begin{tikzpicture}[")
  print(tex, tp.options)
  println(tex, "]")
  println(tex, tp.data)
  println(tex, "\\end{tikzpicture}")
  println(tex, "\\end{document}")
  close(tex)
end

function save(f::TEX, td::TikzDocument)
  if isempty(td.pictures)
    error("TikzDocument does not contain pictures")
  end
  filename = f.filename
  tex = open("$(filename).tex", "w")
  println(tex, "\\documentclass{article}")
  println(tex, "\\usepackage{caption}")
  println(tex, "\\usepackage{tikz}")
  println(tex, td.pictures[1].preamble)
  println(tex, "\\begin{document}")
  println(tex, "\\centering")
  @assert length(td.pictures) == length(td.captions)
  i = 1
  for tp in td.pictures
    println(tex, "\\centering")
    print(tex, "\\begin{tikzpicture}[")
    print(tex, tp.options)
    println(tex, "]")
    println(tex, tp.data)
    println(tex, "\\end{tikzpicture}")
    print(tex, "\\captionof{figure}{")
    print(tex, td.captions[i])
    println(tex, "}")
    println(tex, "\\vspace{5ex}")
    println(tex)
    i += 1
  end
  println(tex, "\\end{document}")
  close(tex)
end

function save(f::PDF, tp::TikzPicture)
  try
    filename = f.filename
    save(TEX(filename * ".tex"), tp)
    if tp.enableWrite18
      success(`lualatex --enable-write18 $filename`)
    else
      success(`lualatex $filename`)
    end
    if tikzDeleteIntermediate()
      rm("$filename.tex")
      rm("$filename.aux")
      rm("$filename.log")
    end
  catch
    error("Error saving as PDF.")
  end
end

function save(f::PDF, td::TikzDocument)
  if isempty(td.pictures)
    error("TikzDocument does not contain pictures")
  end
  try
    filename = f.filename
    save(TEX(filename * ".tex"), td)
    if td.pictures[1].enableWrite18
      success(`lualatex --enable-write18 $filename`)
    else
      success(`lualatex $filename`)
    end
    if tikzDeleteIntermediate()
      rm("$filename.tex")
      rm("$filename.aux")
      rm("$filename.log")
    end
  catch
    error("Error saving as PDF.")
  end
end


function save(f::SVG, tp::TikzPicture)
  try
    filename = f.filename
    if tp.usePDF2SVG
      save(PDF(filename), tp)
      success(`pdf2svg $filename.pdf $filename.svg`)
      if tikzDeleteIntermediate()
        rm("$filename.pdf")
      end
    else
      save(TEX("$filename.tex"), tp)
      if tp.enableWrite18
        success(`lualatex --enable-write18 --output-format=dvi $filename`)
      else
        success(`lualatex --output-format=dvi $filename`)
      end
      success(`dvisvgm --no-fonts $filename`)
      if tikzDeleteIntermediate()
        rm("$filename.tex")
        rm("$filename.aux")
        rm("$filename.dvi")
        rm("$filename.log")
      end
    end
  catch
    error("Error saving as SVG")
  end
end

# this is needed to work with multiple images in ijulia (kind of a hack)
global _tikzid = uint(iround(time() * 10))

function Base.writemime(f::IO, ::MIME"image/svg+xml", tp::TikzPicture)
  global _tikzid
  filename = "tikzpicture"
  save(SVG(filename), tp)
  s = readall("$filename.svg")
  s = replace(s, "glyph", "glyph-$(_tikzid)-")
  s = replace(s, "clip", "clip-$(_tikzid)-")
  s = replace(s, "\"image", "\"image-$(_tikzid)-")
  s = replace(s, "#image", "#image-$(_tikzid)-")
  _tikzid += 1
  println(f, s)
  if tikzDeleteIntermediate()
    rm("$filename.svg")
  end
end

end # module
