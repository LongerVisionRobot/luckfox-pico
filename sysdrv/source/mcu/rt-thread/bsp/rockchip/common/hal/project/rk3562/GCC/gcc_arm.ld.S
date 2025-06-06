/* SPDX-License-Identifier: BSD-3-Clause */
/*
 * Copyright (c) 2023 Rockchip Electronics Co., Ltd.
 */

/* Program Entry, set to mark it as "used" and avoid gc */

#include "hal_conf.h"

MEMORY
{
    SRAM  (rxw) : ORIGIN = SRAM_BASE, LENGTH = SRAM_SIZE        /* SYSTEM SRAM */
#ifdef NC_MEM_SIZE
    DRAM  (rxw) : ORIGIN = FIRMWARE_BASE, LENGTH = DRAM_SIZE - NC_MEM_SIZE   /* DRAM */
    NCRAM (rxw) : ORIGIN = NC_MEM_BASE, LENGTH =  NC_MEM_SIZE   /* NCRAM */
#else
    DRAM  (rxw) : ORIGIN = FIRMWARE_BASE, LENGTH = DRAM_SIZE    /* DRAM */
#endif
    SHMEM (rxw) : ORIGIN = SHMEM_BASE, LENGTH = SHMEM_SIZE      /* shared memory for all cpu */
    LINUX_RPMSG (rxw) : ORIGIN = LINUX_RPMSG_BASE, LENGTH = LINUX_RPMSG_SIZE /* shared memory for linux rpmsg */
}

ENTRY(Reset_Handler)

__STACK_SIZE = 0x400;
__FIQ_STACK_SIZE = 0x400;
__IRQ_STACK_SIZE = 0x400;
__SVC_STACK_SIZE = 0x1000;
__ABT_STACK_SIZE = 0x400;
__UND_STACK_SIZE = 0x400;

__TTB_SIZE = 0x4000;
__SPINLOCK_MEM_SIZE = 0x100;
__SHARE_RPMSG_SIZE = 0x80000;

SECTIONS
{
    .text :
    {
        KEEP(*(RESET))                  /* Startup code */
        _stext = .;
        . = ALIGN(16);
        *(.text)                        /* remaining code */
        *(.text.*)                      /* remaining code */
        *(.rodata)                      /* read-only data (constants) */
        *(.rodata*)
        *(.glue_7)
        *(.glue_7t)
        *(.gnu.linkonce.t*)

        . = ALIGN(16);
        _etext = .;
    } > DRAM

    .ARM.extab :
    {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    } > DRAM

    __exidx_start = .;
    .ARM.exidx :
    {
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)

        /* This is used by the startup in order to initialize the .data secion */
        _sidata = .;
    } > DRAM
    __exidx_end = .;

    .zero.table :
    {
        . = ALIGN(4);
        __zero_table_start__ = .;
        LONG (__bss_start__)
        LONG ((__bss_end__ - __bss_start__) / 4)
        LONG (__TTB_start__)
        LONG ((__TTB_end__ - __TTB_start__) / 4)
#ifdef PRIMARY_CPU
        LONG (ADDR(.share_lock))
        LONG (SIZEOF(.share_lock) / 4)
#endif
        __zero_table_end__ = .;
    } > DRAM

    .copy.table :
    {
        . = ALIGN(4);
        __copy_table_start__ = .;
#ifdef PRIMARY_CPU
        LONG (LOADADDR(.share_data))
        LONG (ADDR(.share_data))
        LONG (SIZEOF(.share_data) / 4)
#endif
        __copy_table_end__ = .;
    } > DRAM

    . = ALIGN(4);

    .data :
    {
        *(.data)
        *(.data.*)

        . = ALIGN(16);
        *(.sdata)
        *(.sdata.*)
    } > DRAM

    . = ALIGN(16);

    .ctors :
    {
        PROVIDE(__ctors_start__ = .);
        KEEP(*(SORT(.ctors.*)))
        KEEP(*(.ctors))
        PROVIDE(__ctors_end__ = .);
    } > DRAM

    .dtors :
    {
        PROVIDE(__dtors_start__ = .);
        KEEP(*(SORT(.dtors.*)))
        KEEP(*(.dtors))
        PROVIDE(__dtors_end__ = .);
    } > DRAM

    .ttb :
    {
        . = ALIGN(16 * 1024);
        PROVIDE(__TTB_start__ = .);
        PROVIDE(MMUTable  = .);
        . += __TTB_SIZE;
        PROVIDE(__TTB_end__ = .);
        . = ALIGN(16 * 1024);
    } > DRAM

    .share_lock (NOLOAD):
    {
        . = ALIGN(64);
        PROVIDE(__spinlock_mem_start__ = .);
        . += __SPINLOCK_MEM_SIZE;
        PROVIDE(__spinlock_mem_end__ = .);
        . = ALIGN(64);
    } > SHMEM

    .share_rpmsg (NOLOAD):
    {
        . = ALIGN(0x1000);
        PROVIDE(__share_rpmsg_start__ = .);
        . += __SHARE_RPMSG_SIZE;
        PROVIDE(__share_rpmsg_end__ = .);
        . = ALIGN(0x1000);
    } > SHMEM

    .share_data :
    {
        . = ALIGN(64);
        PROVIDE(__share_data_start__ = .);
        KEEP(*(.share_data))
        PROVIDE(__share_data_end__ = .);
        . = ALIGN(64);
    } > SHMEM AT > DRAM

    .linux_share_rpmsg (NOLOAD):
    {
        PROVIDE(__linux_share_rpmsg_start__ = .);
        . += LINUX_RPMSG_SIZE;
        PROVIDE(__linux_share_rpmsg_end__ = .);
    } > LINUX_RPMSG

    . = ALIGN(16);
    .bss (NOLOAD) :
    {
        PROVIDE(__bss_start__ = .);
        *(.bss)
        *(.bss.*)
        *(.dynbss)
        *(COMMON)
        . = ALIGN(16);
        PROVIDE(__bss_end__ = .);
    } > DRAM
    _end = .;
   PROVIDE(end = .);

    /* The heap is between bss_end and stack_start */
    . = ALIGN(16);
    __ALL_STACK_SIZE = __STACK_SIZE + __FIQ_STACK_SIZE + __IRQ_STACK_SIZE + __SVC_STACK_SIZE + __ABT_STACK_SIZE + __UND_STACK_SIZE;
    __STACK_START = ORIGIN(DRAM) + LENGTH(DRAM) - __ALL_STACK_SIZE;
    __HEAP_SIZE = (__STACK_START - .);
    .heap :
    {
        PROVIDE(__heap_start = .);
        . += __HEAP_SIZE;
        PROVIDE(__heap_end = .);
    } > DRAM

    .stack __STACK_START :
    {
        . = ALIGN(16);

        PROVIDE(__StackTop = .);
        Image$$SYS_STACK$$ZI$$Base = .;
        . += __STACK_SIZE;
        Image$$SYS_STACK$$ZI$$Limit = .;
        __stack = .;

        Image$$FIQ_STACK$$ZI$$Base = .;
        . += __FIQ_STACK_SIZE;
        Image$$FIQ_STACK$$ZI$$Limit = .;

        Image$$IRQ_STACK$$ZI$$Base = .;
        . += __IRQ_STACK_SIZE;
        Image$$IRQ_STACK$$ZI$$Limit = .;

        Image$$SVC_STACK$$ZI$$Base = .;
        . += __SVC_STACK_SIZE;
        Image$$SVC_STACK$$ZI$$Limit = .;

        Image$$ABT_STACK$$ZI$$Base = .;
        . += __ABT_STACK_SIZE;
        Image$$ABT_STACK$$ZI$$Limit = .;

        Image$$UND_STACK$$ZI$$Base = .;
        . += __UND_STACK_SIZE;
        Image$$UND_STACK$$ZI$$Limit = .;

    } > DRAM

#ifdef NC_MEM_SIZE
    .ucheap (NOLOAD):
    {
        PROVIDE(__ucheap_start = .);
        . += NC_MEM_SIZE;
        PROVIDE(__ucheap_end = .);
    } > NCRAM
#endif
}

