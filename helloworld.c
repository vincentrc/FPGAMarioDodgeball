
#include <stdio.h>
#include "xil_io.h"
#include "platform.h"
#include <math.h>

#define BaseAddress 0x43C00000
#define Reg0_Offset 0x00    // data in for RAM
#define Reg1_Offset 0x04    // address for RAM
#define Reg2_Offset 0x08    // Write enable for RAM
#define Reg3_Offset 0x0C	// data out from RAM

#define WordsPerLine 64 // used by set_pix
#define MaxHor 636
#define MaxVer 477


void initialize_picture(int color);
void set_pix(int x,int y, int c);
void set_npix(int x,int y,int nx, int c);
void set_block(int width, int heigth, int Xpos, int Ypos, int color);
//
//   (Xpos,Ypos)
//   <---------width---------> ^
//   <                       > |
//   <                       > |height
//   <                       > |
//   <-----------------------> v
//


int main (void){

 int Xpos,Ypos,Xpos_next,Ypos_next;
 int width;
 int height;
 char up,up_next;
 char left,left_next;
 char step;
 int color;
 int erase_color;

 Xpos=100;
 Ypos=100;
 step=3;
 width=20;
 height=10;
 up_next=0;
 left_next=0;
 up=0;
 left=0;
 color=1;
 erase_color=0;

 initialize_picture(erase_color);            // black screen

 set_block(MaxHor,1,0,0,4);                // draw border
 set_block(MaxHor,1,0,MaxVer,4);
 set_block(1,MaxVer,0,0,4);
 set_block(1,MaxVer,MaxHor,0,4);

 set_block(width,height, Xpos, Ypos, color); // draw block

 Xpos_next=Xpos+step;
 Ypos_next=Ypos+step;

 while(1){

	 //**start_loop

	     //erase previous block position
	 	//set_block(width,height, Xpos, Ypos, erase_color);

	 	//draw block at next position
		//set_block(width,height, Xpos_next, Ypos_next, color);
	     //erase previous block position
	 	//set_block(width,height, Xpos, Ypos, erase_color);
	 	//erase only parts that really disappear

	 	if ((Xpos_next>=Xpos)&(Ypos_next>=Ypos)) {
	 	  set_block(width,Ypos_next-Ypos, Xpos, Ypos, erase_color);
	       set_block(Xpos_next-Xpos,height-(Ypos_next-Ypos), Xpos, Ypos_next, erase_color);
	     }else if((Xpos_next>=Xpos)&(Ypos_next<Ypos)){
	       set_block(width,Ypos-Ypos_next, Xpos, Ypos_next+height, erase_color);
	       set_block(Xpos_next-Xpos,height-(Ypos-Ypos_next), Xpos, Ypos, erase_color);
	     }else if((Xpos_next<Xpos)&(Ypos_next>=Ypos)){
	       set_block(width,Ypos_next-Ypos, Xpos, Ypos, erase_color);
	       set_block(Xpos-Xpos_next,height-(Ypos_next-Ypos), Xpos_next+width, Ypos_next, erase_color);
	 	}else if((Xpos_next<Xpos)&(Ypos_next<Ypos)){
	 	  set_block(width,Ypos-Ypos_next, Xpos, Ypos_next+height, erase_color);
	       set_block(Xpos-Xpos_next,height-(Ypos-Ypos_next), Xpos_next+width, Ypos, erase_color);
	     }

	 	//draw block at next position
	 	//set_block(width,height, Xpos_next, Ypos_next, color);
	     //draw only new parts
	 	if ((Xpos_next>=Xpos)&(Ypos_next>=Ypos)) {
	 	  set_block(width,Ypos_next-Ypos, Xpos_next, Ypos+height, color);
	       set_block(Xpos_next-Xpos,height-(Ypos_next-Ypos), Xpos+width, Ypos_next, color);
	     }else if((Xpos_next>=Xpos)&(Ypos_next<Ypos)){
	       set_block(width,Ypos-Ypos_next, Xpos_next, Ypos_next, color);
	       set_block(Xpos_next-Xpos,height-(Ypos-Ypos_next), Xpos+width, Ypos, color);
	     }else if((Xpos_next<Xpos)&(Ypos_next>=Ypos)){
	       set_block(width,Ypos_next-Ypos, Xpos_next, Ypos+height, color);
	       set_block(Xpos-Xpos_next,height-(Ypos_next-Ypos), Xpos_next, Ypos_next, color);
	 	}else if((Xpos_next<Xpos)&(Ypos_next<Ypos)){
	 	  set_block(width,Ypos-Ypos_next, Xpos_next, Ypos_next, color);
	       set_block(Xpos-Xpos_next,height-(Ypos-Ypos_next), Xpos_next, Ypos, color);
	     }

	//usleep(200000);
	  usleep(16666-137);

   up=up_next;
	left=left_next;
	Xpos=Xpos_next;
   Ypos=Ypos_next;
	//calculate next position
	if (left==0) {
	  if (Xpos<=(MaxHor-width-step)) {
       Xpos_next=Xpos+step;
       left_next=0;
     }else{
       Xpos_next= MaxHor-width;
       left_next=1;
	  }
   }else {
	  if (Xpos>step) {
       Xpos_next=Xpos-step;
       left_next=1;
     }else{
       Xpos_next=1;
       left_next=0;
	  }
	}
	if (up==0) {
	  if (Ypos<=(MaxVer-height-step)) {
       Ypos_next=Ypos+step;
       up_next=0;
     }else{
       Ypos_next=MaxVer-height;
       up_next=1;
	  }
   }else {
	  if (Ypos>step) {
       Ypos_next=Ypos-step;
       up_next=1;
     }else{
	    Ypos_next=1;
       up_next=0;
	  }
	}
   //**end_loop

 }
 return 0;
}


void set_pix(int x,int y, int c){
    volatile unsigned int ramaddr;
	unsigned int word_number=0,packet_nr=0,ram_value=0,last_bit_pixel=0;
	ramaddr = 0;
	//calculate the number of the word where the pixel is stored on one row
	word_number=x/10; // integer division
	//calculate the address of the word containing pixel
	ramaddr=ramaddr+(word_number+(y*WordsPerLine));
	//assign the value of the sram to a temporary value
	Xil_Out32((BaseAddress + Reg2_Offset), 0x0); //bram_we <=0  because we are reading
	Xil_Out32((BaseAddress + Reg1_Offset), ramaddr); //bram_addr
	Xil_Out32((BaseAddress + Reg2_Offset), 0x0); //bram_we <=0  because we are reading,
	Xil_Out32((BaseAddress + Reg1_Offset), ramaddr); //bram_addr
	ram_value=Xil_In32((BaseAddress + Reg3_Offset)); //bram_dout
	//each word contains 10 pixels
	//calculate which position the pixel has in the word
	packet_nr=x-(word_number*10);
	last_bit_pixel=29-(packet_nr*3);
	// clear the bits that are changing -> "000"
	ram_value &=~(0x7<<last_bit_pixel);
	// set the bits
    ram_value |=(c<<last_bit_pixel);
	//write the new sram value to the sram
	Xil_Out32((BaseAddress + Reg2_Offset), 0x1); //bram_we <=1
	Xil_Out32((BaseAddress + Reg0_Offset), ram_value); //bram_din
}

// STUDENT TO MODIFY THIS ROUTINE:
void set_npix(int x,int y,int nx, int c){
    volatile unsigned int ramaddr;
	unsigned int word_number=0,packet_nr=0,ram_value=0,last_bit_pixel=0;
	int i;
	ramaddr = 0;
	//calculate the number of the word where the pixel is stored on one row
	word_number = x / 10;			// integer division
	//calculate the address of the word containing pixel
	ramaddr = ramaddr + (word_number + (y*WordsPerLine));
	//assign the value of the sram to a temporary value
							 //read the 32-bit data:
	Xil_Out32((BaseAddress + Reg2_Offset), 0x0); //bram_we <=0  because we are reading
	Xil_Out32((BaseAddress + Reg1_Offset), ramaddr); //bram_addr
	Xil_Out32((BaseAddress + Reg2_Offset), 0x0); //bram_we <=0  because we are reading,
	Xil_Out32((BaseAddress + Reg1_Offset), ramaddr); //bram_addr
	ram_value = Xil_In32((BaseAddress + Reg3_Offset)); //bram_dout
	//each word contains 10 pixels
	//calculate which position the pixel has in the word
	packet_nr=x-(word_number*10);
    for(i=0;i<nx;i++){
	  last_bit_pixel=29-(packet_nr*3);
	  // clear the bits that are changing -> "000"
	  ram_value &= ~(0x7 << last_bit_pixel);
	  // set the bits
	  ram_value |= (c << last_bit_pixel);
      if (packet_nr<9) {            //check for the last pixel in the byte, if not last:
        packet_nr++;
	  }else{					//if last pixel, move to next 32-bit word
        packet_nr=0;
   							 //write the modified 32-bit data:
		Xil_Out32((BaseAddress + Reg2_Offset), 0x1);						//bram_we <=1
		Xil_Out32((BaseAddress + Reg1_Offset), ramaddr); //bram_addr
		Xil_Out32((BaseAddress + Reg2_Offset), 0x1);						//bram_we <=1
		Xil_Out32((BaseAddress + Reg1_Offset), ramaddr); //bram_addr
		Xil_Out32((BaseAddress + Reg0_Offset), ram_value);						//bram_din
		ramaddr++;				//move to next address with color in it
							 //read the 32-bit data:
		Xil_Out32((BaseAddress + Reg2_Offset), 0x0);						//bram_we <=0
		Xil_Out32((BaseAddress + Reg1_Offset), ramaddr);				//bram_addr
		Xil_Out32((BaseAddress + Reg2_Offset), 0x0);						//bram_we <=0
		Xil_Out32((BaseAddress + Reg1_Offset), ramaddr);
		ram_value = Xil_In32((BaseAddress + Reg3_Offset));						//bram_dout
	  }
    }
	//write the new ram value to the ram
	Xil_Out32((BaseAddress + Reg2_Offset), 0x1); //bram_we <=1
	Xil_Out32((BaseAddress + Reg0_Offset), ram_value); //bram_din
}



void initialize_picture(int color){
      volatile unsigned int ramaddr;
  	int i=0;
  	unsigned int pix10color=0;  // unsigned because of the >>3
      pix10color = color<<29 ;
  	for (i=1;i<10;i++){
        pix10color = pix10color | (pix10color>>3) ;
  	}
      print("\r\nstart writing to RAM\n\r");
 	  	putnum(pix10color); //function to output the color number as ASCII on terminal/com port
  	Xil_Out32((BaseAddress + Reg2_Offset), 0x1) ;  //bram_we <=1
  	for(ramaddr=0;ramaddr<=30719;ramaddr++){

  		Xil_Out32((BaseAddress + Reg0_Offset), pix10color) ;  //bram_din
  		Xil_Out32((BaseAddress + Reg1_Offset), ramaddr) ;  //bram_addr
   	}
  }

// STUDENT TO MODIFY THIS ROUTINE TO CALL SET_NPIX INSTEAD:
void set_block(int width, int height, int Xpos, int Ypos, int color){
	int i, j;
	for (j = Ypos; j<Ypos + height; j++){
		set_npix(Xpos, j, width, color);
	}
}


