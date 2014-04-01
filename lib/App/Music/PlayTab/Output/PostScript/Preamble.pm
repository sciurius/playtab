#! perl

# Author          : Johan Vromans
# Created On      : Tue Apr 19 16:25:30 2011
# Last Modified By: Johan Vromans
# Last Modified On: Tue Apr  1 12:29:04 2014
# Update Count    : 47
# Status          : Unknown, Use with caution!

package App::Music::PlayTab::Output::PostScript::Preamble;

use strict;
use warnings;

our $VERSION = "1.003";

sub preamble {
<<'EOD';
%!PS-Adobe-2.0
%%Pages: (atend)
%%DocumentFonts: Helvetica
%%EndComments
%%BeginProcSet: Symbols 0
/tabdict 50 dict def
tabdict begin
/m { moveto } bind def
/glyphwidth { % name *glyphwidth* wx wy
    gsave nulldevice 0 0 moveto glyphshow currentpoint grestore
} bind def
/dim {
    currentpoint
    /MSyms findfont 7 scalefont setfont
    1 8 rmoveto /Dim glyphshow moveto } def
/hdim {
    currentpoint
    /MSyms findfont 7 scalefont setfont
    1 8 rmoveto /HDim glyphshow moveto } def
/minus {
    currentpoint
    /Symbol findfont 12 scalefont setfont
    1 8 rmoveto (-) show moveto } def
/plus {
    currentpoint
    /Symbol findfont 12 scalefont setfont
    1 8 rmoveto (+) show moveto } def
/delta {
    /MSyms findfont 6 scalefont setfont
    1 -3 rmoveto /Major glyphshow -1 3 rmoveto } def
/sharp {
    /MSyms findfont sfsz scalefont setfont
    sfsz 5 gt { 2 } { 1 } ifelse 2 rmoveto
    /Sharp glyphshow
    sfsz 5 gt { 2 } { 1 } ifelse neg -2 rmoveto } def
/flat {
    /MSyms findfont sfsz scalefont setfont
    sfsz 5 gt { 2 } { 1 } ifelse 2 rmoveto
    /Flat glyphshow
    %sfsz 5 gt { 2 } { 1 } ifelse neg -2 rmoveto
    1 -2 rmoveto } def
/natural {
    /MSyms findfont 20 scalefont setfont
    2 0 rmoveto /Natural glyphshow -1 0 rmoveto } def
/addn {
    /Helvetica findfont 12 scalefont setfont
    0 -3 rmoveto show 0 3 rmoveto } def
/adds {
    /MSyms findfont 5 scalefont setfont
    1 -1 rmoveto /Sharp glyphshow 1 1 rmoveto
    /Helvetica findfont 12 scalefont setfont
    0 -3 rmoveto show 0 3 rmoveto } def
/addf {
    /MSyms findfont 5 scalefont setfont
    1 -1 rmoveto /Flat glyphshow 1 1 rmoveto
    /Helvetica findfont 12 scalefont setfont
    0 -3 rmoveto show 0 3 rmoveto } def
/root {
    /Helvetica findfont 16 scalefont setfont
    show
    /sfsz 6 def
} def
/hroot {
    /Helvetica findfont 12 scalefont setfont
    show
    /sfsz 4 def
} def
/slash {
    /Helvetica findfont 16 scalefont setfont
    2 -4 rmoveto (/) show } def
/bslash {
    /Helvetica findfont 16 scalefont setfont
    0 4 rmoveto (\\) show 0 3 rmoveto } def
/susp {
    /Helvetica findfont 12 scalefont setfont
    0 -3 rmoveto (sus) show show 0 3 rmoveto } def
/bar {
    1 setlinewidth
    currentpoint 0 -3 rmoveto 0 16 rlineto stroke moveto } def
/barn {
    gsave /Helvetica findfont 8 scalefont setfont
    % 0 14 rmoveto dup stringwidth pop 2 div neg 0 rmoveto
    -2 8 rmoveto dup stringwidth pop neg 0 rmoveto
    show grestore
    bar
    } def
/same1 {
    /MSyms findfont 4 scalefont setfont
    /Same2 dup glyphwidth pop 2 div neg 0 rmoveto glyphshow } def
/rest {
    /Helvetica findfont 16 scalefont setfont
    /endash glyphshow } def
/ta {
    /Helvetica findfont 14 scalefont setfont
    (T.A.) show	} def
/TF {
    /Helvetica findfont 16 scalefont setfont } def
/SF {
    /Helvetica findfont 12 scalefont setfont } def
end
%%EndProcSet
%%BeginProcSet: Grid 0 0
% Routines for the drawing of chords.
/griddict 10 dict def
griddict begin
  /gridscale $std_gridscale def
  /gridwidth gridscale 5 mul def
  /gridheight gridscale 4 mul def
  /half-incr gridscale 2 div def
  /dot-size gridscale 0.35 mul def
  /displ-font /Times-Roman findfont gridscale 1.25 mul scalefont def

  /grid {				% -- grid --
    gsave currentpoint
    6
    { 0 gridheight rlineto gridscale gridscale gridwidth sub rmoveto }
    repeat
    moveto
    5
    { gridwidth 0 rlineto 0 gridwidth sub gridscale rmoveto }
    repeat
    stroke grestore
  } def

  /dot {				% string fret dot --
    gsave
    exch 6 exch sub gridscale mul	% str fret -> fret y
    exch dup 5 exch abs sub gridscale mul half-incr sub	% fret y -> y fret x
    exch 3 1 roll rmoveto

    % It is tempting to use the more enhanced format (that places o
    % and x above the grid) but there is a chord caption.
    % fret {...} --
    -1 ne
    { currentpoint dot-size 0 360 arc fill }
    { gsave
      gridwidth 20 div
	    dup neg dup rmoveto
	    dup dup rlineto
	    dup dup rlineto
	    dup neg dup rmoveto
	    dup dup neg exch rmoveto
	    dup dup neg rlineto
	        dup neg rlineto
      gridwidth 50 div setlinewidth stroke
      grestore
    } ifelse
    grestore
  } def	
end
tabdict begin
/dots {				% e a d g b e offset dots --
    griddict begin
    gsave
    1 setlinewidth
    0 setgray

    grid

    % Chord offset, if greater than 1.
    % offset {...} --
    dup () ne
    { gsave
      half-incr neg gridheight gridscale sub rmoveto
      displ-font setfont
      dup stringwidth pop neg half-incr rmoveto show grestore
    }
    { pop }
    ifelse

    1 1 6
    {	% fret string {...} --
	exch dup
	0 ne
	{ dot }
	{ pop pop }
	ifelse
    }
    for
    end
} def
end
%%EndProcSet
%%EndProlog
%%BeginFont: MSyms
%!PS-AdobeFont-1.0: MSyms 000.100
%%Title: MSyms
%Version: 000.100
%%CreationDate: Fri Dec  7 13:24:47 2012
%%Creator: Johan Vromans
%Copyright: Free as a bird
% 2012-12-7: Created.
% Generated by FontForge 20120731 (http://fontforge.sf.net/)
%%EndComments

10 dict begin
/FontType 1 def
/FontMatrix [0.001 0 0 0.001 0 0 ]readonly def
/FontName /MSyms def
/FontBBox {0 -1561 2494 2089 }readonly def
/PaintType 0 def
/FontInfo 9 dict dup begin
 /version (000.100) readonly def
 /Notice (Free as a bird) readonly def
 /FullName (Musical Symbols For Playtab) readonly def
 /FamilyName (MusicalSymbolsForPlaytab) readonly def
 /Weight (Medium) readonly def
 /ItalicAngle 0 def
 /isFixedPitch false def
 /UnderlinePosition -100 def
 /UnderlineThickness 50 def
end readonly def
/Encoding 256 array
 0 1 255 { 1 index exch /.notdef put} for
dup 33/Sharp put
dup 34/Flat put
dup 35/Natural put
dup 36/Same2 put
dup 37/Dim put
dup 38/HDim put
dup 39/Major put
readonly def
currentdict end
currentfile eexec
743F8413F3636CA85A9FFEFB50B4BB27302A5CC0AB6E2F959BF20D320C373C2128D0A0CE
7072B1F672A0AA38C3C0ECEB04B44CB174A1C31612D71FFA20C90954256378372F795B0B
F2941F437F059F41AE0598C00515FEF187333557F32CE32A9EE7D4BAB65DA5343F92707E
2CFCF3E8CE446E5ADAC39FC37ECE64B68B356CE0D710F45B1E7F2CD768ABCA1436083668
761A1009464162D054C1F6BF2C46A319B3C66452876316C13A926456D3662958FD56740D
5856736E6104F813ED319156777934EEB1C5445AE6BF6EE59E5B19708B4287DB4B9BAF98
8291ABC06FDE77FCC3171998C232F68CABD46E44407B24B00A678AF97E78848BB7C0BD2C
BDD5674061220B1FB375A940FA7BD5451B21580BEE1C29092A5F3E43CEF0603FA05829CE
2F5D860ADBCC576BA2720B9F9BE9C3684F5B674B29FAA4624B83864A788C4967AA263B87
00B168B5D4F0FBE28B3B0FA3F6B3D1C98545943F2E161E2D6855B0513E4F39684A36F5B1
A3B37E16C80995442FD52F864941F1C520133C3E04686829208B4127D475F9693EDBF069
91D4D4D4E1536AD1D73366E5E0A27AC8FF0742910CF30163437ACDB3DA3212D2688E683B
4002F88A32AF4E7723E3AE6C0D598913243BDB47DF8D3E79B691A806E221690EA206A4A6
A2077B8324432D79C8A7A99119473022D8EBEF09843606EE962171D21099668EACB6FDD5
5417981D20FCA178A14A43A709829127E431CABB7054ECC2356E1049490410774E57BEB8
5D51A3F2A63BA5AC60295A9BF38F9B2BE9893B357F9BDEFA2B880BF35937AD32A36775F6
038449BE4054B95BAC6B86F2C6DC1989FD377E8B151B4BE9A6A6BB05F195518DE7AA8A4F
38A20A038110D69A7E556634AE7D7FBD5F5C4041C6A4E44698392270F8845F6212EE1483
30248FEEB732D4E5EC3BD7D4B04A268285800A2919960B1F99310F9A1768287150CF53BC
0FB7B2EA374BCEFA999189342679A54925C3B19F5BB38BFEE12429949AAD2512D9215C80
D67EE802E07B50DBC6547F3C37D89EC7C19D22089200AAFBB1AB624C499BC6B9226CA58E
7308B25E5D308000E58A59D0F608E8471A5D031A8BF36A6CFDD288D36E3625449DFB4284
CEDB8F2C33B0CA73FD4A36F7C67DBFD71DD91F2936D2667CEF9169EA6C55C24FA9CD62FC
8E4EA504DB3633AB6C5EE88D024853DE4BCA69476135E155639BBFD7FED2AB1F20127F1F
6FC846EAD110F1A4711C841FA92C6AA5023E3E074B3AE9CCEF3B9F23894430B8EBAC6186
4D77E8EC3F534EB235EDCB1344CF8CCE5AD7731B98D93CD1EA855D104048A0C97A1E33A9
4BD7E64467AA8EAABDEF8BA591190F6A39BD55EB6CA775A959079D6613745BE78A447ABD
AEC56668EF30677263CAFD8E8CAA3D8B26497A2F9706251C86B43319338AFF331CD45CDF
9EB93A67D7DCA12B75E6C5D42FEDD57F77E52B8DEC38548E4A39B2D2CD01593E84E08FE5
E10230D878F9934AD9F92A2B7CE07D9829DDC812D414D363A0C20928D31CDF2591C20BC6
BEA49757ACABCDC53BFE5DD96BFCB81AE0B94C441D96DD5462F033FE590E83CC7BC4578D
A6F812BB6B4026C0787E7A813E7E2277375B6348A4766F0B9C9D20BC67BA3BAD503B7DE6
9B42DC98270939CD00D4B64DAEB8C7413A29378C6671EECF38166BB06511F133955CD5FF
CAC8329A0C71059DD125724BB02F559BBB1E926D7E0B2A1D366D3277A388FC4A0A34CD17
5F37C3E6EFAF06098414C54E6845AEC38B7A1AF751DFD40C4C4CD3382241D8F6DFEA2175
5A2DC47632E5A8E5D74AD8D342A53568476837F7C4D70895521597E5C657EC9E4C9BA630
641FDC1AAC54A785EB47AD964CEA75091E5B89F4E70BD08EF0DDE90920312D62A9547DF5
7DE6675CF8C16CF8FAA263C6BC82CCF93734E91E6A547B3A65FC484777FE40F9B39B9809
BCB9588FF05C6C4F036F1AD7C6A8FBF77F7DE58E7676459017875607A01E2367305C6B00
926DEB916C5DA19BF3FA1C929B0360558BF9CBA7379003F2E1CDCA91D1A9EF8FAD5BD82F
1110034420DAEF5B922D93539F4BEF5A6E63A0A234FA035EAF8A3366DC1BAD6DD0BF0926
57AD441203AF67AF1C20CE3BFC1E878649B0417FEB9B51F52EB4FFE750BF2E628DEFD514
965F3F18FDA90F0F580675C532DA89FFA3DE5799F022FFB666918EE229477252577FD88D
0D92380743C421C29C1C395638D4C2BE78482F9059956A5800997E8BF9CA03528B67486B
6154CB4B84F793C9EF2CC8A0E5F1BDF20E2211A392656A59423CF4EA76711459A8160048
66AE99DF65E95D09653ADC9C1EF579E917131A2CB692792436F085AD54BB804F87F69464
815F2C10D404799C2FB491EC3CDFB42A7476DE3B02E7C9FBF92B11570161FA74C1A085DE
005880F696B140B35056FA3B77154901361EA904BD564A5371FB1A67ACCA00002B1BDDF9
B73D48B6F00DC7E8CA1553023A6CFED1E29CE12E7A443443620022BF9244489D2B0D676E
5C5EE900787ED320CC42A9C84909E1B83AE3626AFBE51B76B0313B1F22FF857B8E4D77BA
9DF69A709FB220CD31CEB47691E97B6FBBE93850CDC906404293B8374ACB65FF8EABC101
74A213E20008AE8A7600F949D767605F71EF3D98C44BA4B9CEA274AFBC151B1A3386E1A9
6F7B2F19F33474A40E23D27F02A1DFEBA951546CA6E13E5AD9EAC6478732128F871D3BDC
6EE40B10C0368616883F58D5CDDFDC12B54647C7E3E16EFCD575438857550E06B34138BE
AB7852D4DABB73B3A0B3EEFD3C341E56C4F2C9DF498A6B09C199611C7E62D466DBE73943
FF4095C412F6479C1F627FCEB0E6359F920A3CC691BCF4EB6E158C83B3F114FE3154F427
1B2A4FC323B02B288D76F522C8BBF90241F53AD25F492DC44607524C3F015D30C7D0665B
17129F182901790EC8DBF2E3876F54DB3D00AB964D9A734383548BBFDF843875AB24CE10
4A418AA081CBB0FEDE8D6D145D41EB26E1EE210A82FEE2069B185DA629EB7C352DAA0F49
4C4C005F4B8E5EA0ABD2457B3FF41E2DB77013B62D30A4754F9372A39AFA8233BC104146
5E9431F964843C7C14CF7F664CF6
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
cleartomark
%%EndFont
%%BeginSetup
%%PaperSize: A4
%%EndSetup
EOD
}

1;

__END__

=head1 NAME

App::Music::PlayTab::PostScript::Preamble - PostScript preamble.

=head1 DESCRIPTION

This is an internal module for the App::Music::PlayTab application.
