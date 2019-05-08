----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:26:48 05/17/2012 
-- Design Name: 
-- Module Name:    i2c - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
--use IEEE.STD_LOGIC_ARITH.all;
--use work.my_functions.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
---------------------------------------------------------------------------------------
ENTITY iic IS
	GENERIC (
	fclk: POSITIVE := 100_000;   --Freq of sys clock (in kHz)
	data_rate: POSITIVE := 100 --desired I2C bus speed (in kbps)
	); 
	PORT (
	  --system signals:
	  clk, 
	  rst_n: IN STD_LOGIC;
	  wr: IN STD_LOGIC;
	  dev_address: IN STD_LOGIC_VECTOR(6 downto 0);
	  data: IN STD_LOGIC_VECTOR(7 downto 0);
	  address: IN STD_LOGIC_VECTOR(7 downto 0);
	  busy : OUT STD_LOGIC;
	  --ssd: OUT STD_LOGIC_VECTOR(6 downto 0);
	  ack_error: OUT STD_LOGIC;
	  -- i2c signals:
	  SCL: OUT STD_LOGIC;
	  SDA_I : IN std_logic;
	  SDA_O : OUT std_logic;
	  SDA_T : OUT std_logic
	  );
END iic;
----------------------------------------------------------------------------------------------
architecture fsm of iic is
--General constants and signals:
   CONSTANT divider: 				INTEGER 								:= (fclk/4)/data_rate; --- 
	CONSTANT delay:					INTEGER 								:= (5*data_rate); --sets maximum delay to 5 bits

	CONSTANT w: std_logic := '0';
	CONSTANT r: std_logic := '1';
	
	SIGNAL	aux_clk_en:				STD_LOGIC := '0';
	SIGNAL 	bus_clk:					STD_LOGIC := '0';
	SIGNAL 	data_clk:				STD_LOGIC := '0';
	SIGNAL 	data_clk_en1:			STD_LOGIC := '0';
	SIGNAL 	data_clk_en2:			STD_LOGIC := '0';
	SIGNAL   data_out:				STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL 	wr_flag:					STD_LOGIC;
	SIGNAL	mem_addr:				STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL   ack:						STD_LOGIC_VECTOR(2 downto 0);
	SIGNAL   timer:					NATURAL range 0 to delay;
	
	SHARED VARIABLE i:				NATURAL range 0 to delay;
--STATE MACHINE singals
   TYPE state is (idle, start_wr, dev_addr_wr, wr_addr, wr_data, stop, ack1, ack2, ack3);
	SIGNAL pr_state, nx_state: state;
	SIGNAL dev_addr_read, dev_addr_write : std_logic_vector (7 downto 0);
	--signal SDA_O, SDA_I, SDA_T: std_logic;
BEGIN
   --------- General Signals  -------------------
	dev_addr_read <= dev_address & '1';
	dev_addr_write <= dev_address & '0';
	ack_error <= (ack(0) OR ack(1) OR ack(2));

	--------- Auxililary Clock -------------------
	--freq=4*data_rate=400 kHz for given parameters
	PROCESS (clk)
	    VARIABLE count: INTEGER RANGE 0 to divider;
   BEGIN
	    if rising_edge(Clk) then
		    count:= count+1;
			 aux_clk_en <= '0';
			 if (count=divider) then 
			    aux_clk_en <= '1';
				 count := 0;
			 end if;
		 end if;
    END PROCESS; 
	  
	 ------- Bus and data Reference clocks -------
	 --freq = data_rate = 100kHz for given parameters
	 PROCESS (clk)
	      VARIABLE count: INTEGER RANGE 0 to 3;
	 BEGIN
	      if rising_edge(clk) then
	           data_clk_en1 <= '0';
	           data_clk_en2 <= '0';
				if aux_clk_en = '1' then
					
					if (count < 3) then
						count:= count + 1;
					else
						count := 0;
					end if;
					
					if (count=0) then
						bus_clk <= '0';
					elsif (count=1) then 
						data_clk <= '1';
						data_clk_en1 <= '1';
					elsif (count=2) then 
						bus_clk <= '1';
					else
						data_clk <= '0';
						data_clk_en2 <= '1';
					end if;
					
				end if;						-- End if aux_clk_en
			end if;							-- End if Clk
	 END PROCESS;
	
	 
-- Finite State Machine:	 
-------- Lower section of FSM -------------------------
	PROCESS (clk, rst_n)
	BEGIN
		if (rst_n='0') then
			pr_state <= idle;
			i:= 0;
		elsif rising_edge(clk) then
			if data_clk_en1 = '1' then
				if (i=timer-1) then 
					pr_state <= nx_state;
					i := 0;
				else
					i := i + 1;
				end if;
		   end if;	
		end if;	
	end process;
	
	PROCESS(clk,rst_n)
	BEGIN
		if (rst_n ='0') then
			wr_flag <= '0';
			ack <= "000";
		elsif rising_edge(clk) then
			if data_clk_en2 = '1' then
				--store write flag:
				if (pr_state=idle) then
					wr_flag <= wr;
					data_out <= data;
					mem_addr <= address;
				end if;
				--store  ack signals during writing:
				IF (pr_state=ack1) then
					ack(0) <= SDA_I;
				elsif (pr_state=ack2) then
					ack(1) <= SDA_I;
				elsif (pr_state=ack3) then
					ack(2) <= SDA_I;
				end if;
				
				-- genrate busy signal
				if (pr_state=idle) then
					busy <= '0';
				else
					busy <= '1';
				end if;
			end if;		
		end if;
	end process;
--------- upper section of FSM --------------
	PROCESS (pr_state, bus_clk, data_clk, wr_flag, data_out, mem_addr, dev_addr_write)
	BEGIN
		CASE pr_state IS
			WHEN idle =>
				SDA_T <=r;
				SCL <= '1';
				SDA_O <= '1';
				timer <= 1; --delay;--max write time 5ms
				if (wr_flag='1') then
					nx_state <= start_wr;
				else
					nx_state <= idle;
				end if;
			WHEN start_wr =>
				SDA_T <=w;
				SCL <= '1';
				SDA_O <= data_clk;
				timer <= 1;
				nx_state <= dev_addr_wr;
			WHEN dev_addr_wr =>
			   SDA_T <=w;
				SCL <= bus_clk;
				SDA_O <= dev_addr_write(7-i);  -- MSB first
				timer <= 8;
				nx_state <= ack1;
			WHEN ack1 =>
				SDA_T <=r;
				SCL <= bus_clk;
				SDA_O <= '1';---
				timer <= 1;
				nx_state <= wr_addr;
			WHEN wr_addr =>
				SDA_T <=w;
				SCL <= bus_clk;
				SDA_O <= mem_addr(7-i);  -- MSB first
				timer <= 8;
				nx_state <= ack2;
			WHEN ack2 =>
				SDA_T <=r;
				SCL <= bus_clk;
			   SDA_O <= '1';--
				timer <= 1;
				nx_state <= wr_data;
			WHEN wr_data =>
				SDA_T <=w;
				SCL <= bus_clk;
				SDA_O <= data_out(7-i);
				timer <= 8;
				nx_state <= ack3;
			WHEN ack3 =>
				SDA_T <=r;
				SCL <= bus_clk;
				SDA_O <= '1';---
				timer <= 1;
				nx_state <= stop;
			WHEN stop =>
				SDA_T <=w;
				SCL <= '1';
				SDA_O <= NOT (Data_clk); -- 
				timer <= 1;
				nx_state <= idle;
		END CASE;
	END PROCESS;
end fsm;