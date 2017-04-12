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
dst.copyright = "Free as a bird"
dst.version = "000.100"
dst.em = 1000;

# Next slot for glyphs.
ind = 33;

# Copy glyphs from MusicSymbols.
src = fontforge.open("MusicSymbols.ttf")
gcopy( "Sharp",   0x0023 )
gcopy( "Flat",    0x0062 )
gcopy( "Natural", 0x006e )
gcopy( "Same2",   0x00d4 )

stretch = psMat.scale( 1, 1.2 )

# Copy glyphs from TimesRoman.
src = fontforge.open("../../../.fonts/TimesNewRomanPSMT.ttf")
gcopy( "Dim",     0x006f, stretch )
gcopy( "HDim",    0x00f8, stretch )
gcopy( "Major",   0x0394 )

# Generate new font.
dst.generate("new.pfa")
