library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
    Port (
        op      : in  STD_LOGIC_VECTOR(3 downto 0);
        a       : in  STD_LOGIC_VECTOR(15 downto 0);
        b       : in  STD_LOGIC_VECTOR(15 downto 0);
        y       : out STD_LOGIC_VECTOR(15 downto 0);
        z_flag  : out STD_LOGIC;
        n_flag  : out STD_LOGIC;
        c_flag  : out STD_LOGIC;
        v_flag  : out STD_LOGIC
    );
end alu;

architecture Behavioral of alu is
    -- Opcodes as per the specification
    constant AND_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    constant OR_OP   : STD_LOGIC_VECTOR(3 downto 0) := "0001";
    constant XOR_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0010";
    constant NOT_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0011";
    constant ADD_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0100";
    constant SUB_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0101";
    constant LSL_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0110";
    constant LSR_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0111";
    constant LDA_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1000";
    constant STA_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1001";
    constant MTA_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1010";
    constant MTR_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1011";
    constant JRP_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1100";
    constant JRN_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1101";
    constant JPR_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1110";
    constant CAL_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1111";
    
    -- Internal signals
    signal result    : STD_LOGIC_VECTOR(15 downto 0);
    signal temp_z    : STD_LOGIC;
    signal temp_n    : STD_LOGIC;
    signal temp_c    : STD_LOGIC;
    signal temp_v    : STD_LOGIC;
begin
    process(op, a, b)
        -- Extended results for arithmetic operations
        variable add_result : STD_LOGIC_VECTOR(16 downto 0);
        variable sub_result : STD_LOGIC_VECTOR(16 downto 0);
        -- For shift operations
        variable shift_amt : integer;
        variable shift_carry : STD_LOGIC;
        variable shift_overflow : STD_LOGIC;
        -- Original sign bits for overflow detection
        variable a_sign, b_sign, res_sign : STD_LOGIC;
    begin
        -- Default values
        result <= (x"0000");
        temp_z <= '0';
        temp_n <= '0';
        temp_c <= '0';
        temp_v <= '0';
        
        case op is
            when ADD_OP =>
                -- Addition with carry
                add_result := std_logic_vector(('0' & unsigned(a)) + ('0' & unsigned(b)));
                result <= add_result(15 downto 0);
                
                -- Set flags
                a_sign := a(15);
                b_sign := b(15);
                res_sign := add_result(15);
                
                -- Carry flag
                temp_c <= add_result(16);
                
                -- Overflow flag - happens when both operands have same sign but result has different sign
                temp_v <= (a_sign and b_sign and not res_sign) or (not a_sign and not b_sign and res_sign);
                
            when SUB_OP =>
                -- Subtraction: A - B
                sub_result := std_logic_vector(('0' & unsigned(a)) - ('0' & unsigned(b)));
                result <= sub_result(15 downto 0);
                
                -- Set flags
                a_sign := a(15);
                b_sign := b(15);
                res_sign := sub_result(15);
                
                -- Carry flag (set when no borrow needed)
                temp_c <= not sub_result(16);
                
                -- Overflow flag - happens when operands have different signs and result sign matches subtracted operand
                temp_v <= (a_sign and not b_sign and not res_sign) or (not a_sign and b_sign and res_sign);
                
            when AND_OP =>
                -- Bitwise AND
                result <= a and b;
                -- The logical operations affect the N and Z flags
                temp_n <= result(15);
                temp_z <= '1' when result = (x"0000") else '0';
                
                
            when OR_OP =>
                -- Bitwise OR
                result <= a or b;
                                -- The logical operations affect the N and Z flags
                temp_n <= result(15);
                temp_z <= '1' when result = (x"0000") else '0';
                
            when XOR_OP =>
                -- Bitwise XOR
                result <= a xor b;
                                -- The logical operations affect the N and Z flags
                temp_n <= result(15);
                temp_z <= '1' when result = (x"0000") else '0';
                
            when NOT_OP =>
                -- Bitwise NOT
                result <= not b;
                                -- The logical operations affect the N and Z flags
                temp_n <= result(15);
                temp_z <= '1' when result = (x"0000") else '0';
                
            when LSL_OP =>
                -- Logical shift left
                shift_amt := to_integer(unsigned(b(4 downto 0))); -- Use only 5 bits for shift amount
                shift_carry := '0';
                shift_overflow := '0';
                
                if shift_amt = 0 then
                    -- No shift
                    result <= a;
                elsif shift_amt >= 16 then
                    -- Shift by 16 or more results in all zeros
                    result <= (x"0000");
                    -- Carry is set if any bit in A was 1
                    if unsigned(a) /= 0 then
                        shift_carry := '1';
                    end if;
                    -- Overflow if original MSB was 1
                    shift_overflow := a(15);
                else
                    -- Normal shift operation
                    result <= std_logic_vector(shift_left(unsigned(a), shift_amt));
                    
                    -- Check for carry (any of the bits shifted out was 1)
                    if unsigned(a(15 downto 16-shift_amt)) /= 0 then
                        shift_carry := '1';
                    end if;
                    
                    -- Overflow if sign bit changes after shift
                    if a(15) /= result(15) then
                        shift_overflow := '1';
                    end if;
                end if;
                
                temp_c <= shift_carry;
                temp_v <= shift_overflow;
                
            when LSR_OP =>
                -- Logical shift right
                shift_amt := to_integer(unsigned(b(4 downto 0))); -- Use only 5 bits for shift amount
                shift_carry := '0';
                shift_overflow := '0';
                
                if shift_amt = 0 then
                    -- No shift
                    result <= a;
                elsif shift_amt >= 16 then
                    -- Shift by 16 or more results in all zeros
                    result <= (x"0000");
                    -- Carry is set if any bit in A was 1
                    if unsigned(a) /= 0 then
                        shift_carry := '1';
                    end if;
                    -- Overflow if original MSB was 1
                    shift_overflow := a(15);
                else
                    -- Normal shift operation
                    result <= std_logic_vector(shift_right(unsigned(a), shift_amt));
                    
                    -- Check for carry (any of the bits shifted out was 1)
                    if unsigned(a(shift_amt-1 downto 0)) /= 0 then
                        shift_carry := '1';
                    end if;
                    
                    -- Overflow if sign bit changes after shift
                    if a(15) /= result(15) then
                        shift_overflow := '1';
                    end if;
                end if;
                
                temp_c <= shift_carry;
                temp_v <= shift_overflow;
            
            when LDA_OP =>
                -- Load Accumulator (acc ? [rX/X])
                result <= b;
                
            when STA_OP =>
                -- Store Accumulator ([rX/X] ? acc)
                result <= a;
                
            when MTA_OP =>
                -- Move to Accumulator (acc ? rX/X)
                result <= b;
                
            when MTR_OP =>
                -- Move to Register (rX ? acc)
                result <= a;
            when JRP_OP =>
                result <= b;
                -- Jump Relative Positive
                
            when JRN_OP =>
                -- Jump Relative Negative
                result <= b;
            when JPR_OP =>
                -- Jump Positive Register
                result <= b;
            when CAL_OP =>
                result <= b;
                -- Call Subroutine: It's up to the control logic to handle RPC and PC
            when others =>
                result <= (x"0000");  -- default
        end case;
        
        -- Common flag updates after all operations
        temp_z <= '1' when result = (x"0000") else '0';
        temp_n <= result(15);
    end process;

    y <= result;
    z_flag <= temp_z;
    n_flag <= temp_n;
    c_flag <= temp_c;
    v_flag <= temp_v;
end Behavioral;

