library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;  -- Fixed typo in package name
use STD.TEXTIO.ALL;

-- Custom hex conversion package
package hex_pkg is
    function to_hstring(value : std_logic_vector) return string;
end package;

package body hex_pkg is
    function to_hstring(value : std_logic_vector) return string is
        constant hex_table : string(1 to 16) := "0123456789ABCDEF";
        variable result    : string(1 to (value'length+3)/4);
        variable quad      : std_logic_vector(3 downto 0);
        variable index     : integer;
    begin
        for i in result'range loop
            index := (i-1)*4;
            if index+3 > value'high then
                quad := (others => '0');
                for j in 0 to value'high-index loop
                    quad(j) := value(index+j);
                end loop;
            else
                quad := value(index+3 downto index);
            end if;
            result(i) := hex_table(to_integer(unsigned(quad)) + 1);
        end loop;
        return result;
    end function;
end package body;

--------------------------------------------------
-- Testbench Entity with Proper Context Clauses --
--------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.hex_pkg.all;

entity ProcessorTB is
end ProcessorTB;

architecture Behavioral of ProcessorTB is
    component Processor
        Port (
            clk         : in  STD_LOGIC;
            rst         : in  STD_LOGIC;
            debug_pc    : out STD_LOGIC_VECTOR(15 downto 0);
            debug_acc   : out STD_LOGIC_VECTOR(15 downto 0);
            debug_instr : out STD_LOGIC_VECTOR(15 downto 0);
            debug_state : out STD_LOGIC_VECTOR(2 downto 0)
        );
    end component;

    -- Test signals
    signal clk         : STD_LOGIC := '0';
    signal rst         : STD_LOGIC := '1';
    signal debug_pc    : STD_LOGIC_VECTOR(15 downto 0);
    signal debug_acc   : STD_LOGIC_VECTOR(15 downto 0);
    signal debug_instr : STD_LOGIC_VECTOR(15 downto 0);
    signal debug_state : STD_LOGIC_VECTOR(2 downto 0);

    constant clk_period : time := 10 ns;

    -- Fixed string lengths to match declarations
    function decode_instruction(instr: STD_LOGIC_VECTOR(15 downto 0)) return string is
        variable opcode_val : integer;
        variable cond_val   : integer;
        variable opcode_str : string(1 to 5) := "     ";
        variable cond_str   : string(1 to 5) := "     ";
        variable updt_str   : string(1 to 1) := " ";
        variable imm_str    : string(1 to 5) := "     ";
        variable val_str    : string(1 to 10) := "          ";
    begin
        opcode_val := to_integer(unsigned(instr(11 downto 8)));
        cond_val := to_integer(unsigned(instr(15 downto 12)));

        -- Opcode decoding
        case opcode_val is
            when 0  => opcode_str := "ADD  ";
            -- Add other cases here...
            when others => opcode_str := "???? ";
        end case;

        -- Condition decoding
        case cond_val is
            when 0  => cond_str := "T    ";
            -- Add other cases here...
            when others => cond_str := "???? ";
        end case;

        -- Immediate/register handling
        if instr(6) = '1' then
            imm_str := "IMM: ";
            val_str := "0x" & to_hstring(instr(5 downto 0)) & "  ";
        else
            imm_str := "REG: ";
            val_str := "R" & integer'image(to_integer(unsigned(instr(5 downto 0)))) & "   ";
        end if;

        return opcode_str & cond_str & updt_str & " " & imm_str & val_str;
    end function;

begin
    uut: Processor
        port map (
            clk         => clk,
            rst         => rst,
            debug_pc    => debug_pc,
            debug_acc   => debug_acc,
            debug_instr => debug_instr,
            debug_state => debug_state
        );

    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    stim_proc: process
    begin
        wait for clk_period*3;
        rst <= '0';
        wait for clk_period*500;
        report "Simulation finished" severity NOTE;
        wait;
    end process;

    monitor_proc: process
    begin
        wait for clk_period;
        report "Time: " & time'image(now) & 
               " PC: 0x" & to_hstring(debug_pc) & 
               " ACC: 0x" & to_hstring(debug_acc) & 
               " INSTR: 0x" & to_hstring(debug_instr);
        wait for clk_period - 1 ns;
    end process;

end Behavioral;
