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
    dst.createChar(ind)
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
dst.em = 1024;
dst.encoding = "ISO 8859-1"

# Next slot for glyphs.
ind = 33;

# Copy glyphs from MusicSymbols.
src = fontforge.open("Bravura-1.12.otf")
scale = psMat.compose( psMat.scale(0.9 ), psMat.translate( 0, 480 ) )
gcopy( "Sharp",       0xe262, scale )
scale = psMat.translate( 0, 350 )
gcopy( "Flat",        0xe260, scale )
scale = psMat.compose( psMat.scale(0.9 ), psMat.translate( 0, 480 ) )
gcopy( "Natural",     0xe261, scale )

# Bar repeats.
gcopy( "Repeat1Bar",  0xe500 )
gcopy( "Repeat2Bars", 0xe501 )
gcopy( "Repeat4Bars", 0xe502 )

# Chord symbols.
stretch = psMat.compose( psMat.scale( 0.9, 1.3 ), psMat.translate( 0, -80 ) )
gcopy( "ChordDim",     0xe870 )
gcopy( "ChordHalfDim", 0xe871 )
gcopy( "ChordAug",     0xe872 )
gcopy( "ChordMajor7",  0xe873, stretch )
gcopy( "ChordMinor",   0xe874 )

# Fretboard symbols.
ind = 0x100;
gcopy( "FB6String",    0xe856 )
gcopy( "FB6StringNut", 0xe857 )
gcopy( "FBFilled",     0xe858 )
gcopy( "FBX",          0xe859 )
gcopy( "FB0",          0xe85a )

# Glyphs for roman numerals.
src = fontforge.open("Times-Roman.ttf")
ind = 0x105
scale = psMat.scale( 0.4 )
gcopy( "RomanI",    0x0049, scale )
gcopy( "RomanV",    0x0056, scale )
gcopy( "RomanX",    0x0058, scale )
gcopy( "RomanL",    0x004c, scale )
gcopy( "RomanM",    0x004d, scale )
gcopy( "RomanD",    0x0044, scale )
gcopy( "RomanC",    0x0043, scale )

# Small high numerals.
# They map to "0" .. "9".
src = fontforge.open("Myriad-CondensedSemiBold.pfb")
scale = psMat.compose( psMat.scale( 0.7 ), psMat.translate( 0, 220 ) )
ind = 0x30
gcopy( "High0",	0x0030, scale )
gcopy( "High1",	0x0031, scale )
gcopy( "High2",	0x0032, scale )
gcopy( "High3",	0x0033, scale )
gcopy( "High4",	0x0034, scale )
gcopy( "High5",	0x0035, scale )
gcopy( "High6",	0x0036, scale )
gcopy( "High7",	0x0037, scale )
gcopy( "High8",	0x0038, scale )
gcopy( "High9",	0x0039, scale )

gcopy( "HighParenOpen",	 0x0028, scale )
gcopy( "HighParenClose", 0x0029, scale )


# Low variants
scale = psMat.compose( psMat.scale( 0.7 ), psMat.translate( 0, -20 ) )
ind = 0x10c
gcopy( "Low0",	0x0030, scale )
gcopy( "Low1",	0x0031, scale )
gcopy( "Low2",	0x0032, scale )
gcopy( "Low3",	0x0033, scale )
gcopy( "Low4",	0x0034, scale )
gcopy( "Low5",	0x0035, scale )
gcopy( "Low6",	0x0036, scale )
gcopy( "Low7",	0x0037, scale )
gcopy( "Low8",	0x0038, scale )
gcopy( "Low9",	0x0039, scale )

# Glyphs for chord names.
# Map to "A" .. "G".
src = fontforge.open("Myriad-CondensedSemiBold.pfb")
ind = 0x41
gcopy( "A",	0x0041 )
gcopy( "B",	0x0042 )
gcopy( "C",	0x0043 )
gcopy( "D",	0x0044 )
gcopy( "E",	0x0045 )
gcopy( "F",	0x0046 )
gcopy( "G",	0x0047 )

# Small(caps).
# Map to the lowcase equivalents.
src = fontforge.open("Myriad-CondensedSemiBold.pfb")
scale = psMat.scale( 0.6 )
ind = 0x61; gcopy( "ScA",  0x0041, scale )
ind = 0x64; gcopy( "ScD",  0x0044, scale )
ind = 0x65; gcopy( "ScE",  0x0045, scale )
ind = 0x67; gcopy( "ScG",  0x0047, scale )
ind = 0x69; gcopy( "ScI",  0x0049, scale )
ind = 0x6d; gcopy( "ScM",  0x004d, scale )
ind = 0x6f; gcopy( "ScO",  0x004f, scale )
ind = 0x70; gcopy( "ScP",  0x0050, scale )
ind = 0x72; gcopy( "ScR",  0x0052, scale )
ind = 0x73; gcopy( "ScS",  0x0053, scale )
ind = 0x74; gcopy( "ScT",  0x0054, scale )
ind = 0x75; gcopy( "ScU",  0x0055, scale )

# Generate new font.
dst.generate("new.ttf")
