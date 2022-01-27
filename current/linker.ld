/*
This is a linker script that tells the linker how to glue .o files into a binary.
The functionalities of .ld file include:
1. tell separate .o files the relative address to each other in the final file
2. create symbolic connection. E.g. the function used by file A is implemented in file B

This file uses linker command language.

Simple Tutorial: (Give credits to http://www.scoberlin.de/content/media/http/informatik/gcc_docs/ld_3.html)

SECTIONS: 
    SECTIONS is a tool that describe the memory layout of the output file. Similar to "ORG" in the assembly file, when linking multiple files, the linker should know where to put each segment. For a program containing only code (.text), initialized data (.data), and uninitialized data (.bss) sections respectively, and code is assumed to be loaded at 0x10000, data to be 0x8000000, the linker script looks like
    
    SECTIONS{
        .= 0x10000;              // mark the current location
        .text : { *(.text)}      // mark the section

        .= 0x8000000;
        .data : { *(.data) }
        .bss : { *(.bss) }
    }

ENTRY:
    ENTRY tells the OS where is the entry point. Something like the main() function in C/C++. It should be a symbol in assembly code.

OUTPUT_FORMAT:
    The OUTPUT_FORMAT command names the BFD format to use for the output file.  
    This can be omitted if explicitly specified using "--oformat binary" in the linking process with i386-elf-g++
*/
ENTRY(boot)
OUTPUT_FORMAT("binary")
SECTIONS {
	. = 0x7c00;
	.text :
	{
        *(.boot)
        *(.text)
	}
    
    .rodata :
    {
    	*(.rodata)
    }
    
    .data :
    {
    	*(.data)
    }

    .bss :
    {
    	*(.bss)
    }
}

