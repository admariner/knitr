#' @include themes.R
#' @include highlight.R

# doc is the output of processed document
insert_header = function(doc) {
  if (is.null(b <- knit_patterns$get('header.begin'))) return(doc)

  if (out_format('html'))
    return(insert_header_html(doc, b))
  if (out_format(c('latex', 'listings', 'sweave')))
    return(insert_header_latex(doc, b))
  doc
}

# Makes latex header with macros required for highlighting, tikz and framed
make_header_latex = function(doc) {
  h = one_string(c(
    header_latex_packages(doc),
    .header.maxwidth, opts_knit$get('header'),
    if (length(grep('\\hlstd', doc, fixed = TRUE))) '\\let\\hlstd\\hldef',
    if (length(grep('\\hlstr', doc, fixed = TRUE))) '\\let\\hlstr\\hlsng',
    if (getOption('OutDec') != '.') '\\usepackage{amsmath}',
    if (out_format('latex')) '\\usepackage{alltt}'
  ))
  if (opts_knit$get('self.contained')) h else {
    write_utf8(h, 'knitr.sty')
    '\\usepackage{knitr}'
  }
}

# if the document already contains \usepackage[options]{pkg}, use the same
# options to avoid the option clash error in LaTeX
use_package = function(pkg, doc) {
  opts = sapply(pkg, function(p) {
    r = sprintf('.*?\\\\usepackage\\[(.+?)]\\{%s}.*', p)
    o = xfun::grep_sub(r, '\\1', doc)
    if (length(o)) return(o[1])
    opts_knit$get(paste0('latex.options.', p)) %n% ''
  })
  sprintf('\\usepackage[%s]{%s}', opts, pkg)
}

# for backward-compatibility, use xcolor package unless the latex.options.color
# has been set; xcolor is preferred: https://github.com/latex3/latex2e/pull/719
header_latex_packages = function(doc) {
  paste(use_package(c('graphicx', 'xcolor'), doc), collapse = '')
}

insert_header_latex = function(doc, b) {
  i = grep(b, doc)
  if (length(i) >= 1L) {
    # it is safer to add usepackage{upquote} before begin{document} than after
    # documentclass{article} because it must appear after usepackage{fontenc};
    # see this weird problem: http://stackoverflow.com/q/12448507/559676
    p = '(?<!%)(\\s*)(\\\\begin\\{document\\})'
    if (!out_format('listings') && length(j <- grep(p, doc, perl = TRUE))) {
      j = j[1]
      doc[j] = sub(p, '\n\\\\IfFileExists{upquote.sty}{\\\\usepackage{upquote}}{}\n\\2', doc[j], perl = TRUE)
    }
    i = i[1L]; l = str_locate(doc[i], b, FALSE)
    doc[i] = str_insert(doc[i], l[, 2], make_header_latex(doc))
  } else if (parent_mode() && !child_mode()) {
    # in parent mode, we fill doc to be a complete document
    doc[1L] = one_string(c(
      getOption('tikzDocumentDeclaration'), make_header_latex(doc),
      .knitEnv$tikzPackages, '\\begin{document}', doc[1L]
    ))
    doc[length(doc)] = one_string(
      c(doc[length(doc)], .knitEnv$bibliography, '\\end{document}')
    )
  }
  doc
}

make_header_html = function() {
  h = opts_knit$get('header')
  h = h[setdiff(names(h), c('tikz', 'framed'))]
  if (opts_knit$get('self.contained')) one_string(c(
    '<style type="text/css">', h[['highlight']], '</style>',
    unlist(h[setdiff(names(h), 'highlight')])
  )) else {
    write_utf8(h, 'knitr.css')
    '<link rel="stylesheet" href="knitr.css" type="text/css" />'
  }
}

insert_header_html = function(doc, b) {
  i = grep(b, doc)
  if (length(i) == 1L) {
    l = str_locate(doc[i], b, FALSE)
    doc[i] = str_insert(doc[i], l[, 2], paste0('\n', make_header_html()))
  }
  doc
}

#' Set the header information
#'
#' Some output documents may need appropriate header information. For example,
#' for LaTeX output, we need to write \samp{\\usepackage{tikz}} into the
#' preamble if we use tikz graphics; this function sets the header information
#' to be written into the output.
#'
#' By default, \pkg{knitr} will set up the header automatically. For example, if
#' the tikz device is used, \pkg{knitr} will add \samp{\\usepackage{tikz}} to
#' the LaTeX preamble, and this is done by setting the header component
#' \code{tikz} to be a character string: \code{set_header(tikz =
#' '\\usepackage{tikz}')}. Similary, when we highlight R code using the
#' \pkg{highlight} package (i.e. the chunk option \code{highlight = TRUE}),
#' \pkg{knitr} will set the \code{highlight} component of the header vector
#' automatically; if the output type is HTML, this component will be different
#' -- instead of LaTeX commands, it contains CSS definitions.
#'
#' For power users, all the components can be modified to adapt to a customized
#' type of output. For instance, we can change \code{highlight} to LaTeX
#' definitions of the \pkg{listings} package (and modify the output hooks
#' accordingly), so we can decorate R code using the \pkg{listings} package.
#' @param ... Header components; currently possible components are
#'   \code{highlight}, \code{tikz} and \code{framed}, which contain the
#'   necessary commands to be used in the HTML header or LaTeX preamble. Note that
#'   HTML output does not use the \code{tikz} and \code{framed} components, since
#'   they do not make sense in the context of HTML.
#' @return The header vector in \code{opts_knit} is set.
#' @export
#' @examples set_header(tikz = '\\usepackage{tikz}')
#' opts_knit$get('header')
set_header = function(...) {
  opts_knit$set(header = merge_list(opts_knit$get('header'), c(...)))
}

.default.sty = inst_dir('themes', 'default.css')
# header for Latex Syntax Highlighting
.header.hi.tex = theme_to_header_latex(.default.sty)$highlight
.knitr.sty = inst_dir('misc', 'knitr.sty')
.header.framed = one_string(read_utf8(.knitr.sty))
# CSS for html syntax highlighting
.header.hi.html = theme_to_header_html(.default.sty)$highlight
rm(list = c('.default.sty', '.knitr.sty')) # do not need them any more

.header.sweave.cmd =
'\\newcommand{\\SweaveOpts}[1]{}  % do not interfere with LaTeX
\\newcommand{\\SweaveInput}[1]{} % because they are not real TeX commands
\\newcommand{\\Sexpr}[1]{}       % will only be parsed by R
'

.header.maxwidth =
'% maxwidth is the original width if it is less than linewidth
% otherwise use linewidth (to make sure the graphics do not exceed the margin)
\\makeatletter
\\def\\maxwidth{ %
  \\ifdim\\Gin@nat@width>\\linewidth
    \\linewidth
  \\else
    \\Gin@nat@width
  \\fi
}
\\makeatother
'
