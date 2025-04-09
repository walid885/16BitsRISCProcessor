library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;

entity alu_tb is
end alu_tb;

architecture Behavioral of alu_tb is
    -- Component declaration
    component alu
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
    end component;
    
    -- Inputs
    signal op     : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal a      : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal b      : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    
    -- Outputs
    signal y      : STD_LOGIC_VECTOR(15 downto 0);
    signal z_flag : STD_LOGIC;
    signal n_flag : STD_LOGIC;
    signal c_flag : STD_LOGIC;
    signal v_flag : STD_LOGIC;
    
    -- Constants for operation codes
    constant ADD_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1000";
    constant SUB_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1001";
    constant AND_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1010";
    constant OR_OP   : STD_LOGIC_VECTOR(3 downto 0) := "1011";
    constant XOR_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1100";
    constant NOT_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1101";
    constant LSL_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1110";
    constant LSR_OP  : STD_LOGIC_VECTOR(3 downto 0) := "1111";
    constant MTA_OP  : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    
    -- Function to convert std_logic_vector to hex string for VHDL-2002
    function to_hex_string(slv: std_logic_vector) return string is
        variable hex_str: string(1 to slv'length/4);
        variable nibble: std_logic_vector(3 downto 0);
        variable i_slv: integer;
        variable i_str: integer;
    begin
        i_str := 1;
        for i in (slv'length/4) downto 1 loop
            i_slv := (i-1)*4;
            nibble := slv(i_slv+3 downto i_slv);
            case nibble is
                when "0000" => hex_str(i_str) := '0';
                when "0001" => hex_str(i_str) := '1';
                when "0010" => hex_str(i_str) := '2';
                when "0011" => hex_str(i_str) := '3';
                when "0100" => hex_str(i_str) := '4';
                when "0101" => hex_str(i_str) := '5';
                when "0110" => hex_str(i_str) := '6';
                when "0111" => hex_str(i_str) := '7';
                when "1000" => hex_str(i_str) := '8';
                when "1001" => hex_str(i_str) := '9';
                when "1010" => hex_str(i_str) := 'A';
                when "1011" => hex_str(i_str) := 'B';
                when "1100" => hex_str(i_str) := 'C';
                when "1101" => hex_str(i_str) := 'D';
                when "1110" => hex_str(i_str) := 'E';
                when "1111" => hex_str(i_str) := 'F';
                when others => hex_str(i_str) := 'X';
            end case;
            i_str := i_str + 1;
        end loop;
        return hex_str;
    end function;
    
    -- Test procedure
    procedure check_result(
        signal op_sig : in  STD_LOGIC_VECTOR(3 downto 0);
        signal a_sig  : in  STD_LOGIC_VECTOR(15 downto 0);
        signal b_sig  : in  STD_LOGIC_VECTOR(15 downto 0);
        signal y_sig  : in  STD_LOGIC_VECTOR(15 downto 0);
        expected_y    : in  STD_LOGIC_VECTOR(15 downto 0);
        expected_z    : in  STD_LOGIC;
        expected_n    : in  STD_LOGIC;
        expected_c    : in  STD_LOGIC;
        expected_v    : in  STD_LOGIC;
        test_name     : in  STRING
    ) is
    begin
        assert y_sig = expected_y 
            report "Test " & test_name & " failed: y = 0x" & 
                  to_hex_string(y_sig) & 
                  ", expected = 0x" & to_hex_string(expected_y)
            severity error;
            
        assert z_flag = expected_z 
            report "Test " & test_name & " failed: z_flag = " & 
                  std_logic'image(z_flag) & 
                  ", expected = " & std_logic'image(expected_z)
            severity error;
            
        assert n_flag = expected_n 
            report "Test " & test_name & " failed: n_flag = " & 
                  std_logic'image(n_flag) & 
                  ", expected = " & std_logic'image(expected_n)
            severity error;
            
        assert c_flag = expected_c 
            report "Test " & test_name & " failed: c_flag = " & 
                  std_logic'image(c_flag) & 
                  ", expected = " & std_logic'image(expected_c)
            severity error;
            
        assert v_flag = expected_v 
            report "Test " & test_name & " failed: v_flag = " & 
                  std_logic'image(v_flag) & 
                  ", expected = " & std_logic'image(expected_v)
            severity error;
    end procedure;
    
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: alu port map (
        op     => op,
        a      => a,
        b      => b,
        y      => y,
        z_flag => z_flag,
        n_flag => n_flag,
        c_flag => c_flag,
        v_flag => v_flag
    );
    
    -- Stimulus process
    stim_proc: process
    begin
        -- Test ADD operation (positive values)
        op <= ADD_OP;
        a <= X"0005";
        b <= X"0003";
        wait for 10 ns;
        check_result(op, a, b, y, X"0008", '0', '0', '0', '0', "ADD positive");
        
        -- Test ADD operation (with carry)
        op <= ADD_OP;
        a <= X"FFFF";
        b <= X"0001";
        wait for 10 ns;
        check_result(op, a, b, y, X"0000", '1', '0', '1', '0', "ADD with carry");
        
        -- Test ADD operation (with overflow)
        op <= ADD_OP;
        a <= X"7FFF";  -- Max positive value
        b <= X"0001";
        wait for 10 ns;
        check_result(op, a, b, y, X"8000", '0', '1', '0', '1', "ADD with overflow");
        
        -- Test SUB operation
        op <= SUB_OP;
        a <= X"000A";
        b <= X"0003";
        wait for 10 ns;
        check_result(op, a, b, y, X"0007", '0', '0', '1', '0', "SUB positive");
        
        -- Test SUB operation (with borrow)
        op <= SUB_OP;
        a <= X"0003";
        b <= X"0005";
        wait for 10 ns;
        check_result(op, a, b, y, X"FFFE", '0', '1', '0', '0', "SUB with borrow");
        
        -- Test SUB operation (with overflow)
        op <= SUB_OP;
        a <= X"8000";  -- Most negative value
        b <= X"0001";
        wait for 10 ns;
        check_result(op, a, b, y, X"7FFF", '0', '0', '1', '1', "SUB with overflow");
        
        -- Test AND operation
        op <= AND_OP;
        a <= X"00FF";
        b <= X"0F0F";
        wait for 10 ns;
        check_result(op, a, b, y, X"000F", '0', '0', '0', '0', "AND");
        
        -- Test OR operation
        op <= OR_OP;
        a <= X"00FF";
        b <= X"0F0F";
        wait for 10 ns;
        check_result(op, a, b, y, X"0FFF", '0', '0', '0', '0', "OR");
        
        -- Test XOR operation
        op <= XOR_OP;
        a <= X"00FF";
        b <= X"0F0F";
        wait for 10 ns;
        check_result(op, a, b, y, X"0FF0", '0', '0', '0', '0', "XOR");
        
        -- Test NOT operation
        op <= NOT_OP;
        a <= X"0000";  -- Not used
        b <= X"00FF";
        wait for 10 ns;
        check_result(op, a, b, y, X"FF00", '0', '1', '0', '0', "NOT");
        
        -- Test LSL operation
        op <= LSL_OP;
        a <= X"8001";  -- 1000 0000 0000 0001
        b <= X"0004";  -- Shift by 4
        wait for 10 ns;
        check_result(op, a, b, y, X"0010", '0', '0', '1', '1', "LSL");
        
        -- Test LSR operation
        op <= LSR_OP;
        a <= X"8001";  -- 1000 0000 0000 0001
        b <= X"0001";  -- Shift by 1
        wait for 10 ns;
        check_result(op, a, b, y, X"4000", '0', '0', '1', '1', "LSR");
        
        -- Test MTA operation
        op <= MTA_OP;
        a <= X"0000";  -- Not used
        b <= X"ABCD";
        wait for 10 ns;
        check_result(op, a, b, y, X"ABCD", '0', '1', '0', '0', "MTA");
        
        -- Test Zero result (for Z flag)
        op <= SUB_OP;
        a <= X"0005";
        b <= X"0005";
        wait for 10 ns;
        check_result(op, a, b, y, X"0000", '1', '0', '1', '0', "Zero result");
        
        -- End simulation
        wait;
    end process;
end Behavioral;