; Originally from:
;	Tiny Font
;	From: http://www.rinkydinkelectronics.com/dlfont.php?id=22
;	Author: MasterMushi
;
; Extended with additional glyphs

db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; <Space>
db	0x18,0x3C,0x3C,0x18,0x18,0x00,0x18,0x00		; !
db	0x66,0x66,0x24,0x00,0x00,0x00,0x00,0x00		; "
db	0x6C,0x6C,0xFE,0x6C,0xFE,0x6C,0x6C,0x00		; #
db	0x18,0x3E,0x60,0x3C,0x06,0x7C,0x18,0x00		; $
db	0x00,0xC6,0xCC,0x18,0x30,0x66,0xC6,0x00		; %
db	0x38,0x6C,0x38,0x76,0xDC,0xCC,0x76,0x00		; &
db	0x18,0x18,0x30,0x00,0x00,0x00,0x00,0x00		; '
db	0x0C,0x18,0x30,0x30,0x30,0x18,0x0C,0x00		; (
db	0x30,0x18,0x0C,0x0C,0x0C,0x18,0x30,0x00		; )
db	0x00,0x66,0x3C,0xFF,0x3C,0x66,0x00,0x00		; *
db	0x00,0x18,0x18,0x7E,0x18,0x18,0x00,0x00		; +
db	0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x30		; ,
db	0x00,0x00,0x00,0x7E,0x00,0x00,0x00,0x00		; -
db	0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x00		; .
db	0x06,0x0C,0x18,0x30,0x60,0xC0,0x80,0x00		; /
db	0x7C,0xC6,0xCE,0xD6,0xE6,0xC6,0x7C,0x00		; 0
db	0x18,0x38,0x18,0x18,0x18,0x18,0x7E,0x00		; 1
db	0x7C,0xC6,0x06,0x1C,0x30,0x66,0xFE,0x00		; 2
db	0x7C,0xC6,0x06,0x3C,0x06,0xC6,0x7C,0x00		; 3
db	0x1C,0x3C,0x6C,0xCC,0xFE,0x0C,0x1E,0x00		; 4
db	0xFE,0xC0,0xC0,0xFC,0x06,0xC6,0x7C,0x00		; 5
db	0x38,0x60,0xC0,0xFC,0xC6,0xC6,0x7C,0x00		; 6
db	0xFE,0xC6,0x0C,0x18,0x30,0x30,0x30,0x00		; 7
db	0x7C,0xC6,0xC6,0x7C,0xC6,0xC6,0x7C,0x00		; 8
db	0x7C,0xC6,0xC6,0x7E,0x06,0x0C,0x78,0x00		; 9
db	0x00,0x18,0x18,0x00,0x00,0x18,0x18,0x00		; :
db	0x00,0x18,0x18,0x00,0x00,0x18,0x18,0x30		; ;
db	0x06,0x0C,0x18,0x30,0x18,0x0C,0x06,0x00		; <
db	0x00,0x00,0x7E,0x00,0x00,0x7E,0x00,0x00		; =
db	0x60,0x30,0x18,0x0C,0x18,0x30,0x60,0x00		; >
db	0x7C,0xC6,0x0C,0x18,0x18,0x00,0x18,0x00		; ?
db	0x7C,0xC6,0xDE,0xDE,0xDE,0xC0,0x78,0x00		; @
db	0x38,0x6C,0xC6,0xFE,0xC6,0xC6,0xC6,0x00		; A
db	0xFC,0x66,0x66,0x7C,0x66,0x66,0xFC,0x00		; B
db	0x3C,0x66,0xC0,0xC0,0xC0,0x66,0x3C,0x00		; C
db	0xF8,0x6C,0x66,0x66,0x66,0x6C,0xF8,0x00		; D
db	0xFE,0x62,0x68,0x78,0x68,0x62,0xFE,0x00		; E
db	0xFE,0x62,0x68,0x78,0x68,0x60,0xF0,0x00		; F
db	0x3C,0x66,0xC0,0xC0,0xCE,0x66,0x3A,0x00		; G
db	0xC6,0xC6,0xC6,0xFE,0xC6,0xC6,0xC6,0x00		; H
db	0x3C,0x18,0x18,0x18,0x18,0x18,0x3C,0x00		; I
db	0x1E,0x0C,0x0C,0x0C,0xCC,0xCC,0x78,0x00		; J
db	0xE6,0x66,0x6C,0x78,0x6C,0x66,0xE6,0x00		; K
db	0xF0,0x60,0x60,0x60,0x62,0x66,0xFE,0x00		; L
db	0xC6,0xEE,0xFE,0xFE,0xD6,0xC6,0xC6,0x00		; M
db	0xC6,0xE6,0xF6,0xDE,0xCE,0xC6,0xC6,0x00		; N
db	0x7C,0xC6,0xC6,0xC6,0xC6,0xC6,0x7C,0x00		; O
db	0xFC,0x66,0x66,0x7C,0x60,0x60,0xF0,0x00		; P
db	0x7C,0xC6,0xC6,0xC6,0xC6,0xCE,0x7C,0x0E		; Q
db	0xFC,0x66,0x66,0x7C,0x6C,0x66,0xE6,0x00		; R
db	0x7C,0xC6,0x60,0x38,0x0C,0xC6,0x7C,0x00		; S
db	0x7E,0x7E,0x5A,0x18,0x18,0x18,0x3C,0x00		; T
db	0xC6,0xC6,0xC6,0xC6,0xC6,0xC6,0x7C,0x00		; U
db	0xC6,0xC6,0xC6,0xC6,0xC6,0x6C,0x38,0x00		; V
db	0xC6,0xC6,0xC6,0xD6,0xD6,0xFE,0x6C,0x00		; W
db	0xC6,0xC6,0x6C,0x38,0x6C,0xC6,0xC6,0x00		; X
db	0x66,0x66,0x66,0x3C,0x18,0x18,0x3C,0x00		; Y
db	0xFE,0xC6,0x8C,0x18,0x32,0x66,0xFE,0x00		; Z
db	0x3C,0x30,0x30,0x30,0x30,0x30,0x3C,0x00		; [
db	0xC0,0x60,0x30,0x18,0x0C,0x06,0x02,0x00		; <Backslash>
db	0x3C,0x0C,0x0C,0x0C,0x0C,0x0C,0x3C,0x00		; ]
db	0x10,0x38,0x6C,0xC6,0x00,0x00,0x00,0x00		; ^
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFF		; _
db	0x30,0x18,0x0C,0x00,0x00,0x00,0x00,0x00		; '
db	0x00,0x00,0x78,0x0C,0x7C,0xCC,0x76,0x00		; a
db	0xE0,0x60,0x7C,0x66,0x66,0x66,0xDC,0x00		; b
db	0x00,0x00,0x7C,0xC6,0xC0,0xC6,0x7C,0x00		; c
db	0x1C,0x0C,0x7C,0xCC,0xCC,0xCC,0x76,0x00		; d
db	0x00,0x00,0x7C,0xC6,0xFE,0xC0,0x7C,0x00		; e
db	0x3C,0x66,0x60,0xF8,0x60,0x60,0xF0,0x00		; f
db	0x00,0x00,0x76,0xCC,0xCC,0x7C,0x0C,0xF8		; g
db	0xE0,0x60,0x6C,0x76,0x66,0x66,0xE6,0x00		; h
db	0x18,0x00,0x38,0x18,0x18,0x18,0x3C,0x00		; i
db	0x06,0x00,0x06,0x06,0x06,0x66,0x66,0x3C		; j
db	0xE0,0x60,0x66,0x6C,0x78,0x6C,0xE6,0x00		; k
db	0x38,0x18,0x18,0x18,0x18,0x18,0x3C,0x00		; l
db	0x00,0x00,0xEC,0xFE,0xD6,0xD6,0xD6,0x00		; m
db	0x00,0x00,0xDC,0x66,0x66,0x66,0x66,0x00		; n
db	0x00,0x00,0x7C,0xC6,0xC6,0xC6,0x7C,0x00		; o
db	0x00,0x00,0xDC,0x66,0x66,0x7C,0x60,0xF0		; p
db	0x00,0x00,0x76,0xCC,0xCC,0x7C,0x0C,0x1E		; q
db	0x00,0x00,0xDC,0x76,0x60,0x60,0xF0,0x00		; r
db	0x00,0x00,0x7E,0xC0,0x7C,0x06,0xFC,0x00		; s
db	0x30,0x30,0xFC,0x30,0x30,0x36,0x1C,0x00		; t
db	0x00,0x00,0xCC,0xCC,0xCC,0xCC,0x76,0x00		; u
db	0x00,0x00,0xC6,0xC6,0xC6,0x6C,0x38,0x00		; v
db	0x00,0x00,0xC6,0xD6,0xD6,0xFE,0x6C,0x00		; w
db	0x00,0x00,0xC6,0x6C,0x38,0x6C,0xC6,0x00		; x
db	0x00,0x00,0xC6,0xC6,0xC6,0x7E,0x06,0xFC		; y
db	0x00,0x00,0x7E,0x4C,0x18,0x32,0x7E,0x00		; z
db	0x0E,0x18,0x18,0x70,0x18,0x18,0x0E,0x00		; {
db	0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x00		; |
db	0x70,0x18,0x18,0x0E,0x18,0x18,0x70,0x00		; }
db	0x76,0xDC,0x00,0x00,0x00,0x00,0x00,0x00		; ~
; Extended character set (Code Page 437... ish)
; Referenced: https://github.com/rene-d/font8x8/blob/master/font8x8_box.h
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (128) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (129) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (130) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (131) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (132) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (133) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (134) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (135) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (136) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (137) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (138) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (139) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (140) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (141) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (142) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (143) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (144) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (145) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (146) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (147) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (148) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (149) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (150) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (151) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (152) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (153) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (154) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (155) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (156) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (157) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (158) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (159) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (160) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (161) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (162) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (163) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (164) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (165) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (166) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (167) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (168) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (169) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (170) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (171) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (172) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (173) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (174) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (175) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (176) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (177) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (178) 
db	0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10		; (179) Vertical
db	0x10,0x10,0x10,0x10,0xf0,0x10,0x10,0x10		; (180) Vertical, left
db	0x10,0x10,0x10,0xf0,0x10,0xf0,0x10,0x10		; (181) Vertical, double left
db	0x28,0x28,0x28,0x28,0xe8,0x28,0x28,0x28		; (182) Double vertical, middle left
db	0x00,0x00,0x00,0x00,0xf8,0x28,0x28,0x28		; (183) Left, double down
db	0x00,0x00,0x00,0xf0,0x10,0xf0,0x10,0x10		; (184) Double left, down
db	0x28,0x28,0x28,0xe8,0x08,0xe8,0x28,0x28		; (185) Double vertical, double left
db	0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28		; (186) Double vertical
db	0x00,0x00,0x00,0xf8,0x08,0xe8,0x28,0x28		; (187) Double left, double down
db	0x28,0x28,0x28,0xe8,0x08,0xf8,0x00,0x00		; (188) Double left, double up
db	0x28,0x28,0x28,0x28,0xf8,0x00,0x00,0x00		; (189) Left, double up
db	0x10,0x10,0x10,0xf0,0x10,0xf0,0x00,0x00		; (190) Double left, up
db	0x00,0x00,0x00,0x00,0xf0,0x10,0x10,0x10		; (191) Left, down
db	0x10,0x10,0x10,0x10,0x1f,0x00,0x00,0x00		; (192) Up, right
db	0x10,0x10,0x10,0x10,0xff,0x00,0x00,0x00		; (193) Horizontal, up
db	0x00,0x00,0x00,0x00,0xff,0x10,0x10,0x10		; (194) Horizontal, down
db	0x10,0x10,0x10,0x10,0x1f,0x10,0x10,0x10		; (195) Vertical, right
db	0x00,0x00,0x00,0x00,0xff,0x00,0x00,0x00		; (196) Horizontal
db	0x10,0x10,0x10,0x10,0xff,0x10,0x10,0x10		; (197) Horizontal, vertical
db	0x10,0x10,0x10,0x1f,0x10,0x1f,0x10,0x10		; (198) Vertical, double right
db	0x28,0x28,0x28,0x28,0x2f,0x28,0x28,0x28		; (199) Double vertical, right
db	0x28,0x28,0x28,0x2f,0x20,0x3f,0x00,0x00		; (200) Double up, double right
db	0x00,0x00,0x00,0x3f,0x20,0x2f,0x28,0x28		; (201) Double down, double right
db	0x28,0x28,0x28,0xef,0x00,0xff,0x00,0x00		; (202) Double horizontal, double up
db	0x00,0x00,0x00,0xff,0x00,0xef,0x28,0x28		; (203) Double horizontal, double down
db	0x28,0x28,0x28,0x2f,0x20,0x2f,0x28,0x28		; (204) Double vertical, double right
db	0x00,0x00,0x00,0xff,0x00,0xff,0x00,0x00		; (205) Double horizontal
db	0x28,0x28,0x28,0xef,0x00,0xef,0x28,0x28		; (206) Double horizontal, double vertical
db	0x10,0x10,0x10,0xff,0x00,0xff,0x00,0x00		; (207) Double horizontal, up
db	0x28,0x28,0x28,0x28,0xff,0x00,0x00,0x00		; (208) Horizontal, double up
db	0x00,0x00,0x00,0xff,0x00,0xff,0x10,0x10		; (209) Double horizontal, down
db	0x00,0x00,0x00,0x00,0xff,0x28,0x28,0x28		; (210) Horizontal, double down
db	0x28,0x28,0x28,0x28,0x3f,0x00,0x00,0x00		; (211) Double up, right
db	0x10,0x10,0x10,0x1f,0x10,0x1f,0x00,0x00		; (212) Up, double right
db	0x00,0x00,0x00,0x1f,0x10,0x1f,0x10,0x10		; (213) Down, double right
db	0x00,0x00,0x00,0x00,0x3f,0x28,0x28,0x28		; (214) Double down, right
db	0x28,0x28,0x28,0x28,0xff,0x28,0x28,0x28		; (215) Horizontal, double vertical
db	0x10,0x10,0x10,0xff,0x10,0xff,0x10,0x10		; (216) Double horizontal, vertical
db	0x10,0x10,0x10,0x10,0xf0,0x00,0x00,0x00		; (217) Left, up
db	0x00,0x00,0x00,0x00,0x1f,0x10,0x10,0x10		; (218) Down, right
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (219) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (220) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (221) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (222) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (223) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (224) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (225) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (226) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (227) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (228) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (229) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (230) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (231) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (232) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (233) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (234) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (235) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (236) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (237) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (238) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (239) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (240) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (241) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (242) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (243) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (244) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (245) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (246) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (247) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (248) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (249) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (250) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (251) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (252) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (253) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (254) 
db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00		; (255) 
