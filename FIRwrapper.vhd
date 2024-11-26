----------------------------------------------------------------------------------
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

entity FIRwrapper is
    Port ( clk : in STD_LOGIC;
           rst_n : in STD_LOGIC;
           en : in STD_LOGIC;
           pi_phase : in STD_LOGIC_VECTOR (15 downto 0);
           win_type : in STD_LOGIC_VECTOR (3 downto 0);
           pace : in STD_LOGIC_VECTOR (7 downto 0);
           n : in STD_LOGIC_VECTOR (15 downto 0);
           lgn : in STD_LOGIC_VECTOR (7 downto 0);
           data_in : in STD_LOGIC_VECTOR (15 downto 0);
           valid : out STD_LOGIC;
           data_out : out STD_LOGIC_VECTOR (15 downto 0)
           );
end FIRwrapper;

architecture Behavioral of FIRwrapper is

component FIR_filter
    Port ( clk : in STD_LOGIC;
           rst_n : in STD_LOGIC;
           en : in STD_LOGIC;
           pi_phase : in STD_LOGIC_VECTOR (15 downto 0);
           win_type : in STD_LOGIC_VECTOR (3 downto 0);
           pace : in STD_LOGIC_VECTOR (7 downto 0);
           n : in STD_LOGIC_VECTOR (15 downto 0);
           lgn : in STD_LOGIC_VECTOR (7 downto 0);
           data_in : in STD_LOGIC_VECTOR (15 downto 0);         
           valid : out STD_LOGIC;
           data_out : out STD_LOGIC_VECTOR (15 downto 0)
           
           );
end component;

begin
   FIR_generator:  FIR_filter
   port map(
           clk => clk, 
           rst_n => rst_n,
           en => en,
           pi_phase => pi_phase,
           win_type => win_type,
           pace => pace,
           n => n,
           lgn => lgn,
           data_in =>data_in,
           valid => valid,
           data_out => data_out   
        );

end Behavioral;
