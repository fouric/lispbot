# lispbot
a tiny IRC bot written in common lisp

# for beginners

Clone the repo, cd into the directory, then run `sbcl --load lispbot.lisp` (if using SBCL) and then `(lispbot:run)` to have it join irc.cat.pdx.edu/#lisp with a half-randomized nick.

if you get an error like the following:

    debugger invoked on a SB-INT:EXTENSION-FAILURE in thread
    #<THREAD "main thread" RUNNING {1001E068E3}>:
      Don't know how to REQUIRE BAR.

...that means that you don't have the "bar" library installed. Head over to https://www.quicklisp.org/beta/, follow the instructions, and then run `(ql:quickload 'bar)` for each library that you need to load.

# todo

add an optional "password" argument, so you can enter your password at the REPL and don't have to have the auth file
