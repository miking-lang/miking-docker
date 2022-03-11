-- sample.mc
-- Sample program for verifying that the docker environment can compile and run
-- MCore programs.

-- import from standard library
include "option.mc"
include "seq.mc"

let a = Some "foo"
let b = Some "bar"
let c = None ()

let printContents = lam o.
  switch o
    case Some msg then print (join ["Found msg: \"", msg, "\"\n"])
    case None _   then print "Found nothing.\n"
  end

mexpr

printContents a;
printContents b;
printContents c
