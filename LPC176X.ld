MEMORY
{
  BOOTLDR (rx) : ORIGIN = 0, LENGTH = 16K
  FLASH (rx) : ORIGIN = 16K, LENGTH = (512K - 48K)
  RAM (rwx) : ORIGIN = 0x10000000, LENGTH = (32K - 0x20)

  USB_RAM(rwx) : ORIGIN = 0x2007C000, LENGTH = 16K
  ETH_RAM(rwx) : ORIGIN = 0x20080000, LENGTH = 16K
}

ENTRY(Reset_Handler)

SECTIONS
{
    .ram_isr_vector :
    {
        _ram_start = .;
        . = 0x100;
    } > RAM
    .text :
    {
        KEEP(*(.isr_vector))
        *(.text*)

        KEEP(*(.init))
        KEEP(*(.fini))

        /* .ctors */
        *crtbegin.o(.ctors)
        *crtbegin?.o(.ctors)
        *(EXCLUDE_FILE(*crtend?.o *crtend.o) .ctors)
        *(SORT(.ctors.*))
        *(.ctors)

        /* .dtors */
        *crtbegin.o(.dtors)
        *crtbegin?.o(.dtors)
        *(EXCLUDE_FILE(*crtend?.o *crtend.o) .dtors)
        *(SORT(.dtors.*))
        *(.dtors)

        *(.rodata*)

        KEEP(*(.eh_frame*))
    } > BOOTLDR

    .ramcode :
    {
        __ramcode_flash_start = LOADADDR (.ramcode);
        __ramcode_ram_start = .;
        *(.glue_7t) *(glue_7)
        *(.ramcode*)
        . = ALIGN(4);
        __ramcode_ram_end = .;
    } > RAM AT > BOOTLDR

    .ARM.extab :
    {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    } > BOOTLDR

    __exidx_start = .;
    .ARM.exidx :
    {
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
    } > BOOTLDR
    __exidx_end = .;

    __etext = .;

    __user_flash_start = ORIGIN(FLASH);
    __user_flash_size  = LENGTH(FLASH);

    .data : AT (__etext)
    {
        __data_start__ = .;
        Image$$RW_IRAM1$$Base = .;
        *(vtable)
        *(.data*)

        . = ALIGN(4);
        /* preinit data */
        PROVIDE (__preinit_array_start = .);
        KEEP(*(.preinit_array))
        PROVIDE (__preinit_array_end = .);

        . = ALIGN(4);
        /* init data */
        PROVIDE (__init_array_start = .);
        KEEP(*(SORT(.init_array.*)))
        KEEP(*(.init_array))
        PROVIDE (__init_array_end = .);


        . = ALIGN(4);
        /* finit data */
        PROVIDE (__fini_array_start = .);
        KEEP(*(SORT(.fini_array.*)))
        KEEP(*(.fini_array))
        PROVIDE (__fini_array_end = .);

        . = ALIGN(4);
        /* All data end */
        __data_end__ = .;

    } > RAM

    .bss :
    {
        __bss_start__ = .;
        *(.bss*)
        *(COMMON)
        __bss_end__ = .;
        Image$$RW_IRAM1$$ZI$$Limit = . ;
    } > RAM

    .heap :
    {
        __end__ = .;
        end = __end__;
        *(.heap*)
        __HeapLimit = .;
    } > RAM

    /* .stack_dummy section doesn't contains any symbols. It is only
     * used for linker to calculate size of stack sections, and assign
     * values to stack symbols later */
    .stack_dummy :
    {
        *(.stack)
    } > RAM

    /* Set stack top to end of RAM, and stack limit move down by
     * size of stack_dummy section */
    __StackTop = ORIGIN(RAM) + LENGTH(RAM);
    __StackLimit = __StackTop - SIZEOF(.stack_dummy);
    PROVIDE(__stack = __StackTop);
    PROVIDE(__heapLimit = __HeapLimit);
    PROVIDE(__stackSize = __StackTop - __HeapLimit);

    /* Area of memory, heap and stack, to fill on startup - 8 bytes at a time. */
    __FillStart = ALIGN(__end__, 8);

    /* Check if data + heap + stack exceeds RAM limit */
    ASSERT(__StackLimit >= __HeapLimit, "region RAM overflowed with stack")


    /* Code can explicitly ask for data to be
       placed in these higher RAM banks where
       they will be left uninitialized.
    */
    .AHBSRAM0 (NOLOAD):
    {
        Image$$RW_IRAM2$$Base = . ;
        PROVIDE(__AHB0_block_start = .);
        *(AHBSRAM0)
        Image$$RW_IRAM2$$ZI$$Limit = .;
        PROVIDE(__AHB0_dyn_start = .);
        PROVIDE(__AHB0_end = ORIGIN(USB_RAM) + LENGTH(USB_RAM));
    } > USB_RAM

    .AHBSRAM1 (NOLOAD):
    {
        Image$$RW_IRAM3$$Base = . ;
        PROVIDE(__AHB1_block_start = .);
        *(AHBSRAM1)
        Image$$RW_IRAM3$$ZI$$Limit = .;
        PROVIDE(__AHB1_dyn_start = .);
        PROVIDE(__AHB1_end = ORIGIN(ETH_RAM) + LENGTH(ETH_RAM));
    } > ETH_RAM
}
