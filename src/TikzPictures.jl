module TikzPictures

export TikzPicture, PDF, TEX, SVG, save

type TikzPicture
  data::String
  options::String
  preamble::String
  usePDF2SVG::Bool
  TikzPicture(data::String; options="", preamble="", usePDF2SVG=true) = new(data, options, preamble, usePDF2SVG)
end

type PDF
  filename::String
end

type TEX
  filename::String
end

type SVG
  filename::String
end

Base.mimewritable(::MIME"image/svg+xml", tp::TikzPicture) = true

function save(f::TEX, tp::TikzPicture)
  filename = f.filename
  tex = open("$filename", "w")
  println(tex, "\\documentclass[tikz]{standalone}")
  println(tex, tp.preamble)
  println(tex, "\\begin{document}")
  println(tex, "\\begin{tikzpicture}[")
  println(tex, tp.options)
  println(tex, "]")
  println(tex, tp.data)
  println(tex, "\\end{tikzpicture}")
  println(tex, "\\end{document}")
  close(tex)
end

function save(f::PDF, tp::TikzPicture)
  try
    filename = f.filename
    save(TEX(filename * ".tex"), tp)
    success(`lualatex $filename`)
    rm("$filename.tex")
    rm("$filename.aux")
    rm("$filename.log")
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
      rm("$filename.pdf")
    else
      save(TEX("$filename.tex"), tp)
      success(`lualatex --output-format=dvi $filename`)
      success(`dvisvgm --no-fonts $filename`)
      rm("$filename.tex")
      rm("$filename.aux")
      rm("$filename.dvi")
      rm("$filename.log")
    end
  catch
    error("Error saving as SVG")
  end
end

function Base.writemime(f::IO, ::MIME"image/svg+xml", tp::TikzPicture)
  filename = "tikzpicture"
  save(SVG(filename), tp)
  s = readall("$filename.svg")
  println(f, s)
  rm("$filename.svg")
end

end # module
