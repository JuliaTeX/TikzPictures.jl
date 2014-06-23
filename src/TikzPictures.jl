module TikzPictures

export TikzPicture, PDF, TEX, SVG, save

type TikzPicture
  data::String
  options::String
  preamble::String
  usePDF2SVG::Bool
  enableWrite18::Bool
  TikzPicture(data::String; options="", preamble="", usePDF2SVG=true, enableWrite18=true) = new(data, options, preamble, usePDF2SVG, enableWrite18)
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
  print(tex, "\\begin{tikzpicture}[")
  print(tex, tp.options)
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
    if tp.enableWrite18
      success(`lualatex --enable-write18 $filename`)
    else
      success(`lualatex $filename`)
    end
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
      if tp.enableWrite18
        success(`lualatex --enable-write18 --output-format=dvi $filename`)
      else
        success(`lualatex --output-format=dvi $filename`)
      end
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

# this is needed to work with multiple images in ijulia (kind of a hack)
global _tikzid = uint32(time() * 10)

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
  rm("$filename.svg")
end

end # module
