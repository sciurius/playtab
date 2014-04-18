#!/usr/bin/python

import fontforge
import sys
import os
import struct
import psMat

dst = None
src = None

# Copy a glyph from f to the next slot, optionally tranforming
# it using the matrix tf.

def gcopy(name, f, tf = 0 ):
    global src, dst
    global ind
    src.selection.select(f)
    src.copy()
    dst.selection.select(ind)
    ind += 1
    dst.paste()
    for glyph in dst.selection.byGlyphs:
    	glyph.glyphname = name
	if tf:
	   glyph.transform(tf)
    
# Create new font, set some properties.
dst  = fontforge.font()
dst.fontname = "MSyms"
dst.familyname = "MusicalSymbolsForPlaytab"
dst.fullname = "Musical Symbols For Playtab"
dst.copyright = "Free as a bird. Most glyphs extracted from Bravura."
dst.version = "000.200"
dst.em = 1000;

# Next slot for glyphs.
ind = 33;

# Copy glyphs from MusicSymbols.
src = fontforge.open("Bravura.otf")
gcopy( "Sharp",       0x266f )
gcopy( "Flat",        0x266d )
gcopy( "Natural",     0x266e )

# Bar repeats.
gcopy( "Repeat1Bar",  0xe4e0 )
gcopy( "Repeat2Bars", 0xe4e1 )
gcopy( "Repeat4Bars", 0xe4e2 )

# Chord symbols.
gcopy( "ChordDim",     0xe800 )
gcopy( "ChordHalfDim", 0xe801 )
gcopy( "ChordAug",     0xe802 )
gcopy( "ChordMajor7",  0xe803 )
gcopy( "ChordMinor",   0xe804 )

# Fretboard symbols.
gcopy( "FB6String",    0xe7e6 )
gcopy( "FB6StringNut", 0xe7e7 )
gcopy( "FBFilled",     0xe7e8 )
gcopy( "FBX",          0xe7e9 )
gcopy( "FB0",          0xe7ea )

# Glyphs for roman numerals.
# They map to 1 .. 7 (but that's coincidental).
src = fontforge.open("Times-Roman.ttf")
scale = psMat.scale( 0.4, 0.4 )
gcopy( "RomanI",    0x0049, scale )
gcopy( "RomanV",    0x0056, scale )
gcopy( "RomanX",    0x0058, scale )
gcopy( "RomanL",    0x004c, scale )
gcopy( "RomanM",    0x004d, scale )
gcopy( "RomanD",    0x0044, scale )
gcopy( "RomanC",    0x0043, scale )

# Generate new font.
dst.generate("new.ttf")
