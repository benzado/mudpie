mudpie
======

mudpie is a *dirt simple* tool for making [baked websites](http://inessential.com/2011/03/16/a_plea_for_baked_weblogs).

(See also: [Bake, Don't Fry](http://www.aaronsw.com/weblog/000404).)

There are literally dozens of similar tools out there that accomplish the same task. So why did I write this? Because I don't want to spend a lot of time learning arcane rules for how a source file becomes an output file, and where it is saved.

mudpie employs a very simple rule: every file in your content directory corresponds to a file in your output directory, with the exact same name. There is no need for a `Rules` file to contain routing information, because there is exactly one route for a source file to take.

Source files that are not compiled are simply copied. So you are free to include your image and font files along with your source files, and mudpie will do the right thing.

mudpie is currently alpha-grade software: I pretty much just wrote it.

How it works
------------

Your site will live in a directory structure like this:

    site/
      content/
      layouts/
      output/

The command `mp bake site/` will copy all the files from `content/` to `output/`. If you have an existing site as static HTML, you could copy everything into `content/` and you'd already be in business!

Let's say you add some files:

    site/
      config.yml
      content/
        index.html
        cats.html
      layout/
        default.html
      output/

You know what, I need to stop here and go to sleep. I'll write more later.
