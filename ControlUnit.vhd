
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ControlUnit is
    Port ( 
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        -- Instruction fields
        opcode      : in  STD_LOGIC_VECTOR(3 downto 0);
        cond        : in  STD_LOGIC_VECTOR(3 downto 0);
        updt        : in  STD_LOGIC;
        imm         : in  STD_LOGIC;
        val         : in  STD_LOGIC_VECTOR(5 downto 0);
        -- Status flags
        status      : in  STD_LOGIC_VECTOR(3 downto 0); -- Z, N, C, V
        -- Control signals
        instr_ce    : out STD_LOGIC;
        status_ce   : out STD_LOGIC;
        acc_ce      : out STD_LOGIC;
        pc_ce       : out STD_LOGIC;
        rpc_ce      : out STD_LOGIC;
        rx_ce       : out STD_LOGIC;
        ram_we      : out STD_LOGIC;
        sel_ram_addr: out STD_LOGIC;  -- 0: PC, 1: ACC
        sel_op1     : out STD_LOGIC;  -- 0: ACC, 1: PC
        sel_rf_din  : out STD_LOGIC;  -- 0: ALU, 1: RAM
        alu_op      : out STD_LOGIC_VECTOR(3 downto 0)
    );
end ControlUnit;

architecture Behavioral of ControlUnit is
    -- Define FSM states
    type state_type is (FETCH1, FETCH2, DECODE, EXEC, STORE);
    signal state_r, next_state : state_type;
    
    -- Condition evaluation signals
    signal cond_met : STD_LOGIC;
    
    -- Helpers
    signal z, n, c, v : STD_LOGIC;
    
begin
    -- Extract status flags
    z <= status(3);  -- Zero
    n <= status(2);  -- Negative
    c <= status(1);  -- Carry
    v <= status(0);  -- Overflow
    
    -- Condition evaluation logic
    process(cond, z, n, c, v)
    begin
        case cond is
            when "0000" => cond_met <= '1';                      -- Always (T)
            when "0001" => cond_met <= z;                        -- Equal/Zero (Z)
            when "0010" => cond_met <= not z;                    -- Not Equal (NZ)
            when "0011" => cond_met <= c;                        -- Carry Set (C)
            when "0100" => cond_met <= not z and not n;          -- Greater Than/Positive (P)
            when "0101" => cond_met <= n;                        -- Less Than/Negative (N)
            when "0110" => cond_met <= z or n;                   -- Less Than or Equal (LE)
            when "0111" => cond_met <= not z and not n;          -- Greater Than (GT)
            when "1000" => cond_met <= v;                        -- Overflow (V)
            when "1001" => cond_met <= not c;                    -- No Carry (NC)
            when "1010" => cond_met <= z or (not z and n);       -- Less Than or Equal (LE)
            when "1011" => cond_met <= not z and not n;          -- Greater Than (GT)
            when "1100" => cond_met <= v;                        -- Overflow (V)
            when "1101" => cond_met <= not v;                    -- No Overflow (NV)
            when "1110" => cond_met <= '1';                      -- Always (T) - redundant
            when "1111" => cond_met <= '0';                      -- Never (F)
            when others => cond_met <= '0';
        end case;
    end process;

    -- State register
    process(clk, rst)
    begin
        if rst = '1' then
            state_r <= FETCH1;
        elsif rising_edge(clk) then
            state_r <= next_state;
        end if;
    end process;
    
    -- Next state logic
    process(state_r)
    begin
        case state_r is
            when FETCH1 =>
                next_state <= FETCH2;
            when FETCH2 =>
                next_state <= DECODE;
            when DECODE =>
                next_state <= EXEC;
            when EXEC =>
                next_state <= STORE;
            when STORE =>
                next_state <= FETCH1;
            when others =>
                next_state <= FETCH1;
        end case;
    end process;
    
    -- Output logic
    process(state_r, opcode, cond_met, updt, imm)
    begin
        -- Default values
        instr_ce    <= '0';
        status_ce   <= '0';
        acc_ce      <= '0';
        pc_ce       <= '0';
        rpc_ce      <= '0';
        rx_ce       <= '0';
        ram_we      <= '0';
        sel_ram_addr<= '0';  -- 0: PC, 1: ACC
        sel_op1     <= '0';  -- 0: ACC, 1: PC
        sel_rf_din  <= '0';  -- 0: ALU, 1: RAM
        alu_op      <= "0000"; -- Default ADD
        
        case state_r is
            when FETCH1 =>
                -- Put PC on address bus to memory
                sel_ram_addr <= '0';  -- Select PC for memory address
                
            when FETCH2 =>
                -- Load instruction register
                instr_ce <= '1';
                
            when DECODE =>
                -- Nothing specific happens here in terms of control signals
                -- This is where operands are loaded into ALU input registers
                
            when EXEC =>
                -- ALU operation and PC increment
                if cond_met = '1' then
                    -- Execute instruction based on opcode
                    case opcode is
                        when "0000" => -- ADD
                            alu_op <= "0000";
                            
                        when "0001" => -- SUB
                            alu_op <= "0001";
                            
                        when "0010" => -- AND
                            alu_op <= "0010";
                            
                        when "0011" => -- OR
                            alu_op <= "0011";
                            
                        when "0100" => -- XOR
                            alu_op <= "0100";
                            
                        when "0101" => -- NOT
                            alu_op <= "0101";
                            
                        when "0110" => -- LSL
                            alu_op <= "0110";
                            
                        when "0111" => -- LSR
                            alu_op <= "0111";
                            
                        when "1000" => -- MTA
                            alu_op <= "1000"; -- Pass through
                            
                        when "1001" => -- MTR
                            alu_op <= "1001"; -- Pass through
                            
                        when "1010" => -- LDA
                            alu_op <= "1010";
                            sel_ram_addr <= '1'; -- Use ACC as memory address
                            sel_rf_din <= '1';   -- Select memory data for register input
                            
                        when "1011" => -- STA
                            alu_op <= "1011";
                            sel_ram_addr <= '1'; -- Use ACC as memory address
                            ram_we <= '1';       -- Enable memory write
                            
                        when "1100" => -- JMP
                            alu_op <= "1100";
                            sel_op1 <= '1';      -- Select PC for ALU input
                            
                        when "1101" => -- BRA
                            alu_op <= "1101";
                            sel_op1 <= '1';      -- Select PC for ALU input
                            
                        when "1110" => -- CAL
                            alu_op <= "1110";
                            sel_op1 <= '1';      -- Select PC for ALU input
                            rpc_ce <= '1';       -- Store return address in RPC
                            
                        when "1111" => -- RET
                            alu_op <= "1111";
                            sel_op1 <= '1';      -- Select PC for ALU input
                            
                        when others =>
                            alu_op <= "0000";
                    end case;
                end if;
                
                -- Always increment PC except for JMP/BRA/CAL/RET
                if opcode /= "1100" and opcode /= "1101" and 
                   opcode /= "1110" and opcode /= "1111" then
                    pc_ce <= '1';
                end if;
                
            when STORE =>
                if cond_met = '1' then
                    -- Store result based on opcode
                    case opcode is
                        when "0000" | "0001" | "0010" | "0011" | 
                             "0100" | "0101" | "0110" | "0111" =>
                            acc_ce <= '1';      -- Arithmetic/Logic operations store to ACC
                            status_ce <= updt;  -- Update status if updt flag is set
                            
                        when "1000" => -- MTA
                            acc_ce <= '1';      -- Store to ACC
                            status_ce <= updt;  -- Update status if updt flag is set
                            
                        when "1001" => -- MTR
                            rx_ce <= '1';       -- Store to Rx
                            status_ce <= updt;  -- Update status if updt flag is set
                            
                        when "1010" => -- LDA
                            acc_ce <= '1';      -- Store to ACC
                            status_ce <= updt;  -- Update status if updt flag is set
                            
                        when "1100" | "1101" | "1110" => -- JMP/BRA/CAL
                            pc_ce <= '1';       -- Store to PC for jumps
                            
                        when "1111" => -- RET
                            pc_ce <= '1';       -- Store RPC to PC
                            
                        when others =>
                            null;
                    end case;
                end if;
                
            when others =>
                null;
        end case;
    end process;

end Behavioral;