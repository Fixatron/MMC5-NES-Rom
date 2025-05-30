; # Create a basic MMC5 test ROM main.asm that uses PRG Mode 0 and sets up basic memory

.segment "HEADER"
    .byte 'N', 'E', 'S', $1A      ; NES file magic
    .byte $20                    ; 32 x 16KB PRG = 512KB
    .byte $10                    ; 16 x 8KB CHR = 128KB
    .byte $30                    ; Mapper 5 (MMC5), vertical mirroring
    .byte $10                    ; Upper mapper bits
    .res 8, 0                    ; Padding

.segment "VECTORS"
    .word nmi
    .word reset
    .word irq

.segment "CODE3"
.proc reset
    SEI
    CLD
    LDX #$40
    STX $4017       ; Disable APU frame IRQ
    LDX #$FF
    TXS            ; Set up stack
    INX
    STX $2000       ; Disable NMI
    STX $2001       ; Disable rendering
    STX $4010       ; Disable DMC IRQs

    ; MMC5 setup
    LDA #$00
    STA $5115       ; PRG Mode 0 (4 x 8KB)

    ; Load test banks
    LDA #$00
    STA $5116       ; Bank 0 → $8000
    LDA #$01
    STA $5117       ; Bank 1 → $A000
    LDA #$02
    STA $5118       ; Bank 2 → $C000
    LDA #$03
    STA $5119       ; Bank 3 → $E000

    ; Wait for vblank
    BIT $2002
vblank_wait:
    BIT $2002
    BPL vblank_wait

forever:
    JMP forever
.endproc

.proc nmi
    RTI
.endproc

.proc irq
    RTI
.endproc

.segment "CODE0"
    .byte "BANK0 DATA HERE", 0

.segment "CODE1"
    .byte "BANK1 DATA HERE", 0

.segment "CODE2"
    .byte "BANK2 DATA HERE", 0
.segment "CHARS"
  .incbin "main.chr"