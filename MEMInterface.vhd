
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM is
    Port ( 
        clk      : in  STD_LOGIC;
        rst      : in  STD_LOGIC;
        addr     : in  STD_LOGIC_VECTOR(15 downto 0);  -- Memory address
        din      : in  STD_LOGIC_VECTOR(15 downto 0);  -- Data input
        we       : in  STD_LOGIC;                      -- Write enable
        dout     : out STD_LOGIC_VECTOR(15 downto 0)   -- Data output
    );
end RAM;

architecture Behavioral of RAM is
    -- Define RAM type (2^10 = 1024 words of 16 bits)
    type ram_type is array (0 to 1023) of STD_LOGIC_VECTOR(15 downto 0);
    
    -- Initialize RAM with a simple program (example)
    signal memory : ram_type := (
        -- Simple program that adds value in R1 to accumulator
        0 => "0000000010000001",  -- ADD R1 (opcode=0000, cond=0000, updt=0, imm=0, val=000001)
        1 => "0000000110000010",  -- LSL R2 (opcode=0110, cond=0000, updt=0, imm=0, val=000010)
        2 => "0000001010000000",  -- LDA (opcode=1010, cond=0000, updt=0, imm=0, val=000000)
        3 => "0000100000000000",  -- MTA R0 (opcode=1000, cond=0000, updt=0, imm=0, val=000000)
        -- Rest initialized to 0
        others => (others => '0')
    );
    
    -- 10 bits from address will be used (addressing 1K words)
    signal addr_internal : integer range 0 to 1023;
    
begin
    -- Convert address to integer for memory indexing
    addr_internal <= to_integer(unsigned(addr(9 downto 0)));
    
    -- Memory read/write process
    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset output
            dout <= (others => '0');
        elsif rising_edge(clk) then
            if we = '1' then
                -- Write operation
                memory(addr_internal) <= din;
            end if;
            -- Read operation (always active)
            dout <= memory(addr_internal);
        end if;
    end process;

end Behavioral;