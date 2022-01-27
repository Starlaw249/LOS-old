/*
All funcions in this header file are implemented in func.asm
*/
#ifndef mylowlevelfunc
#define mylowlevelfunc
extern "C" void io_sti(void); 
extern "C" void io_hlt(void); // hlt
extern "C" void io_cli(void); // cli
extern "C" void io_out8(int port, int data);
extern "C" int io_load_eflags(void);
extern "C" void io_store_eflags(int eflags);
#endif