library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;


entity system3 is
		port (
		   clk_100MHz     : in  STD_LOGIC;
		   hdmi_clkx2_50MHz     : in  STD_LOGIC;
		   hdmi_clk_25MHz     : in  STD_LOGIC;
		   int_reset_n   : in STD_LOGIC;
		   reset       : in  STD_LOGIC;
           hdmi_clk      : out  STD_LOGIC;
           hdmi_hsync    : out  STD_LOGIC;
           hdmi_vsync    : out  STD_LOGIC;
           hdmi_d        : out  STD_LOGIC_VECTOR (15 downto 0);
                   hdmi_de       : out  STD_LOGIC;
                   hdmi_int      : in   STD_LOGIC;
                   hdmi_scl      : out  STD_LOGIC;
                   hdmi_sda      : inout  STD_LOGIC;
        --           hdmi_sda_o      : out  STD_LOGIC;
        --           hdmi_sda_i      : in  STD_LOGIC;
        --           hdmi_sda_t      : out  STD_LOGIC;
           we_Soft       : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
           din_Soft      : in std_logic_vector(31 downto 0);
           dout_Soft     : out std_logic_vector(31 downto 0);
           addr_Soft     : in std_logic_vector(14 downto 0);
           clk_Soft      :  in std_logic );

end system3;

architecture behave of system3 is 

	-- component declaration
	component VideoTimingGen
      GENERIC ( 
      -- resolution   : 640 x 480
    	 H_total      : integer := 800;
        H_active     : integer := 640;
        H_fp         : integer := 16;
        H_sync       : integer := 96;
        H_bp         : integer := 48;
        V_total      : integer := 520;
        V_active     : integer := 480;
        V_fp         : integer := 9;
        V_sync       : integer := 2;
        V_bp         : integer := 29
       );
     PORT(
    	Clock            : in std_logic; 
    	Clk_en         : in std_logic; 
    	Reset_n        : in std_logic; 
    	Hsync          : out std_logic;
    	Vsync          : out std_logic;
    	Hcount         : out std_logic_vector(10 downto 0);
    	Vcount         : out std_logic_vector(10 downto 0);
    	Start_video    : out std_logic;
    	Video_on       : out std_logic
    );
    end component;
    
    
-------------------------- New PLL -----------------------------------------------------
--     component  clk_wiz_0
--     port
--      (-- Clock in ports
--       clk_in1           : in     std_logic;
--       clk_out1          : out    std_logic;
--       clk_out2          : out    std_logic;
--       clk_out3          : out    std_logic;
--       reset             : in     std_logic;
--       locked            : out    std_logic
--      );
--      end component;
--     ------------------------------- New PLL -----------------------------------------------------
    
       COMPONENT iic
       PORT(
          clk    : IN std_logic;
          rst_n : IN std_logic;    
    		wr: IN STD_LOGIC;
    		dev_address: IN STD_LOGIC_VECTOR(6 downto 0);
    		data: IN STD_LOGIC_VECTOR(7 downto 0);
    		address: IN STD_LOGIC_VECTOR(7 downto 0);
    		busy : OUT STD_LOGIC;
    	   ack_error: OUT STD_LOGIC;
          SDA_I : IN std_logic;
    		SDA_O : OUT std_logic;
    		SDA_T : OUT std_logic;     
          SCL   : OUT std_logic
       );
       END COMPONENT;
    
        component RGBGen is
        Port ( Clk : in  STD_LOGIC;
               Reset_n : in  STD_LOGIC;
               Hcount : in std_logic_vector(10 downto 0);
               Vcount : in std_logic_vector(10 downto 0);
               Video_on : in std_logic;
               Start_video : in std_logic;
               VGA_OUT_RED : out  STD_LOGIC_VECTOR (7 downto 0);
               VGA_OUT_GREEN : out  STD_LOGIC_VECTOR (7 downto 0);
               VGA_OUT_BLUE : out  STD_LOGIC_VECTOR (7 downto 0);
               we_Soft      :  in std_logic_vector(0 downto 0);
               din_Soft     : in std_logic_vector(31 downto 0);
               dout_Soft    : out std_logic_vector(31 downto 0);
               addr_Soft    : in std_logic_vector(14 downto 0);
               clk_Soft     :  in std_logic );
        end component;
    
       signal Video_on       : std_logic;
       signal Hsync, Vsync, Start_video, Video_on1	 : std_logic;
       signal Hsync1, Hsync2, Vsync1: std_logic;
       signal Hcount, Vcount: std_logic_vector(10 downto 0);
       signal R,G,B : std_logic_vector(7 downto 0);
       signal colour         : STD_LOGIC_VECTOR (23 downto 0);
       signal Y              : STD_LOGIC_VECTOR (15 downto 0);
       signal Cr             : STD_LOGIC_VECTOR (15 downto 0);
       signal Cb             : STD_LOGIC_VECTOR (15 downto 0);
--       signal hdmi_clkx2_50MHz, hdmi_clk_25MHz  : std_logic;
--       signal clk_100MHz     : std_logic;
       signal register_counter    : std_logic_vector(7 downto 0)  := (others => '0');
    	signal reg_value    : std_logic_vector(15 downto 0)  := (others => '0');
    	signal reg_data:  STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    	signal reg_address:  STD_LOGIC_VECTOR(7 downto 0);
    	signal busy       : std_logic:= '0';
    	signal edge       : std_logic:= '0';
    	signal wr       : std_logic:= '1';
    	signal busy_flag   : std_logic;
    	signal ext_reset_n : std_logic;
--    	signal int_reset_n : std_logic;
    	signal Reset_n : std_logic;
    	signal sda_t, sda_o, sda_i : std_logic;
    
       -- Colours converted using The RGB -> YCbCr  
                                                                            --  Y   Cb  Cr
    constant C_BLACK      : std_logic_vector(23 downto 0) := x"108080";  --  16 128 128
    constant C_RED        : std_logic_vector(23 downto 0) := x"515AF0";  --  81  90 240
    constant C_GREEN      : std_logic_vector(23 downto 0) := x"913622";  -- 145  54  34
    constant C_BLUE       : std_logic_vector(23 downto 0) := x"29F06E";  --  41 240 110
    constant C_WHITE      : std_logic_vector(23 downto 0) := x"EA8080";  -- 234 128 128
    constant C_YELLOW      : std_logic_vector(23 downto 0) := x"D21092";  -- 210 16 146
    constant C_MAGENTA     : std_logic_vector(23 downto 0) := x"6BCADE";  -- 107 202 222
    constant C_CYAN      : std_logic_vector(23 downto 0) := x"AAA610";    -- 170 166 16
    	
    	type reg_value_pair is ARRAY(0 TO 42) OF std_logic_vector(15 DOWNTO 0);    
       
    	-- Registers reference : "ADV7511 Programming Guide"
       signal reg_value_pairs : reg_value_pair := (
                
                x"4110", -- Powerup (Page 15)   
    				
                x"9803", --Fixed registers that must be set  (Page 15) 
    				x"9AE0", --Fixed registers that must be set  (Page 15) 
    				x"9C30", --Fixed registers that must be set	(Page 15)
    				x"9D61", --Fixed registers that must be set	(Page 15)
    				x"A2A4",	--Fixed registers that must be set	(Page 15)
    				x"A3A4", --Fixed registers that must be set	(Page 15)
    				x"E0D0",	--Fixed registers that must be set	(Page 15)		
    				x"5512", --AVI InfoFrame Related Registers   (Page 72)
    				x"F900", --Fixed registers that must be set  (Page 15)
    				
                x"1506", -- YCbCr 422, DDR, External sync
                x"4810", -- Left justified data (D23 downto 8)
                x"1637", -- 8 bit style 2, 1st half on rising edge 
                x"1700", -- output aspect ratio 16:9, external DE 
                x"D03C", -- auto sync data 
                x"AF04", -- DVI mode
                x"4c04", -- Color depth  24 Bits/Pixel (Page 52 )
                x"4000",
    
    				---- HDTV YCbCr (Limited Range) to RGB (Full Range) (Page 62)
                x"18E7", 
    				x"1934",  
    				x"1A04",
    				x"1BAD",  
    				x"1C00", 
    				x"1D00",   
    				x"1E1C",
    				x"1F1B", ----Red
    
                
                x"201D", 
    				x"21DC",  
    				x"2204", 
    				x"23AD",   
    				x"241F", 
    				x"2524",  
    				x"2601", 
    				x"2735", -----Green
                
                
                x"2800", 
    				x"2900",   
    				x"2A04", 
    				x"2BAD",   
    				x"2C08", 
    				x"2D7C",   
    				x"2E1B", 
    				x"2F77", ----Blue
    
    				x"FFFF"
       );

begin

	--------------  Call in components ------------------  
    	U1 : VideoTimingGen 
    	  port map (
    		 Clock          =>  hdmi_clk_25MHz,           
    		 Clk_en         =>  '1',       
    		 Reset_n        =>  Reset_n,        
    		 Hsync          =>  Hsync,
    		 Vsync          =>  Vsync,
    		 Hcount         =>  Hcount,           --hor_count,
    		 Vcount         =>  Vcount,           --ver_count,
    		 Start_video    =>  Start_video,   
    		 Video_on       =>  Video_on
    		);
    
    			
       U2Inst_iic: iic PORT MAP(
          clk => clk_100MHz,
          rst_n => Reset_n,
    		wr => wr,
    		dev_address => "0111001",
    		data => reg_data,
    		address => reg_address,
    		busy => busy,
    	   ack_error => open,
          SCL => hdmi_scl,
          SDA_I => sda_i,
    		SDA_O => sda_o,
    		SDA_T => sda_t
       );
       
    	U3 : RGBGen
    	port map (
    			Clk 			=> hdmi_clk_25MHz,
    			Reset_n			=> Reset_n,
    			Hcount			=> Hcount,
    			Vcount			=> Vcount,
    			Video_on        => Video_on,
    			Start_video     => Start_video,
    			VGA_OUT_RED		=> R,
    			VGA_OUT_GREEN	=> G,
    			VGA_OUT_BLUE	=> B,
    			we_Soft         =>we_Soft,
                din_Soft        =>din_Soft,
                dout_Soft       =>dout_Soft,
                addr_Soft       =>addr_Soft,
                clk_Soft        =>clk_Soft
    			);
    
--     	U4PLL_New :clk_wiz_0
--          port map (
--              -- Clock in ports
--             clk_in1   => clk_100,
--           ---  clkfb_in  => clkfb, 
--             -- Clock out ports
--             clk_out1  => hdmi_clk_25MHz,
--             clk_out2  => hdmi_clkx2_50MHz,
--             clk_out3  => clk_100MHz,
--          --   clkfb_out => clkfb,
--             -- Status and control signals
--             reset       => '0',
--             locked     => int_reset_n
--            );
    
    	IOBUF_inst : IOBUF
    	generic map (
    		DRIVE => 12,
    		IOSTANDARD => "DEFAULT",
    		SLEW => "SLOW")
    	port map (
    		O => sda_i, -- Buffer output
    		IO => hdmi_sda, -- Buffer inout port (connect directly to top-level port)
    		I => sda_o, -- Buffer input
    		T => sda_t -- 3-state enable input, high=input, low=output
      );
    
    ----------------End of components ------------------------------
    
       ext_reset_n <= not(reset);
       Reset_n <= int_reset_n and ext_reset_n;      -- need to make a board reset button, not done yet.
       hdmi_clk <= hdmi_clk_25MHz;
    
     -- breaking the 24 bits colour into separate components Y, Cb, Cr  
          Y   <= colour(23 downto 16) & x"00";
          Cb  <= colour(15 downto  8) & x"00";
          Cr  <= colour( 7 downto  0) & x"00";
       
    registers: process(clk_100MHz, Reset_n)     
           ----- setup 43 registers in ADV chip
    VARIABLE i: INTEGER RANGE 0 to 43;
      begin
       
    	if  (Reset_n = '0') then
    		wr <='1';
    		i:=0;
    	else
    		if rising_edge(clk_100MHz) then
    			
    			if (i<43) then
    				if (busy = '1' and busy_flag ='1' ) then
    					reg_value <= reg_value_pairs(to_integer(unsigned(register_counter)));
    					reg_address <= reg_value(15 downto 8);
    					reg_data <= reg_value(7 downto 0);		   
    					register_counter     <= std_logic_vector(unsigned(register_counter)+1);
    					busy_flag <= '0';
    					i:=i+1;									
    				end if;
    			
    				if busy = '0' then
    					busy_flag <= '1';
    				end if;
    			
    			else 
    				wr<='0';
    			end if;	
    		end if;	
        end if;
       end process;
    
          
    hdmi_clkx2_process: process (hdmi_clkx2_50MHz, Video_on1)
    	------ loading hdmi_d with 3 components --------	
    VARIABLE count: INTEGER RANGE 0 to 3; 
    		
      begin
          if rising_edge(hdmi_clkx2_50MHz) then 
            if Reset_n = '0' then hdmi_d <= (others => '0'); 
    		else if Video_on1 = '0' then 
                count := 0;    
    			hdmi_d <= (others => '0');
              
    		  else
    			if (count=0) then 
    				hdmi_d <= Y;
    			elsif (count=1) then 
    				hdmi_d <= Cb;
    			elsif (count=2) then
    				hdmi_d  <= Y;
    			else
    				hdmi_d <= Cr;
    			end if;
    			
    			if (count < 3) then
                	count:= count + 1;
                	else
                		count := 0;
                end if;		
    		end if;	
    				
    		end if;
    
          end if;
       end process;
    
    
    COLORprocess:  process (R, G, B)
      variable  sel  :  std_logic_vector(23 downto 0);
    begin
      sel := R & G & B;   -- concatenate 3 signals coming from RGBGen  
    
      case sel is
        when  x"000000"  =>  colour <= C_BLACK;
        when  x"FF0000"  =>  colour <= C_RED;
        when  x"00FF00"  =>  colour <= C_GREEN;
        when  x"0000FF"  =>  colour <= C_BLUE;
        when  x"FFFFFF"  =>  colour <= C_WHITE;
        when  x"FFFF00"  =>  colour <= C_YELLOW;
        when  x"FF00FF"  =>  colour <= C_MAGENTA;
        when  x"00FFFF"  =>  colour <= C_CYAN;
        when others =>  colour <= C_RED;                 -- default
      end case;
    
    end process;
    
    --    Delay of 1 clk period for Hsync and Vsync to compensate for the pixel data bus latch
    delay1clock: process(hdmi_clk_25MHz)
      begin
        if rising_edge(hdmi_clk_25MHz) then
          Hsync1 <= Hsync;
          Hsync2 <= Hsync1;
          Vsync1 <= Vsync;
    	  Video_on1 <= Video_on; 
        end if; 
      end process;
      
    hdmi_de <= Video_on1;
    hdmi_hsync <= Hsync2;
    hdmi_vsync <= Vsync1;


end behave;

