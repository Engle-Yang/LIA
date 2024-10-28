----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/15/2024 05:07:47 PM
-- Design Name: 
-- Module Name: multiwrapper - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity multiwrapper is
    Port ( clk: in STD_LOGIC;
           rst_n: in STD_LOGIC;
           cEn: in STD_LOGIC;
           sig_i_1 : in STD_LOGIC_VECTOR (15 downto 0);
           sig_i_2 : in STD_LOGIC_VECTOR (15 downto 0);
           sig_o : out STD_LOGIC_VECTOR (31 downto 0)
           );
end multiwrapper;

architecture Behavioral of multiwrapper is

component multi
    Port ( clk: in STD_LOGIC;
           rst_n: in STD_LOGIC;
           cEn: in STD_LOGIC;
           sig_i_1 : in STD_LOGIC_VECTOR (15 downto 0);
           sig_i_2 : in STD_LOGIC_VECTOR (15 downto 0);
           sig_o : out STD_LOGIC_VECTOR (31 downto 0)
           );
end component;

begin
   multi_x :  multi
   port map(
     clk => clk,
     rst_n => rst_n,
     cEn => cEn,
     sig_i_1 => sig_i_1,
     sig_i_2 => sig_i_2,
     sig_o => sig_o       
        );


end Behavioral;
