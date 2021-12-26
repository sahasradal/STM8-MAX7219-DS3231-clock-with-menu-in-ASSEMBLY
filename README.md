# STM8-MAX7219-DS3231-clock-with-menu-in-ASSEMBLY
This code is in ST assembler to be used on STM8S103F3.
The files can be put into the source folder of STVD IDE and build
then burn it into the chip with STVP
Te LED matrix is from ali express 2 peices of "MAX7219 Lattice modules 4 in one display Digital tube display module Single chip module 8x8 common cathode"
soldered together total 8 blocks communicating via SPI
clock module is DS3231 via I2C connected to pins PB4(SCL) PB5(SDA)
MAX7219 LED matrix connected to DIN - PC6(MOSI),SCK - PC5(SCL) , CS - PA3(NSS)
PD2,PD3,PD4 are used as MENU,NEXT,SAVE buttons and are active when connected to ground , at idle these switches are open
press MENU (PD2 to ground) to enter time/date adjust mode (time , date and week are adjusted in one go)
press NEXT button(PD3) to change the value of hour , minute , date , month , year, week . Only increment option is available
Press SAVE button (PD4) to save the selected value. Once value saved the next parameter will be selected. If hour saved the process will jump to minute selection then date...
"MAX7219 Lattice modules 4 in one display Digital tube display module Single chip module 8x8 common cathode" from aliexprees has modules aligned in such a way that 
the addresses of each LED matrix has its 1st address on top and the last address at the bottom that means it is row aligned

---------- 01       ------------01     
---------- 02       ------------02
---------- 07       ------------07
---------- 08       ------------08
![image](https://user-images.githubusercontent.com/36818909/147404957-2415f125-a90b-41cb-9795-442d8c84125d.png)

