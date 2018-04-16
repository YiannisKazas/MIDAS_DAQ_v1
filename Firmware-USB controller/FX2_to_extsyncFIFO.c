#pragma NOIV               // Do not generate interrupt vectors
//-----------------------------------------------------------------------------
//   File:       FX2_to_extsyncFIFO.c
//   Contents:   Hooks required to implement FX2 GPIF to external sync. FIFO
//               interface using CY4265-15AC
//
//   Copyright (c) 2003 Cypress Semiconductor, Inc. All rights reserved
//-----------------------------------------------------------------------------
#include "fx2.h"
#include "fx2regs.h"
#include "fx2sdly.h"            // SYNCDELAY macro, see Section 15.14 of FX2 Tech.
                                // Ref. Manual for usage details.

#define EXTFIFONOTFULL  GPIFREADYSTAT & bmBIT1
#define EXTFIFONOTEMPTY GPIFREADYSTAT & bmBIT0
#define bmEP0BSY 0x01
#define LED_ALL         (bmBIT0 | bmBIT1 | bmBIT2 | bmBIT3)
#define BIT0   0x01	 
#define BIT1   0x02
#define BIT2   0x04
#define BIT3   0x08
#define BIT4   0x10
#define BIT5   0x20
#define BIT6   0x40
#define BIT7   0x80


extern BOOL GotSUD;             // Received setup data flag
extern BOOL Sleep;
extern BOOL Rwuen;
extern BOOL Selfpwr;

BYTE Configuration;             // Current configuration
BYTE AlternateSetting;          // Alternate settings
BYTE j,k,n;
BYTE BITMASK[8] = {BIT0,BIT1,BIT2,BIT3,BIT4,BIT5,BIT6,BIT7};
static WORD xdata LED_Count = 0;
static BYTE xdata LED_Status = 0;
BOOL energry_transfer_complete=FALSE;
//-----------------------------------------------------------------------------
// Task Dispatcher hooks
// The following hooks are called by the task dispatcher.
//-----------------------------------------------------------------------------
void LED_Off (BYTE LED_Mask);
void LED_On (BYTE LED_Mask);
//void GpifInit ();

void TD_Init( void )
{ // Called once at startup

  CPUCS = ((CPUCS & ~bmCLKSPD) | bmCLKSPD1);
  SYNCDELAY;
//  FIFOPINPOLAR = 0x3F;	// ACTIVE HIGH

  PINFLAGSAB = 0x8E;			// FLAGA= EP6FF, FLAGB= EP2EF
  SYNCDELAY;
  IFCONFIG = 0xE3; // 

  // IFCLKSRC=1   , FIFOs executes on internal clk source 
  // xMHz=1       , 48MHz operation
  // IFCLKOE=1    , Drive IFCLK pin signal at 48MHz
  // IFCLKPOL=1   , Invert IFCLK pin signal from internal clk
  // ASYNC=0      , Master samples synchronous
  // GSTATE=0     , Don't drive GPIF states out on PORTE[2:0], debug WF
  // IFCFG[1:0]=11, FX2 in slave FIFO mode


  // Registers which require a synchronization delay, see section 15.14
  // FIFORESET        FIFOPINPOLAR
  // INPKTEND         OUTPKTEND
  // EPxBCH:L         REVCTL
  // GPIFTCB3         GPIFTCB2
  // GPIFTCB1         GPIFTCB0
  // EPxFIFOPFH:L     EPxAUTOINLENH:L
  // EPxFIFOCFG       EPxGPIFFLGSEL
  // PINFLAGSxx       EPxFIFOIRQ
  // EPxFIFOIE        GPIFIRQ
  // GPIFIE           GPIFADRH:L
  // UDMACRCH:L       EPxGPIFTRIG
  // GPIFTRIG
  
  // Note: The pre-REVE EPxGPIFTCH/L register are affected, as well...
  //      ...these have been replaced by GPIFTC[B3:B0] registers



  EP2CFG = 0xA0;                //out 512 bytes, 4x, bulk
  SYNCDELAY;                    
  EP6CFG = 0xE0;                // in 512 bytes, 4x, bulk
  SYNCDELAY;              
  EP4CFG = 0x02;                //clear valid bit
  SYNCDELAY;                     
  EP8CFG = 0x02;                //clear valid bit
  SYNCDELAY;   

  SYNCDELAY;
  FIFORESET = 0x80;             // activate NAK-ALL to avoid race conditions
  SYNCDELAY;                    // see TRM section 15.14
  FIFORESET = 0x02;             // reset, FIFO 2
  SYNCDELAY;                    // 
  FIFORESET = 0x04;             // reset, FIFO 4
  SYNCDELAY;                    // 
  FIFORESET = 0x06;             // reset, FIFO 6
  SYNCDELAY;                    // 
  FIFORESET = 0x08;             // reset, FIFO 8
  SYNCDELAY;                    // 
  FIFORESET = 0x00;             // deactivate NAK-ALL


  // handle the case where we were already in AUTO mode...
  // ...for example: back to back firmware downloads...
  SYNCDELAY;                    // 
  EP2FIFOCFG = 0x00;            // AUTOOUT=0, WORDWIDE=1
  
  // core needs to see AUTOOUT=0 to AUTOOUT=1 switch to arm endp's
  
  SYNCDELAY;                    // 
  EP2FIFOCFG = 0x3C;            // AUTOOUT=1, WORDWIDE=0	
  
  SYNCDELAY;                    // 
  EP6FIFOCFG = 0x5C;            // AUTOIN=1, ZEROLENIN=1, WORDWIDE=0, INFM1=1	

  SYNCDELAY;                    // 
  EP4FIFOCFG = 0x00;            //  WORDWIDE=0

  SYNCDELAY;                    // 
  EP8FIFOCFG = 0x00;            //  WORDWIDE=0


  SYNCDELAY;
  EP6AUTOINLENH = 0x01;		   //0x01
  SYNCDELAY;  
  EP6AUTOINLENL = 0x2C;		// 	0x2C  Auto-in length = 300 Bytes (100 frames * 3 bytes each)
  SYNCDELAY;						

//  EP2AUTOOUTLENH = 0x00;
//  SYNCDELAY;  
//  EP2AUTOOUTLENL = 0x01;
//  SYNCDELAY;

}

void TD_Poll( void )
{ // Called repeatedly while the device is idle

  // ...nothing to do... slave fifo's are in AUTO mode...
  
  
}
 
  

BOOL TD_Suspend(void)          // Called before the device goes into suspend mode
{
   return(TRUE);
}

BOOL TD_Resume(void)          // Called after the device resumes
{
   return(TRUE);
}

//-----------------------------------------------------------------------------
// Device Request hooks
//   The following hooks are called by the end point 0 device request parser.
//-----------------------------------------------------------------------------

BOOL DR_GetDescriptor(void)
{
   return(TRUE);
}

BOOL DR_SetConfiguration(void)   // Called when a Set Configuration command is received
{
   Configuration = SETUPDAT[2];
   return(TRUE);            // Handled by user code
}

BOOL DR_GetConfiguration(void)   // Called when a Get Configuration command is received
{
   EP0BUF[0] = Configuration;
   EP0BCH = 0;
   EP0BCL = 1;
   return(TRUE);            // Handled by user code
}

BOOL DR_SetInterface(void)       // Called when a Set Interface command is received
{
   AlternateSetting = SETUPDAT[2];
   return(TRUE);            // Handled by user code
}

BOOL DR_GetInterface(void)       // Called when a Set Interface command is received
{
   EP0BUF[0] = AlternateSetting;
   EP0BCH = 0;
   EP0BCL = 1;
   return(TRUE);            // Handled by user code
}

BOOL DR_GetStatus(void)
{
   return(TRUE);
}

BOOL DR_ClearFeature(void)
{
   return(TRUE);
}

BOOL DR_SetFeature(void)
{
   return(TRUE);
}

#define VX_B0 0xB0 // Return to Idle State
#define VX_B1 0xB1 // Download Configuration
#define VX_B2 0xB2 // Set DAC
#define VX_B3 0xB3 // Start Recording
#define VX_B4 0xB4 // Global Reset
#define VX_B5 0xB5 // Read Current Consumption

BOOL DR_VendorCmnd(void)
{
  
  switch (SETUPDAT[1])
  {

	case VX_B0: // Idle state
	{	  	
		    OEC=0xFF; //Set Port_C as output
			OED=0xFF; //Set Port_D as output
			OEE=0x03; //Set pin #0,#1 of Port_E as outputs
			IOC=0x00; //Port_C = "00000000" 
			IOD=0x00; //Port_D = "00000000"
			IOE=0x00; //Port_E = "xxxxxx00"
			EP0BCL = 0;		 //EP0BUF LSB BYTE COUNT 
			SYNCDELAY;	   	  		  
			EP0BCH = 0;
			EP0BCL = 4;                   // Arm endpoint with 64# unsigned chars to transfer
			EP0CS |= bmHSNAK;              // Acknowledge handshake phase of device request 
	  break;
			}


	case VX_B1: // Download Configuration   
	{	  	
		    OED=0xFF;	//Define all pins of port_D as outputs 
			IOD=0x00;	//Port_D = "00000000" ---> CS = '0' (SPI_data line contains configuration data)
			EP0BCL = 0;		 //EP0BUF LSB BYTE COUNT 
			while(EP01STAT & bmEP0BSY);     // wait until EP0 is available to be accessed by CPU
		    n=0;
			for (n=0;n<4;n=n+1)	   //sends 4 bytes          
			{	
				for(k=0;k<8;k++) //SENDS ONE BYTE SERIALLY 
		  		{
					if(EP0BUF[n] & BITMASK[7-k])		
		  			{
						IOD = IOD | (0x02);	  //SDIHI
						IOD = IOD | (0x01);	  //SCKHI
						IOD = IOD &~ (0x01);  //SCKLOW
					}
		  			else
					{
						IOD = IOD &~ (0x02);  //SDILOW
						IOD = IOD |  (0x01);  //SCKHI
						IOD = IOD & ~ (0x01); //SCKLOW
					}
		  		}
			}
			IOD=0x00;// Port_D = "00000000" (Return to Idle)
			SYNCDELAY;	   	  		  
			EP0BCH = 0;
			EP0BCL = 4;                   // Arm endpoint with 64# unsigned chars to transfer
			EP0CS |= bmHSNAK;              // Acknowledge handshake phase of device request 
	  break;
			}

	case VX_B2: // Set DAC   
	{	  	
		    OED=0xFF; //Define all pins of port_D as outputs
			IOD=0x04; //Port_D = "00000000" ---> CS = '1' (SPI_data line contains DAC data)
			EP0BCL = 0;		 //EP0BUF LSB BYTE COUNT 
			while(EP01STAT & bmEP0BSY);     // wait until EP0 is available to be accessed by CPU
		    n=0;
			for (n=0;n<2;n=n+1)	   //sends 2 bytes          
			{	
				for(k=0;k<8;k++) //SENDS ONE BYTE SERIALY 
		  		{
					if(EP0BUF[n] & BITMASK[7-k])		
		  			{
						IOD = IOD | (0x02);   //SDIHI
						IOD = IOD | (0x01);	  //SCKHI
						IOD = IOD &~ (0x01);  //SCKLOW
					}
		  			else
					{
						IOD = IOD &~ (0x02);  //SDILOW
						IOD = IOD  | (0x01);  //SCKHI
						IOD = IOD & ~ (0x01); //SCKLOW
					}
		  		}
			}
			IOD=0x00; //Port_D = "00000000" (Return to Idle)
			SYNCDELAY;	   	  		  
			EP0BCH = 0;
			EP0BCL = 4;                   // Arm endpoint with 64# unsigned chars to transfer
			EP0CS |= bmHSNAK;              // Acknowledge handshake phase of device request 
	  break;
			}


	case VX_B3: // Start Recording
	{	  	
		    OEC=0xFF;
			IOC=0x01;   //Port_C = "00000001" (Start_Rec bit = '1')
			EP0BCL = 0;	//EP0BUF LSB BYTE COUNT 
			SYNCDELAY;	   	  		  
			EP0BCH = 0;
			EP0BCL = 4;                   // Arm endpoint with 64# unsigned chars to transfer
			EP0CS |= bmHSNAK;              // Acknowledge handshake phase of device request 

	  break;
			}

	case VX_B4: // Reset 
	{	  	
		    OED=0xFF;
			IOD=0x60;//01100000 --------> SEL="110" 
//			n = 0;
//			for (n=0;n<500;n=n+1)
//			{
//			}
//			IOD=0x00;
			EP0BCL = 0;		 //EP0BUF LSB BYTE COUNT 
			SYNCDELAY;	   	  		  
			EP0BCH = 0;
			EP0BCL = 4;                   // Arm endpoint with 64# unsigned chars to transfer
			EP0CS |= bmHSNAK;              // Acknowledge handshake phase of device request 

	  break;
			}

    case VX_B5: // Read Current Consumption
    { 
	 	OEE=0x03; //Set pins #0,#1 of Port_E as outputs and the rest as inputs 
		IOE=0x00; 
		SYNCDELAY;	   	  		  
		EP0BCH = 0;
	 	EP0BCL = 2;                   // Arm endpoint with 64# unsigned chars to transfer
	 	EP0CS |= bmHSNAK;              // Acknowledge handshake phase of device request 
      break;
	  }


    default:
        return(TRUE);
  }

  return(FALSE);
  }
 //{

//-----------------------------------------------------------------------------
// USB Interrupt Handlers
//   The following functions are called by the USB interrupt jump table.
//-----------------------------------------------------------------------------

// Setup Data Available Interrupt Handler
void ISR_Sudav(void) interrupt 0
{
   GotSUD = TRUE;            // Set flag
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmSUDAV;         // Clear SUDAV IRQ
}

// Setup Token Interrupt Handler
void ISR_Sutok(void) interrupt 0
{
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmSUTOK;         // Clear SUTOK IRQ
}

void ISR_Sof(void) interrupt 0
{
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmSOF;            // Clear SOF IRQ
}

void ISR_Ures(void) interrupt 0
{
   // whenever we get a USB reset, we should revert to full speed mode
   pConfigDscr = pFullSpeedConfigDscr;
   ((CONFIGDSCR xdata *) pConfigDscr)->type = CONFIG_DSCR;
   pOtherConfigDscr = pHighSpeedConfigDscr;
   ((CONFIGDSCR xdata *) pOtherConfigDscr)->type = OTHERSPEED_DSCR;

   EZUSB_IRQ_CLEAR();
   USBIRQ = bmURES;         // Clear URES IRQ
}

void ISR_Susp(void) interrupt 0
{
   Sleep = TRUE;
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmSUSP;
}

void ISR_Highspeed(void) interrupt 0
{
   if (EZUSB_HIGHSPEED())
   {
      pConfigDscr = pHighSpeedConfigDscr;
      ((CONFIGDSCR xdata *) pConfigDscr)->type = CONFIG_DSCR;
      pOtherConfigDscr = pFullSpeedConfigDscr;
      ((CONFIGDSCR xdata *) pOtherConfigDscr)->type = OTHERSPEED_DSCR;
   }

   EZUSB_IRQ_CLEAR();
   USBIRQ = bmHSGRANT;
}
void ISR_Ep0ack(void) interrupt 0
{
}
void ISR_Stub(void) interrupt 0
{
}
void ISR_Ep0in(void) interrupt 0
{
}
void ISR_Ep0out(void) interrupt 0
{
}
void ISR_Ep1in(void) interrupt 0
{
}
void ISR_Ep1out(void) interrupt 0
{
}
void ISR_Ep2inout(void) interrupt 0
{
}
void ISR_Ep4inout(void) interrupt 0
{
}
void ISR_Ep6inout(void) interrupt 0
{
}
void ISR_Ep8inout(void) interrupt 0
{
}
void ISR_Ibn(void) interrupt 0
{
}
void ISR_Ep0pingnak(void) interrupt 0
{
}
void ISR_Ep1pingnak(void) interrupt 0
{
}
void ISR_Ep2pingnak(void) interrupt 0
{
}
void ISR_Ep4pingnak(void) interrupt 0
{
}
void ISR_Ep6pingnak(void) interrupt 0
{
}
void ISR_Ep8pingnak(void) interrupt 0
{
}
void ISR_Errorlimit(void) interrupt 0
{
}
void ISR_Ep2piderror(void) interrupt 0
{
}
void ISR_Ep4piderror(void) interrupt 0
{
}
void ISR_Ep6piderror(void) interrupt 0
{
}
void ISR_Ep8piderror(void) interrupt 0
{
}
void ISR_Ep2pflag(void) interrupt 0
{
}
void ISR_Ep4pflag(void) interrupt 0
{
}
void ISR_Ep6pflag(void) interrupt 0
{
}
void ISR_Ep8pflag(void) interrupt 0
{
}
void ISR_Ep2eflag(void) interrupt 0
{
}
void ISR_Ep4eflag(void) interrupt 0
{
}
void ISR_Ep6eflag(void) interrupt 0
{
}
void ISR_Ep8eflag(void) interrupt 0
{
}
void ISR_Ep2fflag(void) interrupt 0
{
}
void ISR_Ep4fflag(void) interrupt 0
{
}
void ISR_Ep6fflag(void) interrupt 0
{
}
void ISR_Ep8fflag(void) interrupt 0
{
}
void ISR_GpifComplete(void) interrupt 0
{
}
void ISR_GpifWaveform(void) interrupt 0
{
}

// ...debug LEDs: accessed via movx reads only ( through CPLD )
// it may be worth noting here that the default monitor loads at 0xC000
xdata volatile const BYTE LED0_ON  _at_ 0x8000;
xdata volatile const BYTE LED0_OFF _at_ 0x8100;
xdata volatile const BYTE LED1_ON  _at_ 0x9000;
xdata volatile const BYTE LED1_OFF _at_ 0x9100;
xdata volatile const BYTE LED2_ON  _at_ 0xA000;
xdata volatile const BYTE LED2_OFF _at_ 0xA100;
xdata volatile const BYTE LED3_ON  _at_ 0xB000;
xdata volatile const BYTE LED3_OFF _at_ 0xB100;
// use this global variable when (de)asserting debug LEDs...
BYTE xdata ledX_rdvar = 0x00;
BYTE xdata LED_State = 0;
void LED_Off (BYTE LED_Mask)
{
	if (LED_Mask & bmBIT0)
	{
		ledX_rdvar = LED0_OFF;
		LED_State &= ~bmBIT0;
	}
	if (LED_Mask & bmBIT1)
	{
		ledX_rdvar = LED1_OFF;
		LED_State &= ~bmBIT1;
	}
	if (LED_Mask & bmBIT2)
	{
		ledX_rdvar = LED2_OFF;
		LED_State &= ~bmBIT2;
	}
	if (LED_Mask & bmBIT3)
	{
		ledX_rdvar = LED3_OFF;
		LED_State &= ~bmBIT3;
	}
}

void LED_On (BYTE LED_Mask)
{
	if (LED_Mask & bmBIT0)
	{
		ledX_rdvar = LED0_ON;
		LED_State |= bmBIT0;
	}
	if (LED_Mask & bmBIT1)
	{
		ledX_rdvar = LED1_ON;
		LED_State |= bmBIT1;
	}
	if (LED_Mask & bmBIT2)
	{
		ledX_rdvar = LED2_ON;
		LED_State |= bmBIT2;
	}
	if (LED_Mask & bmBIT3)
	{
		ledX_rdvar = LED3_ON;
		LED_State |= bmBIT3;
	}
}

