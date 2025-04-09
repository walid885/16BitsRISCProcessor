library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
    Port (
        op      : in  STD_LOGIC_VECTOR(3 downto 0);    -- Operation code
        a       : in  STD_LOGIC_VECTOR(15 downto 0);   -- Input operand A (typically Accumulator)
        b       : in  STD_LOGIC_VECTOR(15 downto 0);   -- Input operand B
        y       : out STD_LOGIC_VECTOR(15 downto 0);   -- Result output
        z_flag  : out STD_LOGIC;                       -- Zero flag
        n_flag  : out STD_LOGIC;                       -- Negative flag
        c_flag  : out STD_LOGIC;                       -- Carry flag
        v_flag  : out STD_LOGIC                        -- Overflow flag
    );
end alu;

architecture Behavioral of alu is
    -- Opcodes as per the specification
    constant ADD_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1000";  -- Addition
    constant SUB_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1001";  -- Subtraction
    constant AND_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1010";  -- AND
    constant OR_OP   : STD_LOGIC_VECTOR(3 downto 0) := "1011";  -- OR
    constant XOR_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1100";  -- XOR
    constant NOT_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1101";  -- NOT
    constant LSL_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1110";  -- Logical Shift Left
    constant LSR_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1111";  -- Logical Shift Right
    constant MTA_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0000";  -- Move to Accumulator
    constant MTR_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0001";  -- Move to Register
    constant CAL_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0010";  -- Call
    constant RET_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0011";  -- Return
    
    -- Internal signals
    signal result    : STD_LOGIC_VECTOR(15 downto 0);
    signal add_result: STD_LOGIC_VECTOR(16 downto 0);  -- One bit wider for carry
    signal sub_result: STD_LOGIC_VECTOR(16 downto 0);  -- One bit wider for borrow
    
    -- For shift operations
    signal shift_left_result : STD_LOGIC_VECTOR(31 downto 0);
    signal shift_right_result : STD_LOGIC_VECTOR(31 downto 0);
    
    -- Original sign bits for overflow detection
    signal a_sign, b_sign, result_sign : STD_LOGIC;
begin
    -- Compute operation results
    process(op, a, b)
        variable shift_amt : INTEGER;  -- Changed to variable
    begin
        -- Default values
        add_result <= (others => '0');
        sub_result <= (others => '0');
        result <= (others => '0');
        c_flag <= '0';
        v_flag <= '0';
        
        -- Determine sign bits for overflow detection
        a_sign <= a(15);
        
        case op is
            when ADD_OP =>
                -- Addition with carry
                add_result <= std_logic_vector(('0' & unsigned(a)) + ('0' & unsigned(b)));
                result <= add_result(15 downto 0);
                c_flag <= add_result(16);  -- Carry out
                
                -- Overflow detection for addition
                b_sign <= b(15);
                result_sign <= add_result(15);
                v_flag <= (a_sign and b_sign and not result_sign) or 
                          (not a_sign and not b_sign and result_sign);
                
            when SUB_OP =>
                -- Subtraction with borrow
                sub_result <= std_logic_vector(('0' & unsigned(a)) - ('0' & unsigned(b)));
                result <= sub_result(15 downto 0);
                c_flag <= not sub_result(16);  -- Borrow out (inverted)
                
                -- Overflow detection for subtraction
                b_sign <= not b(15);  -- Invert sign for subtraction
                result_sign <= sub_result(15);
                v_flag <= (a_sign and b_sign and not result_sign) or 
                          (not a_sign and not b_sign and result_sign);
                
            when AND_OP =>
                -- Bitwise AND
                result <= a and b;
                
            when OR_OP =>
                -- Bitwise OR
                result <= a or b;
                
            when XOR_OP =>
                -- Bitwise XOR
                result <= a xor b;
                
            when NOT_OP =>
                -- Bitwise NOT (one's complement)
                result <= not b;
                
            when LSL_OP =>
                -- Logical shift left
                shift_amt := to_integer(unsigned(b(4 downto 0)));  -- Use only lower 5 bits for shift amount
                
                -- Extended shift result for carry detection
                shift_left_result <= std_logic_vector(unsigned(a & X"0000") sll shift_amt);
                result <= shift_left_result(31 downto 16);
                
                -- Set carry if any bit was shifted out
                if shift_amt > 0 and shift_amt <= 16 then
                    if (unsigned(a(15 downto 16-shift_amt)) /= 0) then
                        c_flag <= '1';
                    end if;
                elsif shift_amt > 16 then
                    -- If shift amount is greater than word size, check if any bit was 1
                    if unsigned(a) /= 0 then
                        c_flag <= '1';
                    end if;
                end if;
                
                -- Overflow if sign bit changes
                v_flag <= a(15) xor result(15);
                
            when LSR_OP =>
                -- Logical shift right
                shift_amt := to_integer(unsigned(b(4 downto 0)));  -- Use only lower 5 bits for shift amount
                
                -- Extended shift result for carry detection
                shift_right_result <= std_logic_vector(unsigned(X"0000" & a) srl shift_amt);
                result <= shift_right_result(15 downto 0);
                
                -- Set carry if any bit was shifted out
                if shift_amt > 0 and shift_amt <= 16 then
                    if (unsigned(a(shift_amt-1 downto 0)) /= 0) then
                        c_flag <= '1';
                    end if;
                elsif shift_amt > 16 then
                    -- If shift amount is greater than word size, check if any bit was 1
                    if unsigned(a) /= 0 then
                        c_flag <= '1';
                    end if;
                end if;
                
                -- Overflow if sign bit changes (for logical shifts, will be 0 if shifted enough)
                v_flag <= a(15) xor result(15);
                
            when MTA_OP | MTR_OP | CAL_OP | RET_OP =>
                -- Move operations, just pass B through
                result <= b;
                
            when others =>
                -- Default case
                result <= (others => '0');
        end case;
    end process;
    
    -- Set flags based on result
    z_flag <= '1' when unsigned(result) = 0 else '0';  -- Zero flag
    n_flag <= result(15);  -- Negative flag (sign bit)
    
    -- Output the result
    y <= result;
end Behavioral;