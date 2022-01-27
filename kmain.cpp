// io/flag/interrupt related
# include "mylowlevelfunc.hpp"

// vga_fonts
# include "font8x16.hpp"

// color related
// extern "C" void init_palette(void);
// extern "C" void set_palette(int start, int end, unsigned char *rgb);
// GUI related
// void boxfill8(char *vram, int xsize, int ysize, unsigned char c, int x0, int y0, int x1, int y1);
// void init_screen(char *vram, int xsize, int ysize);
// void putfont8(char *vram, int xsize, int x, int y, char c, unsigned char *font);
// void printStr(char *vram, int xsize, unsigned char color, char *c, int len, unsigned char *font);
# include "mystdio.hpp"




extern "C" void assemblyprint(void);
extern "C" void fin(void);
extern "C" void write_mem8(int addr, int data);



int main(){
    char *vram, strForTest[11]="", strForTest2[14]="LOS 1.0 Alpha";
    unsigned char i;
    int xsize, ysize;
    int tempAddr = 0;
    struct BOOTINFO *binfo;

    // int i;

    init_palette(); //set colors
    binfo = (struct BOOTINFO *) 0xff0; // 0xff0 is define at the top of loader.asm
    xsize = binfo->scrnx;
    ysize = binfo->scrny;
    vram = binfo->vram;
    init_screen(vram, binfo->scrnx, ysize); //draw basic windows desktop

    vga_font[0] += 0; // useless operation, fool the compiler
	
   
    // print "A"(ASCII 65) on the screen
    putfont8(vram, xsize, 0, 16*2, RED, vga_font + 1040);

    // print the memory address of vga_font onto the screen
    tempAddr = (int) vga_font;
    for (i = 0; i < 10; i++, tempAddr /= 10){
        strForTest[9-i] = tempAddr % 10 + '0';
    }
    
    printStr(vram, xsize, 0, 1, BLUE, strForTest, 10, vga_font);
    printStr(vram, xsize, 0, 4, BLUE, strForTest2, 52, vga_font);
    init_mouse_cursor(vram, xsize, xsize/2, ysize/2);
    fin();
    return 0;
}

