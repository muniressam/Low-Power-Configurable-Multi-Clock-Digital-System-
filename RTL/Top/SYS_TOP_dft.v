
module SYS_TOP # ( parameter DATA_WIDTH = 8 ,  RF_ADDR = 4 , NUM_OF_CHAINS = 4)


(
 input   wire                          scan_clk ,
 input   wire                          scan_rst ,
 input   wire                          test_mode ,
 input   wire                          SE ,
 input   wire   [NUM_OF_CHAINS-1:0]    SI ,
 output  wire   [NUM_OF_CHAINS-1:0]    SO ,
 input   wire                          RST_N,
 input   wire                          UART_CLK,
 input   wire                          REF_CLK,
 input   wire                          UART_RX_IN,
 output  wire                          UART_TX_O,
 output  wire                          parity_error,
 output  wire                          framing_error
);


wire                                   SYNC_UART_RST,
                                       SYNC_REF_RST;
									   
wire				       UART_TX_CLK;
wire				       UART_RX_CLK;

wire                 		       REF_SCAN_CLK;
wire                                   UART_SCAN_CLK;
wire                                   UART_RX_SCAN_CLK;
wire                                   UART_TX_SCAN_CLK;

wire             		       RSTN_SCAN_RST;
wire              		       SYNC_REF_SCAN_RST;
wire              		       SYNC_UART_SCAN_RST;


wire      [DATA_WIDTH-1:0]             Operand_A,
                                       Operand_B,
									   UART_Config,
									   DIV_RATIO;
									   
wire      [DATA_WIDTH-1:0]             DIV_RATIO_RX;
									   
wire      [DATA_WIDTH-1:0]             UART_RX_OUT;
wire         						   UART_RX_V_OUT;
wire      [DATA_WIDTH-1:0]			   UART_RX_SYNC;
wire                                   UART_RX_V_SYNC;

wire      [DATA_WIDTH-1:0]             UART_TX_IN;
wire        						   UART_TX_VLD;
wire      [DATA_WIDTH-1:0]             UART_TX_SYNC;
wire        						   UART_TX_V_SYNC;

wire                                   UART_TX_Busy;	
wire                                   UART_TX_Busy_PULSE;	
									   
wire                                   RF_WrEn;
wire                                   RF_RdEn;
wire      [RF_ADDR-1:0]                RF_Address;
wire      [DATA_WIDTH-1:0]             RF_WrData;
wire      [DATA_WIDTH-1:0]             RF_RdData;
wire                                   RF_RdData_VLD;									   

wire                                   CLKG_EN;
wire                                   ALU_EN;
wire      [3:0]                        ALU_FUN; 
wire      [DATA_WIDTH*2-1:0]           ALU_OUT;
wire                                   ALU_OUT_VLD; 
									   
wire                                   ALU_CLK ;								   

wire                                   FIFO_FULL ;
	
wire                                   CLKDIV_EN ;

///********************************************************///
//////////////////// Muxes Clocks & Resets////////////////////
///********************************************************///

//////////////////////// Clocks /////////////////////////////

// Mux primary REF_CLK & SCAN_CLK
mux2X1 U0_mux2X1 (
.IN_0(REF_CLK),
.IN_1(scan_clk),
.SEL(test_mode),
.OUT(REF_SCAN_CLK)
); 

// Mux primary UART_CLK & SCAN_CLK
mux2X1 U1_mux2X1 (
.IN_0(UART_CLK),
.IN_1(scan_clk),
.SEL(test_mode),
.OUT(UART_SCAN_CLK)
); 

// Mux generated UART_RX_CLK & SCAN_CLK
mux2X1 U2_mux2X1 (
.IN_0(UART_RX_CLK),
.IN_1(scan_clk),
.SEL(test_mode),
.OUT(UART_RX_SCAN_CLK)
); 

// Mux generated UART_TX_CLK & SCAN_CLK
mux2X1 U3_mux2X1 (
.IN_0(UART_TX_CLK),
.IN_1(scan_clk),
.SEL(test_mode),
.OUT(UART_TX_SCAN_CLK)
); 

//////////////////////// Resets /////////////////////////////

// Mux primary RST_N & scan_rst
mux2X1 U4_mux2X1 (
.IN_0(RST_N),
.IN_1(scan_rst),
.SEL(test_mode),
.OUT(RSTN_SCAN_RST)
); 

// Mux generated SYNC_REF_RST & scan_rst
mux2X1 U5_mux2X1 (
.IN_0(SYNC_REF_RST),
.IN_1(scan_rst),
.SEL(test_mode),
.OUT(SYNC_REF_SCAN_RST)
); 

// Mux generated SYNC_UART_RST & scan_rst
mux2X1 U6_mux2X1 (
.IN_0(SYNC_UART_RST),
.IN_1(scan_rst),
.SEL(test_mode),
.OUT(SYNC_UART_SCAN_RST)
); 
								   
///********************************************************///
//////////////////// Reset synchronizers /////////////////////
///********************************************************///

RST_SYNC # (.NUM_STAGES(2)) U0_RST_SYNC (
.RST(RSTN_SCAN_RST),
.CLK(UART_SCAN_CLK),
.SYNC_RST(SYNC_UART_RST)
);

RST_SYNC # (.NUM_STAGES(2)) U1_RST_SYNC (
.RST(RSTN_SCAN_RST),
.CLK(REF_SCAN_CLK),
.SYNC_RST(SYNC_REF_RST)
);

///********************************************************///
////////////////////// Data Synchronizer /////////////////////
///********************************************************///

DATA_SYNC # (.NUM_STAGES(2) , .BUS_WIDTH(8)) U0_ref_sync (
.CLK(REF_SCAN_CLK),
.RST(SYNC_REF_SCAN_RST),
.unsync_bus(UART_RX_OUT),
.bus_enable(UART_RX_V_OUT),
.sync_bus(UART_RX_SYNC),
.enable_pulse_d(UART_RX_V_SYNC)
);

///********************************************************///
///////////////////////// Async FIFO /////////////////////////
///********************************************************///

Async_fifo #(.D_SIZE(DATA_WIDTH) , .P_SIZE(4)  , .F_DEPTH(8)) U0_UART_FIFO (
.i_w_clk(REF_SCAN_CLK),
.i_w_rstn(SYNC_REF_SCAN_RST),  
.i_w_inc(UART_TX_VLD),
.i_w_data(UART_TX_IN),             
.i_r_clk(UART_TX_SCAN_CLK),              
.i_r_rstn(SYNC_UART_SCAN_RST),              
.i_r_inc(UART_TX_Busy_PULSE),              
.o_r_data(UART_TX_SYNC),             
.o_full(FIFO_FULL),               
.o_empty(UART_TX_V_SYNC)               
);

///********************************************************///
//////////////////////// Pulse Generator /////////////////////
///********************************************************///

PULSE_GEN U0_PULSE_GEN (
.clk(UART_TX_SCAN_CLK),
.rst(SYNC_UART_SCAN_RST),
.lvl_sig(UART_TX_Busy),
.pulse_sig(UART_TX_Busy_PULSE)
);

///********************************************************///
//////////// Clock Divider for UART_TX Clock /////////////////
///********************************************************///

ClkDiv U0_ClkDiv (
.i_ref_clk(UART_SCAN_CLK),             
.i_rst(SYNC_UART_SCAN_RST),                 
.i_clk_en(CLKDIV_EN),               
.i_div_ratio(DIV_RATIO),           
.o_div_clk(UART_TX_CLK)             
);

///********************************************************///
/////////////////////// Custom Mux Clock /////////////////////
///********************************************************///

CLKDIV_MUX U0_CLKDIV_MUX (
.IN(UART_Config[7:2]),
.OUT(DIV_RATIO_RX)
);

///********************************************************///
//////////// Clock Divider for UART_RX Clock /////////////////
///********************************************************///

ClkDiv U1_ClkDiv (
.i_ref_clk(UART_SCAN_CLK),             
.i_rst(SYNC_UART_SCAN_RST),                 
.i_clk_en(CLKDIV_EN),               
.i_div_ratio(DIV_RATIO_RX),           
.o_div_clk(UART_RX_CLK)             
);

///********************************************************///
/////////////////////////// UART /////////////////////////////
///********************************************************///

UART  U0_UART (
.RST(SYNC_UART_SCAN_RST),
.TX_CLK(UART_TX_SCAN_CLK),
.RX_CLK(UART_RX_SCAN_CLK),
.parity_enable(UART_Config[0]),
.parity_type(UART_Config[1]),
.Prescale(UART_Config[7:2]),
.RX_IN_S(UART_RX_IN),
.RX_OUT_P(UART_RX_OUT),                      
.RX_OUT_V(UART_RX_V_OUT),                      
.TX_IN_P(UART_TX_SYNC), 
.TX_IN_V(!UART_TX_V_SYNC), 
.TX_OUT_S(UART_TX_O),
.TX_OUT_V(UART_TX_Busy),
.parity_error(parity_error),
.framing_error(framing_error)                  
);

///********************************************************///
//////////////////// System Controller ///////////////////////
///********************************************************///

SYS_CTRL U0_SYS_CTRL (
.CLK(REF_SCAN_CLK),
.RST(SYNC_REF_SCAN_RST),
.RF_RdData(RF_RdData),
.RF_RdData_VLD(RF_RdData_VLD),
.RF_WrEn(RF_WrEn),
.RF_RdEn(RF_RdEn),
.RF_Address(RF_Address),
.RF_WrData(RF_WrData),
.ALU_EN(ALU_EN),
.ALU_FUN(ALU_FUN), 
.ALU_OUT(ALU_OUT),
.ALU_OUT_VLD(ALU_OUT_VLD),  
.CLKG_EN(CLKG_EN), 
.CLKDIV_EN(CLKDIV_EN),   
.FIFO_FULL(FIFO_FULL),
.UART_RX_DATA(UART_RX_SYNC), 
.UART_RX_VLD(UART_RX_V_SYNC),
.UART_TX_DATA(UART_TX_IN), 
.UART_TX_VLD(UART_TX_VLD)
);

///********************************************************///
/////////////////////// Register File ////////////////////////
///********************************************************///

RegFile U0_RegFile (
.CLK(REF_SCAN_CLK),
.RST(SYNC_REF_SCAN_RST),
.WrEn(RF_WrEn),
.RdEn(RF_RdEn),
.Address(RF_Address),
.WrData(RF_WrData),
.RdData(RF_RdData),
.RdData_VLD(RF_RdData_VLD),
.REG0(Operand_A),
.REG1(Operand_B),
.REG2(UART_Config),
.REG3(DIV_RATIO)
);

///********************************************************///
//////////////////////////// ALU /////////////////////////////
///********************************************************///
 
ALU U0_ALU (
.CLK(ALU_CLK),
.RST(SYNC_REF_SCAN_RST),  
.A(Operand_A), 
.B(Operand_B),
.EN(ALU_EN),
.ALU_FUN(ALU_FUN),
.ALU_OUT(ALU_OUT),
.OUT_VALID(ALU_OUT_VLD)
);

///********************************************************///
///////////////////////// Clock Gating ///////////////////////
///********************************************************///

CLK_GATE U0_CLK_GATE (
.CLK_EN(CLKG_EN||test_mode),
.CLK(REF_SCAN_CLK),
.GATED_CLK(ALU_CLK)
);


endmodule
 

