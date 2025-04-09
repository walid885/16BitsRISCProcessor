
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity status_register is
    Port ( 
        clk     : in  STD_LOGIC;                     -- Clock signal
        rst     : in  STD_LOGIC;                     -- Reset signal
        ce      : in  STD_LOGIC;                     -- Clock enable
        input       : in  STD_LOGIC_VECTOR(3 downto 0);  -- Input status bits (Z,N,C,V)
        output       : out STD_LOGIC_VECTOR(3 downto 0)   -- Output status bits
    );
end status_register;

architecture Behavioral of status_register is
    signal status : STD_LOGIC_VECTOR(3 downto 0);
begin
    -- Register process
    process(clk, rst)
    begin
        if rst = '1' then
            status <= (others => '0');
        elsif rising_edge(clk) then
            if ce = '1' then
                status <= input;
            end if;
        end if;
    end process;
    
    -- Output assignment
    output <= status;
end Behavioral;