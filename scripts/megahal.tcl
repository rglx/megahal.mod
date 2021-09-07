#!/usr/bin/env eggdrop
# worth a shot i guess

# megahal.tcl accompanying script v3.7
# september 2021 (that's like 22 years of megahal!)
# newer modifications & documentation by rglx
# previous modifications to megahal by zev and z0rc
# original megahal code by Jason Hutchens

# CONFIGURATION START - edit these variables to your liking.

set megahal_directory_resources "text/megahal/"
# stores brain training material and other training/learning data files

set megahal_directory_cache "data/megahal/"
# stores brain files and other bot-generated stuff
# folder NEEDS to exist prior to module load or it'll segfault and die.

loadmodule megahal
# loads the module. don't move this around this file.

# learn things sent to it or channels its in?
set learnmode on

# maximum number of nodes to grow to before trimming it every autosave (or on regular saves)
# you can set this to ten million and barely ever reach it, and with modern hosting capabilities you don't really need to limit this
set maxsize 10000000

# allow only this many lines:this many seconds to trigger a response. 
set floodmega 3:1

# channel limiting (not done via .chanset in DCC/console anymore)
# ignore direct mentions of the bot's nickname in these channels (space-delimited list)
set respondexcludechans "#learning #lobby"
# don't ever talk in these channels (space-delimited list)
set talkexcludechans "#learning #lobby"

# words to always respond to. (space delimited list)
# bot will also listen to words that have non-[A-Za-z0-9] characters around them
set responsekeywords "hal hals megahal megahals bot bots megas mega"

# maximum interval between random messages from the bot
# essentially only once every this many lines will cause a response on whatever channel has +megahal set (in eggdrop's channel file)
set talkfreq 30

# maximum interval between messages to learn (2 = learn every 2nd message, 1 = learn every message, 0 = don't learn any)
set learnfreq 1

# sentence generation settings

# maxcontext setting aka "how deep into already-learned sentences do we consider which path to take when we generate a new one"
# valid values are 1 through 5
# per original authors:
#   2 is highly recommended, 3 is much more boring but it will also produce much more coherent sentences
#   1 will make it babble incoherently a lot of the time and 4-5 will turn it into a parrot instead of a fun AI
set maxcontext 2

# Surprise mode on or off (0/1)
# This changes the way it constructs sentences. 
# If on, it tries to find unconventional combinations of words which means much more fun but also more incoherent sentences
# If off, sentences are safer but more parrot-like so this is only recommended if the brain size is huge )in which case the bot has many safe options to use).
set surprise 1

# Max reply words
# This can help avoid long incoherent sentences that seem to run forever without making sense
# It limits the AI to create shorter sentences
# Recommended setting is about 25-40, set to 0 to allow unlimited size
set maxreplywords 30

# END CONFIGURATION - congrats! you're done. return to the readme for the last steps.

# set learning mode
learningmode $learnmode
# tell megahal our actual bot nickname
set megabotnick $nick

# unbind bot nick bindings
if {[catch "unbind pubm - ${nick}: *pub:hal:"]} {
	putlog "failed to unbind pubm for bot nickname"
} else {
	putlog "successfully unbound pubm for bot nickname"
}

if {[catch "unbind pub - ${nick}: *pub:hal:"]} {
	putlog "failed to unbind pub for bot nickname"
} else {
	putlog "successfully unbound pub for bot nickname"
}
bind pubm - ${nick}: *pub:hal:

#unbind (and rebind dcc)
if {[catch "unbind dcc - hal *dcc:hal"]} {
	putlog "failed to unbind dcc bind for bot nickname"
} else {
	putlog "successfully unbound dcc bind for bot nickname"
}
#bind dcc - $nick *dcc:hal


# save brain every ten minutes. works mostly like crontab.
bind time - "?0 * * * *" auto_brainsave

bind pub - "!savebrain" pub_savebrain
bind pub n "!trimbrain" pub_trimbrain
#bind pub n "!lobotomy" pub_lobotomy
bind pub - "!braininfo" pub_braininfo
bind pub n "!learningmode" pub_learningmode
bind pub - "!talkfrequency" pub_talkfrequency
#bind pub n "!replyrate" pub_talkfrequency
#bind pub n "!restorebrain" pub_restorebrain

 # not yet implemented - eventually will allow lobotomizing without really losing any data
#bind pubm - "*" pub_learnToTrainingFile

proc updateBrainAgeCounter {} {
	global megahal_directory_cache
	# retrieve existing directory
	if {[file exists "$megahal_directory_cache/megahal.brn"]} {
		# ok, it exists, let's use its modtime
		if {[file exists "$megahal_directory_cache/megahal.age"]} {
			# our age file exists already...so we shouldn't mess with it
			putlog "not overwriting brain age counter"
		} else {
			putlog "megahal.tcl - brain age counter nonexistent - using last modified time of current brain"
			set newAgeCounterFileHandle [open "$megahal_directory_cache/megahal.age" w]
			puts $newAgeCounterFileHandle [file mtime "$megahal_directory_cache/megahal.brn"]
			close $newAgeCounterFileHandle
		}
	} else {
		# brain file doesn't exist yet, so let's just use current time
		set newAgeCounterFileHandle [open "$megahal_directory_cache/megahal.age" w]
		puts $newAgeCounterFileHandle [unixtime]
		close $newAgeCounterFileHandle
	}
}

updateBrainAgeCounter

proc auto_brainsave {min b c d e} {
	global maxsize
	putlog "megahal.tcl - autosaving brain"
	trimbrain $maxsize
	savebrain
}

proc pub_savebrain {nick uhost hand chan arg} {
	global maxsize
	putlog "megahal.tcl - $nick is manually saving our brain..."
	trimbrain $maxsize
	set for [treesize -1 0]
	set back [treesize -1 1]
	savebrain
	puthelp "NOTICE $chan :Brain saved, word count: [lindex $for 0], nodes: [expr [lindex $for 1]+[lindex $back 1]]"
}

proc pub_trimbrain {nick uhost hand chan arg} {
	global maxsize
	putlog "megahal.tcl - $nick is manually trimming our brain..."
	set arg1 [lindex $arg 0]
	if {$arg1 == "" || ![isnum $arg1]} {
		set arg1 $maxsize
	}
	trimbrain $arg1
	savebrain

	putlog "megahal.tcl - brain manually trimmed down to $arg1 nodes"
	puthelp "NOTICE $chan :brain trimmed down to $arg1 nodes. word count: [lindex $for 0], nodes: [expr [lindex $for 1]+[lindex $back 1]]"
}

proc pub_lobotomy {nick uhost hand chan arg} {
	global megahal_directory_cache
	global maxsize
	putlog "megahal.tcl - preparing for lobotomy (by order of $nick)..."

	# save and trim our brain first
	trimbrain $maxsize
	savebrain

	putlog "megahal.tcl - backing up brain..."

	# erase the last old one if it exists
	file delete $megahal_directory_cache/megahal.brn.old
	file copy $megahal_directory_cache/megahal.brn $megahal_directory_cache/megahal.brn.old
	file copy $megahal_directory_cache/megahal.brn "$megahal_directory_cache/megahal.brn.old.[unixtime]-lobotomy"
	file delete $megahal_directory_cache/megahal.brn

	# and our age counter
	file delete $megahal_directory_cache/megahal.age
	updateBrainAgeCounter

	putlog "megahal.tcl - regenerating brain..."

	# now reinitialize from our (now nonexistent) brain file, training it, then save.
	reloadbrain
	savebrain
	set for [treesize -1 0]
	set back [treesize -1 1]

	putlog "megahal.tcl - lobotomy completed, regenerated from training texts"
	puthelp "NOTICE $chan :lobotomy completed, regenerated from training texts. word count: [lindex $for 0], nodes: [expr [lindex $for 1]+[lindex $back 1]]"
}

proc pub_braininfo {nick uhost hand chan arg} {
	global learnmode
	global megahal_directory_cache
	set for [treesize -1 0]
	set back [treesize -1 1]
	if {[file exists "$megahal_directory_cache/megahal.age"]} {
		puthelp "NOTICE $chan :(megahal brain info) words: [lindex $for 0] - nodes: [expr [lindex $for 1]+[lindex $back 1]] - learningmode: $learnmode - age: [duration [expr [unixtime] - [file mtime "$megahal_directory_cache/megahal.age"]]]"
	} else {
		puthelp "NOTICE $chan :(megahal brain info) words: [lindex $for 0] - nodes: [expr [lindex $for 1]+[lindex $back 1]] - learningmode: $learnmode"
	}
}

proc pub_learningmode {nick uhost hand chan arg} {
	global learnmode
	set arg1 [lindex $arg 0]
	if {$arg1 == "" || ($arg1 != "on" && $arg1 != "off")} {
		puthelp "NOTICE $chan :specify on or off. currently: $learnmode"
		return
	}
	set learnmode $arg1
	learningmode $learnmode
	puthelp "NOTICE $chan :learning from all channels is now $learnmode" 
}

proc pub_talkfrequency {nick uhost hand chan arg} {
	global talkfreq
	set arg1 [lindex $arg 0]
	if {$arg1 == ""} {
		puthelp "NOTICE $chan :(megahal) Talk frequency currently once every $talkfreq lines." 
		return
	}
	set talkfreq $arg1
	puthelp "NOTICE $chan :(megahal) Talk frequency set to once every $talkfreq lines." 
}

proc pub_restorebrain {nick uhost hand chan arg} {
	global megahal_directory_cache
	if {[file exists $megahal_directory_cache/megahal.old]} {

		# save and trim our brain first
		global maxsize
		trimbrain $maxsize
		savebrain

		# then make a backup of it
		file copy $megahal_directory_cache/megahal.brn "$megahal_directory_cache/megahal.brn.old.[unixtime]-restore"
		file delete $megahal_directory_cache/megahal.brn

		# and our age counter
		file delete $megahal_directory_cache/megahal.age
		updateBrainAgeCounter

		# then copy in our new brain
		file copy $megahal_directory_cache/megahal.old $megahal_directory_cache/megahal.brn

		# and reload from it.
		reloadbrain

		puthelp "NOTICE $chan :restored most recent brain!"
	} else {
		puthelp "NOTICE $chan :old brain file doesn't exist."
	}
}

proc isnum {num} {
	for {set x 0} {$x < [string length $num]} {incr x} {
		if {[string trim [string index $num $x] 0123456789.] != ""} {return 0}
	}
	return 1
}
