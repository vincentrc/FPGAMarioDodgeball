----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Lauren Chrisotpher
-- 
-- Create Date:    10/30/2014 
-- Design Name: 
-- Module Name:    RGBGen - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 1.0  Modified for Vivado 2014
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RGBGen is
    Port ( Clk : in  STD_LOGIC;
           Reset_n : in  STD_LOGIC;
           Hcount : in std_logic_vector(10 downto 0);
           Vcount : in std_logic_vector(10 downto 0);
           Video_on : in std_logic;
           Start_video : in std_logic;
           VGA_OUT_RED : out  STD_LOGIC_VECTOR (7 downto 0);
           VGA_OUT_GREEN : out  STD_LOGIC_VECTOR (7 downto 0);
           VGA_OUT_BLUE : out  STD_LOGIC_VECTOR (7 downto 0);
           we_Soft : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
           din_Soft : in std_logic_vector(31 downto 0);
           dout_Soft : out std_logic_vector(31 downto 0);
           addr_Soft : in std_logic_vector(14 downto 0);
           clk_Soft :  in std_logic );
end RGBGen;

architecture Behavioral of RGBGen is

-------------------  adding block memory component---------
COMPONENT blk_mem_gen_0
  PORT (
  clka : IN STD_LOGIC;
  wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
  addra : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
  dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
  douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
  clkb : IN STD_LOGIC;
  web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
  addrb : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
  dinb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
  doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;
-------------------  end block memory component---------


  signal hor_count        : std_logic_vector(10 downto 0);
  signal ver_count        : std_logic_vector(10 downto 0);
  signal Refresh          : std_logic;
  signal XposBlock        : unsigned(10 downto 0);
  signal YposBlock        : unsigned(10 downto 0);
  signal Up_down          : std_logic;  -- 1 = up
  signal Left_right       : std_logic;  -- 1 = left
  signal Draw_block       : std_logic;
  signal Draw_border      : std_logic;
  
  constant H_total      : integer := 800;
  constant H_active     : integer := 640;
  constant H_fp         : integer := 16;
  constant H_sync       : integer := 96;
  constant H_bp         : integer := 48;
  
  constant V_total      : integer := 520;
  constant V_active     : integer := 480;
  constant V_fp         : integer := 9;
  constant V_sync       : integer := 2;
  constant V_bp         : integer := 29;
  
  constant Line0_ver_count: integer := V_sync+V_bp;
  constant Col0_hor_count : integer := H_sync+H_bp; 
  constant BlockHalfHeight: integer := 5;
  constant BlockHalfWidth : integer := 10; 
  constant zero           : std_logic := '0';
  constant one            : std_logic := '1';
  
  --**** New Signals for Dual Port RAM Lab ****
  signal addr_Hard    : unsigned(14 downto 0);
  signal addr_reg     : unsigned(14 downto 0);
--  signal addr_Soft    : std_logic_vector(14 downto 0);
--  signal din_Soft     : std_logic_vector(31 downto 0);
  signal dout_Hard    : std_logic_vector(31 downto 0);
--  signal dout_Soft    : std_logic_vector(31 downto 0);
--  signal we_Soft      : std_logic_vector(0 downto 0);
  signal PixCntr      : integer range 0 to 9;
  signal R, G, B      : std_logic_vector(7 downto 0);
-----------------------------------------------
 
begin

U1RGBBlockDualPortMemory : blk_mem_gen_0
  PORT MAP (
    clka => clk,
    wea => (others => '0'),
    addra => std_logic_vector(addr_Hard),
    dina => (others => '0'),
    douta => dout_Hard,
    clkb => clk_Soft,
    web => we_Soft,
    addrb => addr_Soft,
    dinb => din_Soft,
    doutb => dout_Soft
  );
 
  hor_count <= Hcount;
  ver_count <= Vcount;
  
------------------NOW using the RAM to get R, G, B ------------  
   --Software side now will be connected
--we_Soft   <=(others => '0');
--din_Soft  <=(others => '0');
--addr_Soft <=(others => '0');

-- GenPixCntr: process
-- add your code here 
-- clk process that counts clocks repeating 0-9 while Video_on='1', resets to zero when start_video = '1'
GenPixCntr: process(clk)
begin
  if rising_edge(clk) then
    if Reset_n ='0' then
      PixCntr <=0;
    else
      if Start_video = '1' then
        PixCntr <= 0;
      elsif Video_on='1' then
        if PixCntr < 9 then
          PixCntr <= PixCntr+1;
        elsif PixCntr = 9 then
          PixCntr  <= 0;
        end if;
      end if;
    end if;
  end if; 
end process GenPixCntr;


-- Genaddr_reg: process
-- add your code here 
-- clk process that counts between 0 and < 30719 for RAM addressing every 8th PixCntr  
Genaddr_reg: process(clk)
begin
  if rising_edge(clk) then
    if Reset_n ='0' then
      addr_reg <= (others => '0');
    else
      if Start_video = '1' then
        addr_reg <= (others => '0');
      elsif Video_on='1' and PixCntr = 8 and addr_reg < 30719 then
        addr_reg <= addr_reg +1;
      end if;
    end if;
  end if; 
end process Genaddr_reg;  

-- Genaddr_Hard: process
-- add your code here 
-- combinatorial process to map addr_reg to addr_Hard
Genaddr_Hard: process(addr_reg,Start_video)
begin
  if Start_video = '1' then 
     addr_Hard <= (others => '0');
  else
     addr_Hard <= addr_reg;
  end if;
end process Genaddr_Hard;    

-- Connect Red, Green and Blue  with the correct bits of dout_Hard 
-- add your code here  
-- you will have structure like:  Green <= (others => dout_Hard(31 - PixCntr * 3 - 1))
R   <= (others => dout_Hard(31 - PixCntr * 3));
G 	<= (others => dout_Hard(31 - PixCntr * 3 - 1));
B  	<= (others => dout_Hard(31 - PixCntr * 3 - 2));
----------------RAM Drives output ---------- 

-- Retiming 
  
  Proc5View_all: process(Clk)
  begin
    if rising_edge(Clk) then                       
        VGA_OUT_RED         <= R;  
        VGA_OUT_GREEN       <= G;  
        VGA_OUT_BLUE        <= B;     
     end if;                                
  end process Proc5View_all;

end Behavioral;

