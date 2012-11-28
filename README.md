# Mud Pie

Mud Pie is a *dirt simple* tool for generating baked websites.

## What's a baked website?

Maintaining a website as a set of individual HTML files is basically impossible; if you have more than one page, you will have chunks of code you will want to re-use (such as headers and footers). Templates are a necessity.

Dozens of content management systems accomplish this by storing content in a database, then assemble a page on each request. Fine, but wasteful, and you need to maintain an application server and a database.

An alternate strategy (employed by Mud Pie) is to compile some source files into HTML files, which can be directly served by any barebones web server.

For more, see:

- [A Plea for Baked Weblogs](http://inessential.com/2011/03/16/a_plea_for_baked_weblogs)
- [Bake, Don't Fry](http://www.aaronsw.com/weblog/000404)

## How does it work?

Mud Pie is built on top of [Rake][rake] and strives to be straightforward and predictable.

A Mud Pie site uses the following directory structure:

- `Rakefile` containing `require 'mudpie'` at a minimum
- `cache/` for the Pantry (an index of your pages)
- `layouts/` for your template files
  - `default.erb`
  - `post.erb` for blog posts, may itself use the default layout
- `pages/` for your pages
  - `index.html.erb` a eRuby file
  - `feed.xml.rb` a Ruby script
  - `blog/2012/11/hello.html.md` a blog post in Markdown format
- `parts/` for bits of content to be included on your pages and layouts
- `public/` is where the generated files go
  - `index.html` generated from `index.html.erb`
  - `feed.xml` generated from `feed.xml.rb`
  - `blog/2012/11/hello.html` generated from... can you guess?
- `site.rb` for custom code for your site

As I hope you can see, the rules for determining the final URL of a page are fairly straightforward.

Each page can specify metadata at the top of the file, depending on its format:

- Ruby: any lines like `@title = "Hello"` are used as metadata;
- eRuby: we use lines like `% @title = "Hello"`;
- Markdown: a list formatted like `- title: Hello`

This metadata is copied into a SQLite database to allow pages to query it during baking. This is charmingly referred to as "stocking the pantry".

The commands are:

- `rake clean` deletes your `public` directory.
- `rake clobber` deletes your `cache` also.
- `rake mp:bake` updates the `public` directory as needed.
- `rake mp:serve:cold` starts a local HTTP server in the `public` directory.
- `rake mp:serve:hot` starts a local HTTP for live previews of your site.

Mud Pie does not offer any special handling for blog posts. That is, they are not treated differently from other pages. However, Mud Pie's indexing step means you can efficiently retrieve a list of pages that, for example, use the "post" layout, and order them by their date.

## Aren't there dozens of other tools that do this?

Yes. I try to avoid [Not Invented Here syndrom][nih], but I really wasn't happy with any of the systems out there.

[Jekyll][jekyll], one of the most popular tools, was designed for [GitHub Pages][gp], a hosted service where J. Random User can upload a set of pages and templates and GitHub's computers will generate and serve the HTML files. Because a template is basically a computer program that outputs a file, GitHub is facing a situation where they are allowing untrusted code to run on their server.

Since nobody has solved [The Halting Problem][halting] yet, Jekyll relies on [Liquid][liquid] for its templates, because they do not make a Turing-complete language. In other words, _Jekyll intentionally uses a limited templating language because it must deal with untrusted code._

But I'm building websites for myself! I will happily accept the risk that I may write an infinite loop if it means I can use whatever templating language I feel is best for the job.

Mud Pie is designed to allow you to write in Markdown or eRuby or any templating language you care to define a Renderer for. You can even write a straight Ruby script whose output will become the generated page.

[nih]: http://www.joelonsoftware.com/articles/fog0000000007.html
[jekyll]: https://github.com/mojombo/jekyll
[gp]: http://pages.github.com
[halting]: http://www.cgl.uwaterloo.ca/~csk/halt/
[liquid]: http://liquidmarkup.org

## What are the shortcomings or known issues?

There are no tests. _Sacrilege, I know!_

There is no dependency checking beyond "target file depends on source file"; in other words, if you update a layout, pages using that layout won't be updated unless you perform a clean bake.

To facilitate blogging, a Rake task to move a file from a `drafts` folder to an appropriately named path in the `pages` directory would be nice.

A tool to migrate a WordPress site into Mud Pie would be nice.

If `rake mp:serve:hot` supported the MetaWeblog API so I could use MarsEdit to publish posts, that would be awesome.

Metadata parsing for non-script formats (e.g., Markdown) is a little hacky. Maybe YAML Front Matter is the way to go?

Additional renderers:

- [HAML](http://haml.info)
- [Liquid](http://liquidmarkup.org)
- [Textile](http://textile.thresholdstate.com)
- [Mustache](http://mustache.github.com/)
- [CoffeeScript](http://coffeescript.org)
- [Sass](http://sass-lang.com)
- [LESS](http://lesscss.org)
- PHP, Python, and Perl: why not?
- XSLT?

Something like the Rails asset pipeline, where a generated file is named using a hash of its contents, would be useful for javascripts, stylesheets, and image files.
