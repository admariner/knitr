library(testit)

render_jekyll('prettify')
options(prompt = '> ', continue = '+ ')

# see http://stackoverflow.com/q/18992260/559676 for the bug
assert('the source hook pastes source code into one character string', {
  (knit_hooks$get('source')(c('1+1', '2-2'), opts_chunk$get()) %==%
    "\n\n<pre><code class=\"prettyprint \">1+1\n2-2</code></pre>\n\n")
  (knit_hooks$get('source')(c('1+1+\n1', '2-2'), opts_chunk$merge(list(prompt = TRUE))) %==%
    "\n\n<pre><code class=\"prettyprint \">&gt; 1+1+\n+ 1\n&gt; 2-2</code></pre>\n\n")
})

render_markdown()

img_output = function(path, opts = list()) {
  opts = opts_chunk$merge(opts)
  sew(knit_print(include_graphics(path, error = FALSE)), opts)
}

assert('include_graphics() includes custom images correctly', {
  (img_output('a.png') %==% '![](a.png)')
  (img_output(c('a.png', 'b.png'), list(fig.show = 'hold')) %==% '![](a.png)![](b.png)')
  (img_output('a.png', list(fig.cap = 'foo bar')) %==% '![foo bar](a.png)')
  (img_output('a.png', list(out.width = '50%')) %==% '<img src="a.png" width="50%" />')
  (img_output('a.pdf', list(out.width = '300px')) %==% '<embed src="a.pdf" width="300px" type="application/pdf" />')
})

hook_src = knit_hooks$get("source")
options_ = list(engine = "r", prompt = FALSE, highlight = TRUE)

assert('Length of fences are satisfied', {
  (hook_src("", options_) %==% "\n\n``` r\n\n```\n\n")
  (hook_src("```", options_) %==% "\n\n```` r\n```\n````\n\n")
})

assert('Attributes for source can be specified class.source and attr.source', {
  (hook_src("1", c(options_, class.source = "a b")) %==% "\n\n```{.r .a .b}\n1\n```\n\n")
  (hook_src("1", c(options_, attr.source = ".a .b")) %==% "\n\n```{.r .a .b}\n1\n```\n\n")
  (hook_src("1", c(options_, class.source = "a", attr.source = "b='1'")) %==%
    "\n\n```{.r .a b='1'}\n1\n```\n\n")
  (hook_src("1", c(options_, attr.source = ".a b='1'")) %==%
    "\n\n```{.r .a b='1'}\n1\n```\n\n")
})

assert('class.source and attr.source works also with collapse = TRUE', {
  hook_chunk = hooks_markdown()$chunk
  (hook_chunk("```{.r .a b=1}\n1\n```", c(options_, collapse = TRUE)) %==%
      "```{.r .a b=1}\n1\n```")
  (hook_chunk("```{.r .a b=1}\n1\n```\n```{.r .a b=1}\n1\n```",
              c(options_, collapse = TRUE)) %==%
      "```{.r .a b=1}\n1\n1\n```")
})

hook_out = knit_hooks$get("output")

assert('Attributes for source can be specified class.source and attr.source', {
  (hook_out("1\n", c(options_, class.output = "a b")) %==%
    "\n\n```{.a .b}\n1\n```\n\n")
  (hook_out("1\n", c(options_, attr.output = ".a .b")) %==%
    "\n\n```{.a .b}\n1\n```\n\n")
  (hook_out("1\n", c(options_, class.output = "a", attr.output = "b='1'")) %==%
    "\n\n```{.a b='1'}\n1\n```\n\n")
  (hook_out("1\n", c(options_, attr.output = ".a b='1'")) %==%
    "\n\n```{.a b='1'}\n1\n```\n\n")
})

hook_chunk = knit_hooks$get("chunk")

assert('Chunks are enclosed by fenced divs when needed.', {
  (hook_chunk('', list(class.chunk=NULL)) %==% '')
  (hook_chunk('', list(class.chunk="")) %==% '::: \n\n:::')
  (hook_chunk('', list(class.chunk="foo")) %==% '::: foo\n\n:::')
  (hook_chunk(':::', list(class.chunk="foo")) %==% ':::: foo\n:::\n::::')
})

knit_hooks$restore()


x = "1.png"
w = h = 1
ex = "style='margin: 0;'"
cap = "foo"
opt = function(
  w = NULL, h = NULL, ex = NULL, cap = NULL, show = 'asis',
  fig.align = 'default', ...
) {
  list(
    out.width = w, out.height = h, out.extra = ex,
    fig.cap = cap, fig.show = show, fig.align = fig.align, ...
  )
}

assert("Include a plot by pandoc md", {
  (hook_plot_md_pandoc(x, opt()) %==% "![](1.png)")
  (hook_plot_md_pandoc(x, opt(w = w)) %==% sprintf("![](1.png){width=%s}", w))
  (hook_plot_md_pandoc(x, opt(h = h)) %==% sprintf("![](1.png){height=%s}", h))
  (hook_plot_md_pandoc(x, opt(cap = cap)) %==% sprintf("![%s](1.png)", cap))
  (hook_plot_md_pandoc(x, opt(ex = ex)) %==% sprintf("![](1.png){%s}", ex))
  (hook_plot_md_pandoc(x, opt(w = w, cap = cap, ex = ex)) %==%
    sprintf("![%s](1.png){width=%s %s}", cap, w, ex))
})

assert("fig.alt does not break office document", {
  old = opts_knit$get('rmarkdown.pandoc.to')
  opts_knit$set(rmarkdown.pandoc.to = "docx")
  (suppressWarnings(hook_plot_md(x, opt())) %==% "![](1.png)")
  (suppressWarnings(hook_plot_md(x, opt(fig.alt = "bar"))) %==% "![](1.png)")
  opts_knit$set('rmarkdown.pandoc.to' = old)
})
