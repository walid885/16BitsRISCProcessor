
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_textio.all;
use STD.textio.all;

-- For VHDL-2002, if to_hstring is not available, add this function:
package hex_pkg is
    function to_hstring (value : std_logic_vector) return string;
end package;

package body hex_pkg is
    function to_hstring (value : std_logic_vector) return string is
        constant hex_table : string(1 to 16) := "0123456789ABCDEF";
        variable result : string(1 to (value'length+3)/4);
        variable quad : std_logic_vector(3 downto 0);
        variable index : integer;
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
            result(i) := hex_table(to_integer(unsigned(quad))+1);
        end loop;
        return result;
    end function;
end package body;

use work.hex_pkg.all;


entity ProcessorTB is
end ProcessorTB;

architecture Behavioral of ProcessorTB is
    -- Component declaration
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
    
    -- Clock period definition
    constant clk_period : time := 10 ns;
    
    -- Helper function to display instruction details
    function decode_instruction(instr: STD_LOGIC_VECTOR(15 downto 0)) return string is
        variable opcode_val : integer;
        variable cond_val   : integer;
        variable opcode_str : string(1 to 5);
        variable cond_str   : string(1 to 5);
        variable updt_str   : string(1 to 1);
        variable imm_str    : string(1 to 5);
        variable val_str    : string(1 to 10);
    begin
        opcode_val := to_integer(unsigned(instr(11 downto 8)));
        cond_val := to_integer(unsigned(instr(15 downto 12)));
        
        -- Determine opcode
        case opcode_val is
            when 0 => opcode_str := "ADD  ";
            when 1 => opcode_str := "SUB  ";
            when 2 => opcode_str := "AND  ";
            when 3 => opcode_str := "OR   ";
            when 4 => opcode_str := "XOR  ";
            when 5 => opcode_str := "NOT  ";
            when 6 => opcode_str := "LSL  ";
            when 7 => opcode_str := "LSR  ";
            when 8 => opcode_str := "MTA  ";
            when 9 => opcode_str := "MTR  ";
            when 10 => opcode_str := "LDA  ";
            when 11 => opcode_str := "STA  ";
            when 12 => opcode_str := "JMP  ";
            when 13 => opcode_str := "BRA  ";
            when 14 => opcode_str := "CAL  ";
            when 15 => opcode_str := "RET  ";
            when others => opcode_str := "????";
        end case;
        
        -- Determine condition
        case cond_val is
            when 0 => cond_str := "T    ";
            when 1 => cond_str := "Z    ";
            when 2 => cond_str := "NZ   ";
            when 3 => cond_str := "C    ";
            when 4 => cond_str := "P    ";
            when 5 => cond_str := "N    ";
            when 6 => cond_str := "LE   ";
            when 7 => cond_str := "GT   ";
            when 8 => cond_str := "V    ";
            when 9 => cond_str := "NC   ";
            when 10 => cond_str := "LE   ";
            when 11 => cond_str := "GT   ";
            when 12 => cond_str := "V    ";
            when 13 => cond_str := "NV   ";
            when 14 => cond_str := "T    ";
            when 15 => cond_str := "F    ";
            when others => cond_str := "????";
        end case;
        
        -- Update flag
        if instr(7) = '1' then
            updt_str := "S";
        else
            updt_str := " ";
        end if;
        
        -- Immediate or register
        if instr(6) = '1' then
            imm_str := "IMM: ";
            val_str := "0x" & to_hstring(unsigned(instr(5 downto 0))) & "    ";
        else
            imm_str := "REG: ";
            val_str := "R" & integer'image(to_integer(unsigned(instr(5 downto 0)))) & "     ";
        end if;
        
        return opcode_str & cond_str & updt_str & " " & imm_str & val_str;
    end function;
    
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: Processor
        port map (
            clk         => clk,
            rst         => rst,
            debug_pc    => debug_pc,
            debug_acc   => debug_acc,
            debug_instr => debug_instr,
            debug_state => debug_state
        );
        
    -- Clock process
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
    
    -- Monitor process to display processor state
    monitor_proc: process
    begin
        wait for clk_period;
        
        -- Display processor state every clock cycle
        report "Time: " & time'image(now) & 
               " PC: 0x" & to_hstring(unsigned(debug_pc)) & 
               " ACC: 0x" & to_hstring(unsigned(debug_acc)) & 
               " INSTR: 0x" & to_hstring(unsigned(debug_instr));
               
        -- Display decoded instruction when available
        if to_integer(unsigned(debug_instr)) /= 0 then
            report "Decoding: " & decode_instruction(debug_instr);
        end if;
        
        wait for clk_period - 1 ns;  -- Wait for almost a full clock cycle
    end process;
    
    -- Stimulus process
    stim_proc: process
    begin
        -- Hold reset state for a few cycles
        rst <= '1';
        wait for clk_period*3;
        rst <= '0';
        
        -- Let the processor run through its program
        -- Run for 100 instruction cycles (500 clock cycles since each instruction takes 5 cycles)
        wait for clk_period*500;
        
        -- End simulation
        report "Simulation finished" severity NOTE;
        wait;
    end process;

end Behavioral;