library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
    Port (
        op      : in  STD_LOGIC_VECTOR(3 downto 0);    -- Operation code
        a       : in  STD_LOGIC_VECTOR(15 downto 0);   -- Input operand A (Accumulator)
        b       : in  STD_LOGIC_VECTOR(15 downto 0);   -- Input operand B
        y       : out STD_LOGIC_VECTOR(15 downto 0);   -- Result output
        z_flag  : out STD_LOGIC;                       -- Zero flag
        n_flag  : out STD_LOGIC;                       -- Negative flag
        c_flag  : out STD_LOGIC;                       -- Carry flag
        v_flag  : out STD_LOGIC                        -- Overflow flag
    );
end alu;

architecture Behavioral of alu is
    -- Define opcodes as constants for better readability
    constant AND_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0000";  -- AND (acc ? acc AND rX/X)
    constant OR_OP   : STD_LOGIC_VECTOR(3 downto 0) := "0001";  -- OR  (acc ? acc OR rX/X)
    constant XOR_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0010";  -- XOR (acc ? acc XOR rX/X)
    constant NOT_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0011";  -- NOT (acc ? NOT rX/X)
    constant ADD_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0100";  -- ADD (acc ? acc + rX/X)
    constant SUB_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0101";  -- SUB (acc ? acc - rX/X)
    constant LSL_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0110";  -- LSL (acc ? acc << rX/X)
    constant LSR_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0111";  -- LSR (acc ? acc >> rX/X)
    constant LDA_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1000";  -- LDA (acc ? [rX/X])
    constant STA_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1001";  -- STA ([rX/X] ? acc)
    constant MTA_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1010";  -- MTA (acc ? rX/X)
    constant MTR_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1011";  -- MTR (rX ? acc)
    constant JRP_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1100";  -- MTR (rX ? acc)
    constant JRN_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1101";  -- MTR (rX ? acc)
    constant JPR_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1110";  -- MTR (rX ? acc)
    constant CALL_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1111";  -- MTR (rX ? acc)
    
    -- Internal signals
    signal result      : STD_LOGIC_VECTOR(15 downto 0);
    signal zero_result : STD_LOGIC;
    signal neg_result  : STD_LOGIC;
    signal carry_out   : STD_LOGIC;
    signal overflow    : STD_LOGIC;
begin
    process(op, a, b)
        variable temp_result : unsigned(16 downto 0); -- For intermediate calculations only
        variable shift_amt   : integer;
        variable old_msb     : STD_LOGIC;
        variable new_msb     : STD_LOGIC;
    begin
        -- Default values
        result <= (x"0000");
        zero_result <= '0';
        neg_result <= '0';
        carry_out <= '0';
        overflow <= '0';

        case op is
            when AND_OP =>
                -- Bitwise AND
                result <= a and b;
                -- Logical operations only affect Z and N flags
                
            when OR_OP =>
                -- Bitwise OR
                result <= a or b;
                
            when XOR_OP =>
                -- Bitwise XOR
                result <= a xor b;
                
            when NOT_OP =>
                -- Bitwise NOT (of B)
                result <= not b;
                -- Make sure to set negative flag correctly
                neg_result <= not b(15);
                
            when ADD_OP =>
                -- Addition operation (without using 17-bit calculation directly)
                -- Calculate in a 16-bit compliant way
                result <= std_logic_vector(unsigned(a) + unsigned(b));
                
                -- Carry detection using comparison
                if (unsigned(a) > unsigned(not b)) then
                    carry_out <= '1';
                end if;
                
                -- Overflow detection for signed addition
                if ((a(15) = '0' and b(15) = '0' and result(15) = '1') or
                    (a(15) = '1' and b(15) = '1' and result(15) = '0')) then
                    overflow <= '1';
                end if;
                
            when SUB_OP =>
                -- Subtraction operation
                result <= std_logic_vector(unsigned(a) - unsigned(b));
                
                -- Borrow detection (inverse of carry)
                if (unsigned(a) >= unsigned(b)) then
                    carry_out <= '1';  -- No borrow needed
                else
                    carry_out <= '0';  -- Borrow needed
                end if;
                
                -- Overflow detection for signed subtraction
                if ((a(15) = '0' and b(15) = '1' and result(15) = '1') or
                    (a(15) = '1' and b(15) = '0' and result(15) = '0')) then
                    overflow <= '1';
                end if;
                
            when LSL_OP =>
                -- Logical shift left
                shift_amt := to_integer(unsigned(b(4 downto 0))); -- Use only 5 bits
                old_msb := a(15);
                
                if shift_amt = 0 then
                    result <= a;
                elsif shift_amt >= 16 then
                    -- All bits shifted out, result is zero
                    result <= (x"0000");
                    
                    -- If any bit was 1, carry is set
                    if unsigned(a) /= 0 then
                        carry_out <= '1';
                    end if;
                else
                    -- Normal shift operation
                    result <= std_logic_vector(shift_left(unsigned(a), shift_amt));
                    
                    -- Set carry if any bits shift out
                    if shift_amt > 0 and unsigned(a(15 downto 16-shift_amt)) /= 0 then
                        carry_out <= '1';
                    end if;
                end if;
                
                -- Set overflow if sign bit changes
                new_msb := result(15);
                if old_msb /= new_msb then
                    overflow <= '1';
                end if;
                
            when LSR_OP =>
                -- Logical shift right
                shift_amt := to_integer(unsigned(b(4 downto 0))); -- Use only 5 bits
                old_msb := a(15);
                
                if shift_amt = 0 then
                    result <= a;
                elsif shift_amt >= 16 then
                    -- All bits shifted out, result is zero
                    result <= (x"0000");
                    
                    -- If any bit was 1, carry is set
                    if unsigned(a) /= 0 then
                        carry_out <= '1';
                    end if;
                else
                    -- Normal shift operation
                    result <= std_logic_vector(shift_right(unsigned(a), shift_amt));
                    
                    -- Set carry if any bits shift out
                    if shift_amt > 0 and unsigned(a(shift_amt-1 downto 0)) /= 0 then
                        carry_out <= '1';
                    end if;
                end if;
                
                -- Set overflow if sign bit changes
                new_msb := result(15);
                if old_msb /= new_msb then
                    overflow <= '1';
                end if;
                
            when MTA_OP | LDA_OP =>
                -- Move to Accumulator (or Load Accumulator)
                result <= b;
                -- For MTA, need to set negative flag correctly
                neg_result <= b(15);
                
            when MTR_OP | STA_OP =>
                -- Move to Register (or Store Accumulator)
                result <= a;
                -- Flags are not typically affected
                
            when others =>
                -- For any undefined operation, result is 0
                result <= (x"0000");
        end case;
        
        -- Common flag calculations for all operations
        -- Zero flag: Set if result is all zeros
        if unsigned(result) = 0 then
            zero_result <= '1';
        else 
            zero_result <= '0';
        end if;
        
        -- Negative flag: Set if MSB of result is 1 (unless already set)
        if neg_result = '0' then
            neg_result <= result(15);
        end if;
    end process;
    
    -- Assign output signals
    y <= result;
    z_flag <= zero_result;
    n_flag <= neg_result;
    c_flag <= carry_out;
    v_flag <= overflow;
end Behavioral;
