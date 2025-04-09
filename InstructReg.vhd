
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity instruction_register is
    Port (
        clk     : in  STD_LOGIC;                      -- Clock signal
        rst     : in  STD_LOGIC;                      -- Reset signal
        ce      : in  STD_LOGIC;                      -- Clock enable
        i       : in  STD_LOGIC_VECTOR(15 downto 0);  -- Input instruction
        o       : out STD_LOGIC_VECTOR(15 downto 0);  -- Output instruction
        
        -- Decoded instruction fields
        cond    : out STD_LOGIC_VECTOR(3 downto 0);   -- Condition code (bits 15-12)
        op      : out STD_LOGIC_VECTOR(3 downto 0);   -- Operation code (bits 11-8)
        updt    : out STD_LOGIC;                      -- Update flag (bit 7)
        imm     : out STD_LOGIC;                      -- Immediate flag (bit 6)
        val     : out STD_LOGIC_VECTOR(5 downto 0)    -- Value/Register number (bits 5-0)
    );
end instruction_register;

architecture Behavioral of instruction_register is
    signal instr : STD_LOGIC_VECTOR(15 downto 0);
begin
    -- Register process
    process(clk, rst)
    begin
        if rst = '1' then
            instr <= (others => '0');
        elsif rising_edge(clk) then
            if ce = '1' then
                instr <= i;
            end if;
        end if;
    end process;
    
    -- Output assignments
    o <= instr;
    
    -- Decode the instruction fields
    cond <= instr(15 downto 12);  -- Condition field
    op   <= instr(11 downto 8);   -- Operation code
    updt <= instr(7);             -- Update flag
    imm  <= instr(6);             -- Immediate flag
    val  <= instr(5 downto 0);    -- Value/Register number
end Behavioral;