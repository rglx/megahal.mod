# MegaHAL, the eggdrop module

Artificially Intelligent conversation with learning capability and
psychotic personality.

## requirements
 - recent version of eggdrop ( https://www.eggheads.org/ ) compiled, running, set up and operational in a channel already
 - the megahal.mod folder (not the main repository, but the subfolder here which should contain the Makefile and the .c and .h files)
 - the training text files of your choosing

## installation
 - stop your bot and make a backup of your userfile, channelfile, and while you're at it, everything else in `~/eggdrop`.
 - add the megahal.mod folder (not the whole repository! just the subdirectory!) to eggdrop's source code directory under `eggdrop-<version>/src/mod/`. inside `eggdrop-<version>/src/mod/megahal.mod/` should be `Makefile`, `megahal.c`, and `megahal.h` and nothing else.
 - seriously, make that backup.
 - from your source code directory, run `./configure` plus whatever your usual options are (for say, pointing to a specifically compiled tcl version or something)
 - after that's done, `make config` (or if you used the interactive module setup `make iconfig`) then `make -jX` (where `X` is how many logical cores your machine has)
 - copy `scripts/` and `text/` and `data/` to your eggdrop installation's directory.


## contributors
- original megahal code by Jason Hutchens (1999)
- by Zev "^Baron^" Toledano (operator of thelastexit.net) (2009)
- v3.7 patch and initial eggdrop script by z0rc (2011)
- further minor revisions by rglx (2021)
