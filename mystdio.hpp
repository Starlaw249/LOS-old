#ifndef mystdio
#define mystdio

# include "mylowlevelfunc.hpp"

#ifndef COLORCONSTS
#define COLORCONSTS
#define BLACK 0
#define RED 1
#define GREEN 2
#define YELLOW 3
#define BLUE 4
#define PURPLE 5
#define LIGHTBLUE  6
#define WHITE 7
#define LIGHTGREY 8
#define DARKRED 9
#define DARKGREEN 10
#define DARKYELLOW 11
#define DARKBLUE 12
#define DARKPURPLE 13
#define LIGHTDARKBLUE 14
#define DARKGREY 15
#endif

/* structure for screen related info */
struct BOOTINFO {
    // all variables are of 8 bits. Order cares.
    char cyls, leds, vmode, reserve;
    short scrnx, scrny;
    char *vram;
};

char mousebg[16][16]; // buffer for the original background at the mouse's location


// color related
void init_palette(void);
void set_palette(int start, int end, unsigned char *rgb);
// GUI related
void boxfill8(char *vram, int xsize, int ysize, unsigned char c, int x0, int y0, int x1, int y1);
void init_screen(char *vram, int xsize, int ysize);
void putfont8(char *vram, int xsize, int x, int y, char c, unsigned char *font);
void printStr(char *vram, int xsize, int x, int y, unsigned char color, char *c, int len, unsigned char *font);

void init_mouse_cursor(char *vram,int xsize, int x,int y);
void putblock8x8(char *vram, int vxsize, int pxsize, int pysize, int px0, int py0, char *buf, int bxsize);
void getblock8x8(char *vram, int vxsize, int pxsize, int pysize, int px0, int py0, char *buf, int bxsize);


/* Source code */
void init_palette(void){
    // customized color map
    static unsigned char table_rgb[16 * 3] = {
        0x00, 0x00, 0x00, // 0: black
        0xff, 0x00, 0x00, // 1: red
        0x00, 0xff, 0x00, // 2. green
        0xff, 0xff, 0x00, // 3. yellow
        0x00, 0x00, 0xff, // 4. blue
        0xff, 0x00, 0xff, // 5. purple
        0x00, 0xff, 0xff, // 6. light blue
        0xff, 0xff, 0xff, // 7, white
        0xc6, 0xc6, 0xc6, // 8. light grey
        0x84, 0x00, 0x00, // 9. dark red
        0x00, 0x84, 0x00, // 10, dark green
        0x84, 0x84, 0x00, // 11. dark yellow
        0x00, 0x00, 0x84, // 12. dark blue
        0x84, 0x00, 0x84, // 13. dark purple
        0x00, 0x84, 0x84, // 14. light dark blue
        0x84, 0x84, 0x84  // 15. dark grey
    };
    set_palette(0, 15, table_rgb);
    return;
}

void set_palette(int start, int end, unsigned char *rgb){
    /*
    * following video DA converter rule to set palette
    */
    int i, eflags;
    eflags = io_load_eflags();  // store current flags
    io_cli();                   // temporarily prevent interruptions
    io_out8(0x03c8, start);
    for(i=start; i<= end; i++){
        io_out8(0x03c9, rgb[0]/4);
        io_out8(0x03c9, rgb[1]/4);
        io_out8(0x03c9, rgb[2]/4);
        rgb += 3;
    }
    io_store_eflags(eflags);    //restore flags
    // io_sti();
    return;
}

void boxfill8(char *vram, int xsize, int ysize, unsigned char c, int x0, int y0, int x1, int y1){
    /*
    * This function will draw a box (rectangle) on the screen which has width xsize
    * c is for color
    * (x0, y0) and (x1, y1) are two diagonals of the box. These are absolute coordinates
    */
    int x, y;
    x0 = x0 < 0 ? xsize + x0 : x0;
    y0 = y0 < 0 ? ysize + y0 : y0;
    x1 = x1 < 0 ? xsize + x1 : x1;
    y1 = y1 < 0 ? ysize + y1 : y1;
    if(y0 > y1){
        y = y0; y0 = y1; y1 = y;
    }
    if(x0 > x1){
        x = x0; x0 = x1; x1 = x;
    }

    for (y = y0; y <= y1; y++){
        for(x = x0; x <= x1; x++){
            vram[y * xsize + x] = c;
        }
    }
}

void init_screen(char *vram, int xsize, int ysize){
    boxfill8(vram, xsize, ysize, LIGHTDARKBLUE,  0,     0,   -1,  -19);
	boxfill8(vram, xsize, ysize, LIGHTGREY,      0,   -18,   -1,  -18);
	boxfill8(vram, xsize, ysize, WHITE,          0,   -17,   -1,  -17);
	boxfill8(vram, xsize, ysize, LIGHTGREY,      0,   -16,   -1,   -1);

	boxfill8(vram, xsize, ysize, WHITE,          3,   -14,   59,  -14);
	boxfill8(vram, xsize, ysize, WHITE,          2,   -14,    2,   -4);
	boxfill8(vram, xsize, ysize, DARKGREY,       3,    -4,   59,   -4);
	boxfill8(vram, xsize, ysize, DARKGREY,      59,   -13,   59,   -5);
	boxfill8(vram, xsize, ysize, BLACK,          2,    -3,   59,   -3);
	boxfill8(vram, xsize, ysize, BLACK,         60,   -14,   60,   -3);

	boxfill8(vram, xsize, ysize, DARKGREY,     -47,  -14,   -4,   -14);
	boxfill8(vram, xsize, ysize, DARKGREY,     -47,  -13,  -47,    -4);
	boxfill8(vram, xsize, ysize, WHITE,        -47,   -3,   -4,    -3);
	boxfill8(vram, xsize, ysize, WHITE,         -3,  -14,   -3,    -3);
}

void putfont8(char *vram, int xsize, int x, int y, char color, unsigned char *font){
	int i;
	char *p, d /* data */;
	for (i = 0; i < 16; i++) {
		p = vram + (y + i) * xsize + x;
		d = font[i];
        // set the color for the corresponding 8 pixels.
		if ((d & 0x80) != 0) { p[0] = color; }
		if ((d & 0x40) != 0) { p[1] = color; }
		if ((d & 0x20) != 0) { p[2] = color; }
		if ((d & 0x10) != 0) { p[3] = color; }
		if ((d & 0x08) != 0) { p[4] = color; }
		if ((d & 0x04) != 0) { p[5] = color; }
		if ((d & 0x02) != 0) { p[6] = color; }
		if ((d & 0x01) != 0) { p[7] = color; }
	}
	return;
}

// no auto wrap
// x, and y are the index of charactor location on the screen.
// x = 1 => pixel location x * 8
// y = 2 => pixel location y * 16
void printStr(char *vram, int xsize, int x, int y, unsigned char color, char *c, int len, unsigned char *font){
    int i, x_, y_; // x_ and y_ are for the actual text pixel location
    for(i = 0; i < len; i++){
        x_ = (i*8 + x * 8) % xsize;
        y_ = y*16 + (i*8 + x * 8) / xsize * 16;
        putfont8(vram, xsize, x_, y_, color, font + c[i]*16);
    }
}



/* mouse */
// void init_mouse_cursor(char *vram,int xsize, int x,int y,char bc){
void init_mouse_cursor(char *vram,int xsize, int x,int y){
    // bc += 0;
	//16*16 Mouse
    //鼠标指针点阵
	static char cursor[16][17] = {
	 "*...............",
	 "**..............",
	 "*O*.............",
	 "*OO*............",
	 "*OOO*...........",
	 "*OOOO*..........",
	 "*OOOOO*.........",
	 "*OOOOOO*........",
	 "*OOOOOOO*.......",
	 "*OOOO*****......",
	 "*OO***..........",
	 "*O*.............",
	 "**..............",
	 "*...............",
	 "................",
	 "................"
	};
	
	for (int i = 0; i < 16; i++) {
		for (int j = 0; j < 16; j++) {
			int off = (i+y)*xsize+x+j;
            mousebg[i][j] = vram[off];
			if (cursor[i][j] == '*') {
				vram[off] = BLACK;
			}
			if (cursor[i][j] == 'O') {
				vram[off] = WHITE;
			}
			if (cursor[i][j] == '.') {
				// vram[off] = bc;
			}
		}
	}

}

/* put buf contents back to vram*/
void putblock8x8(char *vram, int vxsize, int pxsize, int pysize, int px0, int py0, char *buf, int bxsize){
    int x, y;
    for(y = 0; y < pysize; y++){
        for(x = 0; x < pxsize; x++){
            vram[(py0+y) * vxsize + (px0 + x)] = buf[y * bxsize + x];
        }
    }
}

/* get buf contents from vram*/
void getblock8x8(char *vram, int vxsize, int pxsize, int pysize, int px0, int py0, char *buf, int bxsize){
    int x, y;
    for(y = 0; y < pysize; y++){
        for(x = 0; x < pxsize; x++){
            buf[y * bxsize + x] = vram[(py0+y) * vxsize + (px0 + x)];
        }
    }
}

#endif