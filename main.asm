.export reset, nmi, irq

.segment "HEADER"
  .byte $4E,$45,$53,$1A
  .byte $02    ; 64kb PRG
  .byte $08    ; 128KB CHR
  .byte $50
  .byte $00
  .byte $00,$00,$00,$00,$00,$00,$00,$00
.segment "RODATA"
loading_nametable:
  .res 32 * 2, $00     ; top 2 rows = blank
  .byte $01, $02, $03, $04, $05, $06, $07, $08  ; "LOADING" in tiles 1–8
  .res 32 - 8, $00     ; rest of row
  .res (30 - 3) * 32, $00  ; rest of screen

.segment "VECTORS"
    .addr nmi
    .addr reset
    .addr irq
.segment "CODE0"
    .byte "BANK0 DATA HERE", 0

.segment "CODE1"
    .byte "BANK1 DATA HERE", 0

.segment "CODE2"
    .byte "BANK2 DATA HERE", 0

.segment "CODE3"
.proc reset
    SEI
    CLD
    LDX #$40
    STX $4017
    LDX #$FF
    TXS
    INX
    STX $2000
    STX $2001
    STX $4010       ; SET DMC IRQs?

    LDA #$00
    STA $4016       ; clear joypad strobe??  This seems like an odd place to do it since it doesn't read joy data here  =P
    STA $4015       ; turn off all sound channels
    STA $5015       ; turn off all sound channels (MMC5)

    STA $5010       ; disable MMC5 PCM and the IRQs it generates
    STA $5204       ; disable scanline IRQs
    STA $5130       ; high byte of bank

    STA $5200       ; disable split-screen mode)


    LDA #$FF
    STA $5117       ; this actually probably isn't strictly necessary, but documentation tells us that $5117 must have a reliable power-on value of $FF.
    LDA #$02
    STA $5102       ; enable PRG-RAM
    LDA #$01        ; "In order to enable writing to PRG RAM, this must be set to binary '01' (e.g. $01)."-NESDev
    STA $5103       ; enable PRG-RAM

    ; Set MMC5 PRG Mode 3 (4 x 8KB banks)
    LDA #$03      ; i want prgMode3, but that doesn't work. i need to use prg mode 0 1x32kb to get the 8kb banks to swap, otherwise the banks get swapped in with garbage data.
    STA $5100

    ; Assign 8KB PRG banks
    LDA #$80      ; high bit must be set for ROM 
    STA $5114
    LDA #$81
    STA $5115
    LDA #$82
    STA $5116
    ; LDA #$07
    ; STA $5117 redundant, this bank doesn't change, right?

    LDA #$03
    STA $5101   ; Set CHR bank size to 1 KB [03 is 8x8kb mode, 00 is 1x32kb mode]
    ; LDA #$01
    ; STA $5105   ; MMC5 CHR mode: 8KB background, 8KB sprite

    ; Tell MMC5 to use CHR-ROM banks
    LDA #$00
    STA $5120       ; PPU $0000–$03FF
    LDA #$01
    STA $5121 
    LDA #$02
    STA $5122 
    LDA #$03
    STA $5123 
    LDA #$04
    STA $5124 
    LDA #$05
    STA $5125 
    LDA #$06
    STA $5126 
    LDA #$07
    STA $5127 

    ; Wait for VBlank
    BIT $2002
vblank_wait:
    BIT $2002
    BPL vblank_wait

clear_memory:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne clear_memory
;; second wait for vblank, PPU is ready after this
vblankwait2:
  bit $2002
  bpl vblankwait2

main:
load_palettes:
  lda $2002
  lda #$3f
  sta $2006
  lda #$00
  sta $2006
  ldx #$00
@loop:
  lda palettes, x
  sta $2007
  inx
  cpx #$20
  bne @loop

    ; Enable background rendering
    LDA #%10000000
    STA $2000
    LDA #%00011110
    STA $2001

forever:
    JMP forever
.endproc

hello:
  .byte $00, $00, $00, $00 	; Why do I need these here?
  .byte $00, $00, $00, $00  ; https://www.nesdev.org/wiki/PPU_registers#OAMADDR_precautions
  .byte $6c, $00, $00, $6c  ; ^^^ probably why those blank ones are needed
  .byte $6c, $01, $00, $76
  .byte $6c, $02, $00, $80
  .byte $6c, $02, $00, $8A
  .byte $6c, $03, $00, $94

palettes:
  ; Background Palette
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00

  ; Sprite Palette
  .byte $0f, $20, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00

.proc nmi
  ldx #$00 	; Set SPR-RAM address to 0
  stx $2003
@loop:	lda hello, x 	; Load the hello message into SPR-RAM
  sta $2004
  inx
  cpx #$1c
  bne @loop
  rti
.endproc


.proc irq
    RTI
.endproc

.segment "CHARS"
  .incbin "CHR-ROM.chr"