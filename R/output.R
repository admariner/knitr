#' Knit a document
#'
#' This function takes an input file, extracts the R code in it according to a
#' list of patterns, evaluates the code and writes the output in another file.
#' It can also tangle R source code from the input document (\code{purl()} is a
#' wrapper to \code{knit(..., tangle = TRUE)}). The \code{knitr.purl.inline}
#' option can be used to also tangle the code of inline expressions (disabled by
#' default).
#'
#' For most of the time, it is not necessary to set any options outside the
#' input document; in other words, a single call like
#' \code{knit('my_input.Rnw')} is usually enough. This function will try to
#' determine many internal settings automatically. For the sake of
#' reproducibility, it is better practice to include the options inside the
#' input document (to be self-contained), instead of setting them before
#' knitting the document.
#'
#' First the filename of the output document is determined in this way:
#' \file{foo.Rnw} generates \file{foo.tex}, and other filename extensions like
#' \file{.Rtex}, \file{.Rhtml} (\file{.Rhtm}) and \file{.Rmd}
#' (\file{.Rmarkdown}) will generate \file{.tex}, \file{.html} and \file{.md}
#' respectively. For other types of files, if the filename contains
#' \samp{_knit_}, this part will be removed in the output file, e.g.,
#' \file{foo_knit_.html} creates the output \file{foo.html}; if \samp{_knit_} is
#' not found in the filename, \file{foo.ext} will produce \file{foo.txt} if
#' \code{ext} is not \code{txt}, otherwise the output is \file{foo-out.txt}. If
#' \code{tangle = TRUE}, \file{foo.ext} generates an R script \file{foo.R}.
#'
#' We need a set of syntax to identify special markups for R code chunks and R
#' options, etc. The syntax is defined in a pattern list. All built-in pattern
#' lists can be found in \code{all_patterns} (call it \code{apat}). First
#' \pkg{knitr} will try to decide the pattern list based on the filename
#' extension of the input document, e.g. \samp{Rnw} files use the list
#' \code{apat$rnw}, \samp{tex} uses the list \code{apat$tex}, \samp{brew} uses
#' \code{apat$brew} and HTML files use \code{apat$html}; for unkown extensions,
#' the content of the input document is matched against all pattern lists to
#' automatically determine which pattern list is being used. You can also
#' manually set the pattern list using the \code{\link{knit_patterns}} object or
#' the \code{\link{pat_rnw}} series functions in advance and \pkg{knitr} will
#' respect the setting.
#'
#' According to the output format (\code{opts_knit$get('out.format')}), a set of
#' output hooks will be set to mark up results from R (see
#' \code{\link{render_latex}}). The output format can be LaTeX, Sweave and HTML,
#' etc. The output hooks decide how to mark up the results (you can customize
#' the hooks).
#'
#' The name \code{knit} comes from its counterpart \samp{weave} (as in Sweave),
#' and the name \code{purl} (as \samp{tangle} in Stangle) comes from a knitting
#' method `knit one, purl one'.
#'
#' If the input document has child documents, they will also be compiled
#' recursively. See \code{\link{knit_child}}.
#'
#' See the package website and manuals in the references to know more about
#' \pkg{knitr}, including the full documentation of chunk options and demos,
#' etc.
#' @param input Path to the input file.
#' @param output Path to the output file for \code{knit()}. If \code{NULL}, this
#'   function will try to guess a default, which will be under the current
#'   working directory.
#' @param tangle Boolean; whether to tangle the R code from the input file (like
#'   \code{utils::\link{Stangle}}).
#' @param text A character vector. This is an alternative way to provide the
#'   input file.
#' @param quiet Boolean; suppress the progress bar and messages?
#' @param envir Environment in which code chunks are to be evaluated, for
#'   example, \code{\link{parent.frame}()}, \code{\link{new.env}()}, or
#'   \code{\link{globalenv}()}).
#' @param encoding Encoding of the input file; always assumed to be UTF-8 (i.e.,
#'   this argument is effectively ignored).
#' @return The compiled document is written into the output file, and the path
#'   of the output file is returned. If the \code{text} argument is not
#'   \code{NULL}, the compiled output is returned as a character vector. In
#'   other words, if you provide a file input, you get an output filename; if
#'   you provide a character vector input, you get a character vector output.
#' @note The working directory when evaluating R code chunks is the directory of
#'   the input document by default, so if the R code involves external files
#'   (like \code{read.table()}), it is better to put these files under the same
#'   directory of the input document so that we can use relative paths. However,
#'   it is possible to change this directory with the package option
#'   \code{\link{opts_knit}$set(root.dir = ...)} so all paths in code chunks are
#'   relative to this \code{root.dir}. It is not recommended to change the
#'   working directory via \code{\link{setwd}()} in a code chunk, because it may
#'   lead to terrible consequences (e.g. figure and cache files may be written
#'   to wrong places). If you do use \code{setwd()}, please note that
#'   \pkg{knitr} will always restore the working directory to the original one.
#'   Whenever you feel confused, print \code{getwd()} in a code chunk to see
#'   what the working directory really is.
#'
#'   If the \code{output} argument is a file path, it is strongly recommended to
#'   be in the current working directory (e.g. \file{foo.tex} instead of
#'   \file{somewhere/foo.tex}), especially when the output has external
#'   dependencies such as figure files. If you want to write the output to a
#'   different directory, it is recommended to set the working directory to that
#'   directory before you knit a document. For example, if the source document
#'   is \file{foo.Rmd} and the expected output is \file{out/foo.md}, you can
#'   write \code{setwd('out/'); knit('../foo.Rmd')} instead of
#'   \code{knit('foo.Rmd', 'out/foo.md')}.
#'
#'   N.B. There is no guarantee that the R script generated by \code{purl()} can
#'   reproduce the computation done in \code{knit()}. The \code{knit()} process
#'   can be fairly complicated (special values for chunk options, custom chunk
#'   hooks, computing engines besides R, and the \code{envir} argument, etc). If
#'   you want to reproduce the computation in a report generated by
#'   \code{knit()}, be sure to use \code{knit()}, instead of merely executing
#'   the R script generated by \code{purl()}. This seems to be obvious, but some
#'   people
#'   \href{https://stat.ethz.ch/pipermail/r-devel/2014-May/069113.html}{do not
#'   get it}.
#' @export
#' @references Package homepage: \url{https://yihui.org/knitr/}. The \pkg{knitr}
#'   \href{https://yihui.org/knitr/demo/manual/}{main manual}: and
#'   \href{https://yihui.org/knitr/demo/graphics/}{graphics manual}.
#'
#'   See \code{citation('knitr')} for the citation information.
#' @examples library(knitr)
#' (f = system.file('examples', 'knitr-minimal.Rnw', package = 'knitr'))
#' knit(f)  # compile to tex
#'
#' purl(f)  # tangle R code
#' purl(f, documentation = 0)  # extract R code only
#' purl(f, documentation = 2)  # also include documentation
#'
#' unlink(c('knitr-minimal.tex', 'knitr-minimal.R', 'figure'), recursive = TRUE)
knit = function(
  input, output = NULL, tangle = FALSE, text = NULL, quiet = FALSE,
  envir = parent.frame(), encoding = 'UTF-8'
) {

  in.file = !missing(input) && is.character(input)  # is input provided?
  oconc = knit_concord$get(); on.exit(knit_concord$set(oconc), add = TRUE)

  if (child_mode()) {
    setwd(opts_knit$get('output.dir') %n% '.') # always restore original working dir
    # in child mode, input path needs to be adjusted
    if (in.file && !is_abs_path(input)) {
      input = paste0(opts_knit$get('child.path'), input)
      input = file.path(input_dir(), input)
    }
    # respect the quiet argument in child mode (#741)
    optk = opts_knit$get(); on.exit(opts_knit$restore(optk), add = TRUE)
    opts_knit$set(progress = opts_knit$get('progress') && !quiet)
    quiet = !opts_knit$get('progress')
  } else {
    knit_log$restore()
    on.exit(chunk_counter(reset = TRUE), add = TRUE) # restore counter
    adjust_opts_knit()
    # turn off fancy quotes, use a null pdf device to record graphics
    oopts = options(
      useFancyQuotes = FALSE, device = pdf_null, knitr.in.progress = TRUE
    )
    on.exit(options(oopts), add = TRUE)
    # restore objects like chunk options after parent exits
    opta = list(opts_chunk, opts_current, knit_code, opts_knit)
    optv = lapply(opta, function(o) o$get())
    on.exit(for (i in seq_along(opta)) opta[[i]]$restore(optv[[i]]), add = TRUE)
    opts_knit$set(
      output.dir = getwd(),  # record working directory in 1st run
      tangle = tangle, progress = opts_knit$get('progress') && !quiet
    )
  }
  # store the evaluation environment and restore on exit
  oenvir = .knitEnv$knit_global; .knitEnv$knit_global = envir
  on.exit({.knitEnv$knit_global = oenvir}, add = TRUE)

  ext = 'unknown'
  if (in.file) {
    input.dir = .knitEnv$input.dir; on.exit({.knitEnv$input.dir = input.dir}, add = TRUE)
    .knitEnv$input.dir = dirname(input) # record input dir
    ext = tolower(file_ext(input))
    if ((is.null(output) || is.na(output)) && !child_mode())
      output = basename(auto_out_name(input, ext))
    # do not run purl() when the output is newer than input (the output might
    # have been generated by hook_purl)
    if (is.character(output) && !child_mode()) {
      out.purl = with_ext(input, 'R')
      if (xfun::same_path(output, out.purl) && tangle && file_test('-nt', out.purl, input))
        return(out.purl)
      otangle = .knitEnv$tangle.file  # the tangled R script
      .knitEnv$tangle.file = normalizePath(out.purl, mustWork = FALSE)
      .knitEnv$tangle.start = FALSE
      on.exit({.knitEnv$tangle.file = otangle; .knitEnv$tangle.start = NULL}, add = TRUE)
    }
    if (is.null(getOption('tikzMetricsDictionary'))) {
      options(tikzMetricsDictionary = tikz_dict(input)) # cache tikz dictionary
      on.exit(options(tikzMetricsDictionary = NULL), add = TRUE)
    }
    knit_concord$set(infile = input, outfile = output)
  }

  # we need some special treatment for chunks in Quarto document
  .knitEnv$is_quarto = !is.null(opts_knit$get('quarto.version')) || ext == 'qmd'

  text = if (is.null(text)) xfun::read_utf8(input) else split_lines(text)
  if (!length(text)) {
    if (is.character(output)) file.create(output)
    return(output) # a trivial case: create an empty file and exit
  }

  apat = all_patterns; opat = knit_patterns$get()
  on.exit(knit_patterns$restore(opat), add = TRUE)
  if (length(opat) == 0 || all(vapply(opat, is.null, logical(1)))) {
    # use ext if cannot auto detect pattern
    if (is.null(pattern <- detect_pattern(text, ext))) {
      # nothing to be executed; just return original input
      if (is.null(output)) {
        return(if (tangle) '' else one_string(text))
      } else {
        write_utf8(if (tangle) '' else text, output)
        return(output)
      }
    }
    if (!(pattern %in% names(apat))) stop(
      "a pattern list cannot be automatically found for the file extension '",
      ext, "' in built-in pattern lists; ",
      'see ?knit_patterns on how to set up customized patterns'
    )
    set_pattern(pattern)
    if (pattern == 'rnw' && length(sweave_lines <- which_sweave(text)) > 0)
      remind_sweave(if (in.file) input, sweave_lines)
    opts_knit$set(out.format = switch(
      pattern, rnw = 'latex', tex = 'latex', html = 'html', md = 'markdown',
      rst = 'rst', brew = 'brew', asciidoc = 'asciidoc', textile = 'textile'
    ))
  }

  if (is.null(out_format())) auto_format(ext)

  params = NULL  # the params field from YAML
  if (out_format('markdown')) {
    if (child_mode()) {
      # in child mode, strip off the YAML metadata in Markdown if exists
      if (grepl('^---\\s*$', text[1])) {
        i = grep('^---\\s*$', text)
        if (length(i) >= 2) text[1:i[2]] = ''
      }
    } else {
      params = knit_params(text)
      params = if (length(params))
        c('params <-', capture.output(dput(flatten_params(params), '')), '')
      .knitEnv$tangle.params = params  # for hook_purl()
    }
  }
  # change output hooks only if they are not set beforehand
  if (identical(knit_hooks$get(names(.default.hooks)), .default.hooks) && !child_mode()) {
    getFromNamespace(paste('render', out_format(), sep = '_'), 'knitr')()
    on.exit(knit_hooks$set(.default.hooks), add = TRUE)
  }

  progress = opts_knit$get('progress')
  if (in.file && !quiet) message(ifelse(progress, '\n\n', ''), 'processing file: ', input)
  res = process_file(text, output)
  res = one_string(knit_hooks$get('document')(res))
  if (tangle) res = c(params, res)
  if (!is.null(output)) write_utf8(res, output)
  if (!child_mode()) {
    dep_list$restore()  # empty dependency list
    .knitEnv$labels = NULL
  }

  if (in.file && is.character(output) && file.exists(output)) {
    concord_gen(input, output)
    if (!quiet) message('output file: ', output, ifelse(progress, '\n', ''))
  }

  output %n% res
}
#' @rdname knit
#' @param documentation An integer specifying the level of documentation to add to
#'   the tangled script. \code{0} means to output pure code, discarding all text chunks);
#'   \code{1} (the default) means to add the chunk headers to the code; \code{2} means to
#'   add all text chunks to code as roxygen comments.
#' @param ... arguments passed to \code{\link{knit}()} from \code{purl()}
#' @export
purl = function(..., documentation = 1L) {
  doc = opts_knit$get('documentation'); on.exit(opts_knit$set(documentation = doc))
  opts_knit$set(documentation = documentation)
  knit(..., tangle = TRUE)
}

process_file = function(text, output) {
  groups = split_file(lines = text)
  n = length(groups); res = character(n)
  tangle = opts_knit$get('tangle')

  # when in R CMD check, turn off the progress bar (R-exts said the progress bar
  # was not appropriate for non-interactive mode, and I don't want to argue)
  progress = opts_knit$get('progress') && !is_R_CMD_check()
  labels = unlist(lapply(groups, function(g) {
    if (is.list(g$params)) g[[c('params', 'label')]] else ''
  }))
  if (progress) {
    pb_fun = getOption('knitr.progress.fun', txt_pb)
    pb = if (is.function(pb_fun)) pb_fun(n, labels)
    on.exit(if (is.function(pb$done)) pb$done(), add = TRUE)
  }
  wd = getwd()
  for (i in 1:n) {
    if (!is.null(.knitEnv$terminate)) {
      if (!child_mode() || !.knitEnv$terminate_fully) {
        # reset the internal variable `terminate` in the top parent
        res[i] = one_string(.knitEnv$terminate)
        knit_exit(NULL, NULL)
      }
      break  # must have called knit_exit(), so exit early
    }
    if (progress && is.function(pb$update)) pb$update(i)
    group = groups[[i]]
    knit_concord$set(block = i)
    error = NULL
    res[i] = xfun:::handle_error(
      with_options(
        withCallingHandlers(
          if (tangle) process_tangle(group) else process_group(group),
          error = function(e) {
            if (progress && is.function(pb$interrupt)) pb$interrupt()
            if (is_R_CMD_build() || is_R_CMD_check()) error <<- format(e)
          }
        ),
        list(rlang_trace_top_env = knit_global())
      ),
      function(loc) {
        setwd(wd)
        write_utf8(res, output %n% stdout())
        paste0(
          '\nQuitting from ', loc,
          if (!is.null(error)) paste0('\n', rule(), error, '\n', rule())
        )
      },
      if (labels[i] != '') sprintf(' [%s]', labels[i]), get_loc
    )
    knit_concord$set(offset = NULL)
  }

  if (!tangle) res = insert_header(res)  # insert header
  # output line numbers
  if (concord_mode()) knit_concord$set(outlines = line_count(res))
  print_knitlog()
  if (tangle) res = strip_white(res)

  res
}

rule = function() {
  # Used by pkgbuild; please don't change without letting us know
  paste0(strrep('~', getOption('width')), '\n')
}

# return a string to point out the current location in the doc
get_loc = function(label = '') {
  paste0(knit_concord$get('infile'), ':', current_lines(), label)
}

auto_out_name = function(input, ext = tolower(file_ext(input))) {
  base = sans_ext(input)
  name = if (opts_knit$get('tangle')) c(base, '.R') else
    if (ext %in% c('rnw', 'snw')) c(base, '.tex') else
      if (ext %in% c('rmd', 'rmarkdown', 'qmd', 'rhtml', 'rhtm', 'rtex', 'stex', 'rrst', 'rtextile'))
        c(base, '.', substring(ext, 2L)) else
          if (grepl('_knit_', input)) sub('_knit_', '', input) else
            if (ext != 'txt') c(base, '.txt') else c(base, '-out.', ext)
  paste(name, collapse = '')
}

# determine output format based on file extension
ext2fmt = c(
  rnw = 'latex', snw = 'latex', tex = 'latex', rtex = 'latex', stex = 'latex',
  htm = 'html', html = 'html', rhtml = 'html', rhtm = 'html',
  md = 'markdown', markdown = 'markdown', rmd = 'markdown', rmarkdown = 'markdown',
  qmd = 'markdown', brew = 'brew', rst = 'rst', rrst = 'rst'
)

auto_format = function(ext) {
  fmt = ext2fmt[ext]
  if (is.na(fmt)) fmt = {
    warning('cannot automatically decide the output format')
    'unknown'
  }
  opts_knit$set(out.format = fmt)
  invisible(fmt)
}

#' Knit a child document
#'
#' This function knits a child document and returns a character string to input
#' the result into the main document. It is designed to be used in the chunk
#' option \code{child} and serves as the alternative to the
#' \command{SweaveInput} command in Sweave.
#' @param ... Arguments passed to \code{\link{knit}}.
#' @param options A list of chunk options to be used as global options inside
#'   the child document. When one uses the \code{child}
#'   option in a parent chunk, the chunk options of the parent chunk will be
#'   passed to the \code{options} argument here.  Ignored if not a list.
#' @inheritParams knit
#' @return A character string of the content of the compiled child document is
#'   returned as a character string so it can be written back to the parent
#'   document directly.
#' @references \url{https://yihui.org/knitr/demo/child/}
#' @note This function is not supposed be called directly like
#'   \code{\link{knit}()}; instead it must be placed in a parent document to let
#'   \code{\link{knit}()} call it indirectly.
#'
#'   The path of the child document is determined relative to the parent document.
#' @export
#' @examples # you can write \Sexpr{knit_child('child-doc.Rnw')} in an Rnw file 'main.Rnw'
#' # to input results from child-doc.Rnw in main.tex
#'
#' # comment out the child doc by \Sexpr{knit_child('child-doc.Rnw', eval = FALSE)}
knit_child = function(..., options = NULL, envir = knit_global()) {
  child = child_mode()
  opts_knit$set(child = TRUE) # yes, in child mode now
  on.exit(opts_knit$set(child = child)) # restore child status
  if (is.list(options)) {
    options$label = options$child = NULL  # do not need to pass the parent label on
    if (length(options)) {
      optc = opts_chunk$get(names(options), drop = FALSE); opts_chunk$set(options)
      # if user did not touch opts_chunk$set() in child, restore the chunk option
      on.exit({
        for (i in names(options)) if (identical(options[[i]], opts_chunk$get(i)))
          opts_chunk$set(optc[i])
      }, add = TRUE)
    }
  }
  res = knit(..., tangle = opts_knit$get('tangle'), envir = envir)
  one_string(c('', res))
}

#' Exit knitting early
#'
#' Sometimes we may want to exit the knitting process early, and completely
#' ignore the rest of the document. This function provides a mechanism to
#' terminate \code{\link{knit}()}.
#' @param append A character vector to be appended to the results from
#'   \code{knit()} so far. By default, this is \samp{\end{document}} for LaTeX
#'   output, and \samp{</body></html>} for HTML output, to make the output
#'   document complete. For other types of output, it is an empty string.
#' @param fully Whether to fully exit the knitting process if \code{knit_exit()}
#'   is called from a child document. If \code{FALSE}, only exit the knitting
#'   process of the child document.
#' @return Invisible \code{NULL}. An internal signal is set up (as a side
#'   effect) to notify \code{knit()} to quit as if it had reached the end of the
#'   document.
#' @export
#' @examples # see https://github.com/yihui/knitr-examples/blob/master/096-knit-exit.Rmd
knit_exit = function(append, fully = TRUE) {
  if (missing(append)) append = if (out_format(c('latex', 'sweave', 'listings')))
    '\\end{document}' else if (out_format('html')) '</body>\n</html>' else ''
  .knitEnv$terminate = append # use this terminate variable to notify knit()
  .knitEnv$terminate_fully = fully
  invisible()
}

knit_log = new_defaults()  # knitr log for errors, warnings and messages

#' Wrap evaluated results for output
#'
#' This function is mainly for internal use: it is called on each part of the
#' output of the code chunk (code, messages, text output, and plots, etc.) after
#' all statements in the code chunk have been evaluated, and will sew these
#' pieces of output together into a character vector.
#' @param x Output from \code{evaluate::\link[evaluate]{evaluate}()}.
#' @param options A list of chunk options used to control output.
#' @param ... Other arguments to pass to methods.
#' @export
sew = function(x, options = list(), ...) {
  UseMethod('sew', x)
}

#' @export
sew.list = function(x, options = list(), ...) {
  if (length(x) == 0L) return(x)
  lapply(x, sew, options, ...)
}

# ignore unknown classes
#' @export
sew.default = function(x, options, ...) return()

#' @export
sew.character = function(x, options, ...) {
  if (options$results == 'hide') return()
  if (output_asis(x, options)) {
    if (!out_format('latex')) return(x)  # latex output still need a tweak
  } else x = comment_out(x, options$comment)
  knit_hooks$get('output')(x, options)
}

asis_token = '<!-- KNITR_ASIS_OUTPUT_TOKEN -->'
wrap_asis = function(x, options) {
  # do nothing when inside quarto as it is not needed
  # https://github.com/yihui/knitr/pull/2212#pullrequestreview-1292924523
  if (is_quarto()) return(x)

  x = as.character(x)
  if ((n <- length(x)) == 0 || !out_format('markdown') || missing(options) || !isTRUE(options$collapse))
    return(x)
  x[1] = paste0(asis_token, x[1])
  x[n] = paste0(x[n], asis_token)
  x
}

# If you provide a custom print function that returns a character object of
# class 'knit_asis', it will be written as is.
#' @export
sew.knit_asis = function(x, options, inline = FALSE, ...) {
  m = attr(x, 'knit_meta')
  knit_meta_add(m, if (missing(options)) '' else options$label)
  if (!missing(options)) {
    if (options$cache > 0 && isFALSE(attr(x, 'knit_cacheable'))) stop(
      "The code chunk '", options$label, "' is not cacheable; ",
      "please use the chunk option cache=FALSE on this chunk"
    )
    # store metadata in an object named of the form .hash_meta when cache=TRUE
    if (length(m) && options$cache == 3)
      assign(cache_meta_name(options$hash), m, envir = knit_global())
    if (inherits(x, 'knit_asis_htmlwidget')) {
      options$fig.cur = plot_counter()
      options = reduce_plot_opts(options)
      # TODO: remove this when quarto > 1.3.353 is widely used
      if (is_quarto()) return(add_html_caption(options, wrap_asis(x, options)))
      # look for attribute 'aria-labelledby="label"' in the first HTML tag and
      # use the label to provide alt text if found
      return(add_html_caption(
        options, wrap_asis(x, options),
        xfun::grep_sub('^[^<]*<[^>]+aria-labelledby[ ]*=[ ]*"([^"]+)".*$', '\\1', x)
      ))
    }
  }
  x = wrap_asis(x, options)
  if (inline) return(x)
  options$results = 'asis'
  knit_hooks$get('output')(x, options)
}

#' @export
sew.source = function(x, options, ...) {
  if (isFALSE(options$echo)) return()
  src = sub('\n$', '', x$src)
  if (options$strip.white) src = strip_white(src)
  if (is_blank(src)) return()  # an empty chunk
  knit_hooks$get('source')(src, options)
}

msg_wrap = function(message, type, options) {
  # when the output format is LaTeX, do not wrap messages (let LaTeX deal with wrapping)
  if (!length(grep('\n', message)) && !out_format(c('latex', 'listings', 'sweave')))
    message = xfun::str_wrap(message, width = getOption('width'))
  knit_log$set(setNames(
    list(c(knit_log$get(type), paste0('Chunk ', options$label, ':\n  ', message))),
    type
  ))
  message = msg_sanitize(message, type)
  knit_hooks$get(type)(comment_out(message, options$comment), options)
}

# set options(knitr.sanitize.errors = TRUE) to hide error messages, etc
msg_sanitize = function(message, type) {
  type = match.arg(type, c('error', 'warning', 'message'))
  opt = getOption(sprintf('knitr.sanitize.%ss', type), FALSE)
  if (isTRUE(opt)) message = switch(
    type, error = 'An error occurred', warning = 'A warning was emitted',
    message = 'A message was emitted'
  ) else if (is.character(opt)) message = opt
  message
}

#' @export
sew.warning = function(x, options, ...) {
  call = if (is.null(x$call)) '' else {
    call = deparse(x$call)[1]
    if (call == 'eval(expr, envir, enclos)') '' else paste(' in', call)
  }
  msg_wrap(sprintf('Warning%s: %s', call, conditionMessage(x)), 'warning', options)
}

#' @export
sew.message = function(x, options, ...) {
  msg_wrap(paste(conditionMessage(x), collapse = ''), 'message', options)
}

#' @export
sew.error = function(x, options, ...) {
  msg_wrap(as.character(x), 'error', options)
}

#' @export
sew.recordedplot = function(x, options, ...) {
  # figure number sequence for multiple plots
  fig.cur = plot_counter()
  options$fig.cur = fig.cur # put fig num in options
  name = fig_path('', options, number = fig.cur)
  in_base_dir(
    # automatically creates dir for plots
    if (!file_test('-d', dirname(name)))
      dir.create(dirname(name), recursive = TRUE)
  )
  # vectorize over dev, ext and dpi: save multiple versions of the plot
  files = mapply(
    save_plot, width = options$fig.width, height = options$fig.height,
    dev = options$dev, ext = options$fig.ext, dpi = options$dpi,
    MoreArgs = list(plot = x, name = name, options = options), SIMPLIFY = FALSE
  )
  opts_knit$append(plot_files = unlist(files))
  if (options$fig.show == 'hide') return('')
  in_base_dir(run_hook_plot(files[[1]], reduce_plot_opts(options)))
}

#' @export
sew.knit_image_paths = function(x, options = opts_chunk$get(), inline = FALSE, ...) {
  if (options$fig.show == 'hide') return('')
  # remove the automatically set out.width when fig.retina is set, otherwise the
  # size of external images embedded via include_graphics() will be set to
  # fig.width * dpi in fix_options()
  if (is.numeric(r <- options$fig.retina)) {
    w1 = options$out.width
    w2 = options$fig.width * options$dpi / r
    if (length(w1) * length(w2) == 1 && is.numeric(w1) && w1 == w2)
      options['out.width'] = list(NULL)
  }
  options$fig.num = options$fig.num %n% length(x)
  dpi = attr(x, 'dpi') %n% options$dpi
  hook = knit_hooks$get('plot')
  paste(unlist(lapply(seq_along(x), function(i) {
    options$fig.cur = plot_counter()
    if (is.null(options[['out.width']]))
      options['out.width'] = list(raster_dpi_width(x[i], dpi))
    hook(x[i], reduce_plot_opts(options))
  })), collapse = '')
}

#' @export
sew.html_screenshot = function(x, options = opts_chunk$get(), inline = FALSE, ...) {
  ext = x$extension
  in_base_dir({
    i = plot_counter()
    if (is.null(f <- x$file)) {
      f = fig_path(ext, options, i)
      dir.create(dirname(f), recursive = TRUE, showWarnings = FALSE)
      writeBin(x$image, f, useBytes = TRUE)
    }
    options$fig.cur = i
    options = reduce_plot_opts(options)
    if (!is.null(x$url) && is.null(options$fig.link)) options$fig.link = x$url
    run_hook_plot(f, options)
  })
}

# record plot filenames in opts_knit$get('plot_files'), including those from R
# code and auto screenshots of HTML widgets, etc. Then run the plot hook.
run_hook_plot = function(x, options) {
  opts_knit$append(plot_files = x)
  hook = knit_hooks$get('plot')
  hook(x, options)
}

#' @export
sew.knit_embed_url = function(x, options = opts_chunk$get(), inline = FALSE, ...) {
  options$fig.cur = plot_counter()
  options = reduce_plot_opts(options)
  if (length(extra <- options$out.extra)) extra = paste('', extra, collapse = '')
  add_html_caption(options, sprintf(
    '<iframe src="%s" width="%s" height="%s" data-external="1"%s></iframe>',
    html_escape(x$url), options$out.width %n% '100%', x$height %n% '400px',
    extra %n% ''
  ))
}

add_html_caption = function(options, code, id = NULL) {
  cap = .img.cap(options)
  if (cap == '' && !length(id)) return(code)

  if (length(id)) {
    alt = .img.cap(options, alt = TRUE, escape = TRUE)
    if (cap == alt && cap != '') {
      # both are the same, so insert cap with id
      alttext = sprintf('<p class="caption" id="%s">%s</p>\n', id, cap)
      # prevent a second insertion
      cap = ''
    } else {
      alttext = sprintf('<p id="%s" hidden>%s</p>\n', id, alt)
    }
  } else alttext = ''

  captext = if (cap == '') '' else sprintf('<p class="caption">%s</p>\n', cap)

  sprintf(
    '<div class="figure"%s>\n%s\n%s%s</div>',
    css_text_align(options$fig.align), code, captext, alttext
  )
}

#' A custom printing function
#'
#' The S3 generic function \code{knit_print} is the default printing function in
#' \pkg{knitr}. The chunk option \code{render} uses this function by default.
#' The main purpose of this S3 generic function is to customize printing of R
#' objects in code chunks. We can fall back to the normal printing behavior by
#' setting the chunk option \code{render = normal_print}.
#'
#' Users can write custom methods based on this generic function. For example,
#' if we want to print all data frames as tables in the output, we can define a
#' method \code{knit_print.data.frame} that turns a data.frame into a table (the
#' implementation may use other R packages or functions, e.g. \pkg{xtable} or
#' \code{\link{kable}()}).
#' @param x An R object to be printed
#' @param ... Additional arguments passed to the S3 method. Currently ignored,
#'   except two optional arguments \code{options} and \code{inline}; see
#'   the references below.
#' @return The value returned from the print method should be a character vector
#'   or can be converted to a character value. You can wrap the value in
#'   \code{\link{asis_output}()} so that \pkg{knitr} writes the character value
#'   as is in the output.
#' @note It is recommended to leave a \code{...} argument in your method, to
#'   allow future changes of the \code{knit_print()} API without breaking your
#'   method.
#' @references See \code{vignette('knit_print', package = 'knitr')}.
#' @export
#' @examples library(knitr)
#' # write tables for data frames
#' knit_print.data.frame = function(x, ...) {
#'   res = paste(c('', '', kable(x, output = FALSE)), collapse = '\n')
#'   asis_output(res)
#' }
#' # register the method
#' registerS3method("knit_print", "data.frame", knit_print.data.frame)
#' # after you define and register the above method, data frames will be printed
#' # as tables in knitr, which is different with the default print() behavior
knit_print = function(x, ...) {
  if (getOption('knitr.in.progress', FALSE)) {
    current_env = parent.frame()
    local_options(list(rlang_trace_top_env = current_env))
  }
  if (need_screenshot(x, ...)) {
    html_screenshot(x)
  } else {
    UseMethod('knit_print')
  }
}

#" the default print method is just print()/show()
#' @export
knit_print.default = function(x, ..., inline = FALSE) {
  if (inline) x else normal_print(x)
}

#' @export
knit_print.knit_asis = function(x, ...) x

#' @export
knit_print.knit_asis_url = function(x, ...) x

#' @rdname knit_print
#' @export
normal_print = function(x, ...) {
  if (isS4(x)) methods::show(x) else print(x)
}

#' Mark an R object with a special class
#'
#' This is a convenience function that assigns the input object a class named
#' \code{knit_asis}, so that \pkg{knitr} will treat it as is (the effect is the
#' same as the chunk option \code{results = 'asis'}) when it is written to the
#' output.
#'
#' This function is normally used in a custom S3 method based on the printing
#' function \code{\link{knit_print}()}.
#'
#' For the \code{cacheable} argument, you need to be careful when printing the
#' object involves non-trivial side effects, in which case it is strongly
#' recommended to use \code{cacheable = FALSE} to instruct \pkg{knitr} that this
#' object should not be cached using the chunk option \code{cache = TRUE},
#' otherwise the side effects will be lost the next time the chunk is knitted.
#' For example, printing a \pkg{shiny} input element or an HTML widget in an R
#' Markdown document may involve registering metadata about some JavaScript
#' libraries or stylesheets, and the metadata may be lost if we cache the code
#' chunk, because the code evaluation will be skipped the next time. This
#' particular issue has been solved in \pkg{knitr} after v1.13 (the metadata
#' will be saved and loaded automatically when caching is enabled), but not all
#' metadata can be saved and loaded next time and still works in the new R
#' session.
#' @param x An R object. Typically a character string, or an object which can
#'    be converted to a character string via \code{\link{as.character}()}.
#' @param meta Additional metadata of the object to be printed. The metadata
#'   will be collected when the object is printed, and accessible via
#'   \code{knit_meta()}.
#' @param cacheable Boolean indicating whether this object is cacheable. If
#'   \code{FALSE}, \pkg{knitr} will stop when caching is enabled on code chunks
#'   that contain \code{asis_output()}.
#' @note This function only works in top-level R expressions, and it will not
#'   work when it is called inside another expression, such as a for-loop. See
#'   \url{https://github.com/yihui/knitr/issues/1137} for a discussion.
#' @export
#' @examples  # see ?knit_print
asis_output = function(x, meta = NULL, cacheable = NA) {
  structure(x, class = 'knit_asis', knit_meta = meta, knit_cacheable = cacheable)
}

#' Metadata about objects to be printed
#'
#' As an object is printed, \pkg{knitr} will collect metadata about it (if
#' available). After knitting is done, all the metadata is accessible via this
#' function. You can manually add metadata to the \pkg{knitr} session via
#' \code{knit_meta_add()}.
#' @param class Optionally return only metadata entries that inherit from the
#'   specified class. The default, \code{NULL}, returns all entries.
#' @param clean Whether to clean the collected metadata. By default, the
#'   metadata stored in \pkg{knitr} is cleaned up once retrieved, because we may
#'   not want the metadata to be passed to the next \code{knit()} call; to be
#'   defensive (i.e. not to have carryover metadata), you can call
#'   \code{knit_meta()} before \code{knit()}.
#' @export
#' @return \code{knit_meta()} returns the matched metadata specified by
#'   \code{class}; \code{knit_meta_add()} returns all current metadata.
knit_meta = function(class = NULL, clean = TRUE) {
  if (is.null(class)) {
    if (clean) on.exit({.knitEnv$meta = list()}, add = TRUE)
    return(.knitEnv$meta)
  }
  # if a class was specified, match the items belonging to the class
  matches = if (length(.knitEnv$meta)) {
    vapply(.knitEnv$meta, inherits, logical(1), what = class)
  }
  if (!any(matches)) return(list())
  if (clean) on.exit({
    .knitEnv$meta[matches] = NULL
    id = attr(.knitEnv$meta, 'knit_meta_id')
    if (length(id)) attr(.knitEnv$meta, 'knit_meta_id') = id[!matches]
  }, add = TRUE)
  .knitEnv$meta[matches]
}

#' @param meta A metadata object to be added to the session.
#' @param label A chunk label to indicate which chunk the metadata belongs to.
#' @rdname knit_meta
#' @export
knit_meta_add = function(meta, label = '') {
  if (length(meta)) {
    meta_id = attr(.knitEnv$meta, 'knit_meta_id')
    .knitEnv$meta = c(.knitEnv$meta, meta)
    attr(.knitEnv$meta, 'knit_meta_id') = c(meta_id, rep_len(label, length(meta)))
  }
  .knitEnv$meta
}
