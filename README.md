# Mud Pie

Mud Pie is a *dirt simple* tool for making [baked
websites](http://inessential.com/2011/03/16/a_plea_for_baked_weblogs).

(See also: [Bake, Don't Fry](http://www.aaronsw.com/weblog/000404).)

There are literally dozens of similar tools that accomplish this same task. So
why did I write this? Mostly because I don't want to learn a lot of arcane rules
about how a source file becomes an output file, and where it is saved.

Mud Pie employs a very simple rule: every file in your content directory
corresponds to at least one file in your output directory. If the file name ends
with `.mp`, it is compiled; otherwise it is simply copied.

For example,

- `foo/bar.html.mp` is compiled to `foo/bar.html`,
- `foo/baz.png` is copied to `foo/baz.png`.

Compiling means we process the file using Ruby's IRB templating system. A simple
`hello-world.html.mp` might look like this:

    % @title = 'My First Web Page'
    
    Hello, world!

Lines that start with `%` are interpreted as Ruby code, and variables set will
be visible to later template files that are used to lay out the page.

Mud Pie is currently alpha-grade software. I'm using it to maintain [the Heroic
Software website](http://heroicsoftware.net/), but I'm not above breaking
compatibility as I figure out what works and what doesn't.

## How it works

Your site will live in a directory structure like this:

    site/
      content/
      layouts/
      output/

The command `mp bake site/` will copy all the files from `content/` to
`output/`. If you have an existing site as static HTML, you could copy
everything into `content/` and you'd already be in business!

Let's say you add some files:

    site/
      config.yml
      content/
        index.html.mp
        cats.html.mp
      layout/
        _.html
      output/

You know what, I need to stop here and go to sleep. I'll write more later.
