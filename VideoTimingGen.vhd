 -----------------------------------------------------------------------------
 -- Copyright (C) 2005 IMEC                                                  -
 --                                                                          -
 -- Redistribution and use in source and binary forms, with or without       -
 -- modification, are permitted provided that the following conditions       -
 -- are met:                                                                 -
 --                                                                          -
 -- 1. Redistributions of source code must retain the above copyright        -
 --    notice, this list of conditions and the following disclaimer.         -
 --                                                                          -
 -- 2. Redistributions in binary form must reproduce the above               -
 --    copyright notice, this list of conditions and the following           -
 --    disclaimer in the documentation and/or other materials provided       -
 --    with the distribution.                                                -
 --                                                                          -
 -- 3. Neither the name of the author nor the names of contributors          -
 --    may be used to endorse or promote products derived from this          -
 --    software without specific prior written permission.                   -
 --                                                                          -
 -- THIS CODE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''           -
 -- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED        -
 -- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A          -
 -- PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR       -
 -- CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,             -
 -- SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT         -
 -- LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF         -
 -- USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND      -
 -- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,       -
 -- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT       -
 -- OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF       -
 -- SUCH DAMAGE.                                                             -
 --                                                                          -
 -----------------------------------------------------------------------------
 -----------------------------------------------------------------------------
 -- File           : VideoTimingGen.vhd
 -----------------------------------------------------------------------------
 -- Description    : VHDL entity and architecture for VideotimingGen
 -- --------------------------------------------------------------------------
 -- Author         : Geert Vanwijnsberghe
 -- Date           : 10/2/06
 -- Version        : 1.0
 -- Change history : 
 -----------------------------------------------------------------------------
   
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

-- VGA Video Sync generation

ENTITY VideoTimingGen IS
-- GENERIC ( 
--  -- resolution   : 1280 x 720
--	 H_total      : integer := 1648;
--    H_active     : integer := 1280;
--    H_fp         : integer := 72;
--    H_sync       : integer := 80;
--    H_bp         : integer := 216;
--    V_total      : integer := 750;
--    V_active     : integer := 720;
--    V_fp         : integer := 3;
--    V_sync       : integer := 5;
--    V_bp         : integer := 22
--   ); 
   GENERIC ( 	 
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
    Clock         : in std_logic;  
    Clk_en        : in std_logic; 
    Reset_n       : in std_logic; -- synchronous active low
    Hsync         : out std_logic;
    Vsync         : out std_logic;
    Hcount        :	out std_logic_vector(10 downto 0);   
	 Hcount_even   :  out std_logic;
    Vcount        : out std_logic_vector(10 downto 0);
    Start_video   : out std_logic;
    Video_on      : out std_logic
  );
end VideoTimingGen;

architecture behav of VideoTimingGen is
  signal video_on_h, video_on_v: std_logic;
  signal hcount_sig, vcount_sig      : unsigned(10 downto 0);  
begin

  --Generate Horizontal and Vertical counters
  --Sequential process
  process(Clock)
  begin
  if rising_edge(Clock) then
    if Reset_n = '0' then
      hcount_sig        <= (others => '0');
      vcount_sig        <= (others => '0');     
    elsif clk_en = '1' then 
      -- calculation of hcount_sig    
      if (hcount_sig >= H_total-1) then  
	    hcount_sig <= (others => '0');
      else
	    hcount_sig <= hcount_sig + 1;
      end if;
      -- calculation of vcount_sig
      if (hcount_sig = H_total-1) then         
        if (vcount_sig >= V_total-1) then         
          vcount_sig <= (others => '0');
        else 
          vcount_sig <= vcount_sig + 1;
        end if;
      end if;
    end if;
  end if;
  end process;
   
  --Generate Horizontal Sync Signal using hcount_sig
  --Combinatorial process
  --not spike free!
  process(hcount_sig)
  begin      
    if  (hcount_sig < H_sync)  then
      Hsync <= '0';
    else
	  Hsync <= '1';
    end if;
  end process;
  
  --Generate Vertical Sync Signal using vcount_sig
  --Combinatorial process
  --not spike free!
  process(vcount_sig)
  begin 	  
    if  (vcount_sig < V_sync )  then                                              
      Vsync <= '0';
    else
      Vsync <= '1';
    end if;
  end process;
  
  --Generate Video_on Screen Signals for Pixel Data
  --Combinatorial process
  --not spike free!
  process(hcount_sig,vcount_sig)
  begin
      --video_on_h
      if (hcount_sig >= H_sync + H_bp ) and (hcount_sig < H_sync + H_bp + H_active) then
        video_on_h <= '1';
      else
        video_on_h <= '0';
      end if;
      --video_on_v
      if (vcount_sig >= V_sync + V_bp)  and (vcount_sig < V_sync + V_bp + V_active) then
        video_on_v <= '1'; 
      else
        video_on_v <= '0';
      end if;
   end process;
  
  --Generate Start_video puls
  --not spike free!
  --Combinatorial process
  process(hcount_sig,vcount_sig)
  begin  
      if (hcount_sig = H_sync + H_bp) and (vcount_sig = V_sync + V_bp) then
        Start_video <= '1';
      else
        Start_video <= '0';
      end if;
  end process;
    
  --Concurrent assignment
  Video_on     <= video_on_H AND video_on_V;

  --Cast of unsigned to std_logic_vector
  Hcount        <= std_logic_vector(hcount_sig);
  Vcount        <= std_logic_vector(vcount_sig);
  Hcount_even   <= hcount_sig (0);
  
  end behav;
