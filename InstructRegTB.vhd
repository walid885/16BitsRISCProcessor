library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity instruction_register_tb is
end instruction_register_tb;

architecture Behavioral of instruction_register_tb is
    -- Component declaration
    component instruction_register
        Port (
            clk     : in  STD_LOGIC;
            rst     : in  STD_LOGIC;
            ce      : in  STD_LOGIC;
            i       : in  STD_LOGIC_VECTOR(15 downto 0);
            o       : out STD_LOGIC_VECTOR(15 downto 0);
            cond    : out STD_LOGIC_VECTOR(3 downto 0);
            op      : out STD_LOGIC_VECTOR(3 downto 0);
            updt    : out STD_LOGIC;
            imm     : out STD_LOGIC;
            val     : out STD_LOGIC_VECTOR(5 downto 0)
        );
    end component;
    
    -- Inputs
    signal clk  : STD_LOGIC := '0';
    signal rst  : STD_LOGIC := '0';
    signal ce   : STD_LOGIC := '0';
    signal i    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    
    -- Outputs
    signal o    : STD_LOGIC_VECTOR(15 downto 0);
    signal cond : STD_LOGIC_VECTOR(3 downto 0);
    signal op   : STD_LOGIC_VECTOR(3 downto 0);
    signal updt : STD_LOGIC;
    signal imm  : STD_LOGIC;
    signal val  : STD_LOGIC_VECTOR(5 downto 0);
    
    -- Clock period definition
    constant clk_period : time := 10 ns;
    
    -- Helper function to create an instruction word
    function create_instruction(
        cond_val : STD_LOGIC_VECTOR(3 downto 0);
        op_val   : STD_LOGIC_VECTOR(3 downto 0);
        updt_val : STD_LOGIC;
        imm_val  : STD_LOGIC;
        val_val  : STD_LOGIC_VECTOR(5 downto 0)
    ) return STD_LOGIC_VECTOR is
        variable result : STD_LOGIC_VECTOR(15 downto 0);
    begin
        result := cond_val & op_val & updt_val & imm_val & val_val;
        return result;
    end function;
    
    -- Helper procedure to execute a test case
    procedure test_instruction(
        signal clk_in     : in  STD_LOGIC;
        signal i_inout    : inout STD_LOGIC_VECTOR(15 downto 0);
        signal ce_inout   : inout STD_LOGIC;
        signal o_in       : in  STD_LOGIC_VECTOR(15 downto 0);
        signal cond_in    : in  STD_LOGIC_VECTOR(3 downto 0);
        signal op_in      : in  STD_LOGIC_VECTOR(3 downto 0);
        signal updt_in    : in  STD_LOGIC;
        signal imm_in     : in  STD_LOGIC;
        signal val_in     : in  STD_LOGIC_VECTOR(5 downto 0);
        constant test_num : in  integer;
        constant cond_exp : in  STD_LOGIC_VECTOR(3 downto 0);
        constant op_exp   : in  STD_LOGIC_VECTOR(3 downto 0);
        constant updt_exp : in  STD_LOGIC;
        constant imm_exp  : in  STD_LOGIC;
        constant val_exp  : in  STD_LOGIC_VECTOR(5 downto 0);
        constant inst_desc: in  string
    ) is
        constant period : time := 10 ns;
    begin
        -- Apply inputs
        i_inout <= create_instruction(cond_exp, op_exp, updt_exp, imm_exp, val_exp);
        ce_inout <= '1';
        wait for period;
        ce_inout <= '0';
        wait for period;
        
        -- Check outputs
        assert o_in = create_instruction(cond_exp, op_exp, updt_exp, imm_exp, val_exp) 
            report "Test " & integer'image(test_num) & " failed: full instruction for " & inst_desc severity error;
        assert cond_in = cond_exp 
            report "Test " & integer'image(test_num) & " failed: condition field for " & inst_desc severity error;
        assert op_in = op_exp 
            report "Test " & integer'image(test_num) & " failed: opcode field for " & inst_desc severity error;
        assert updt_in = updt_exp 
            report "Test " & integer'image(test_num) & " failed: update flag for " & inst_desc severity error;
        assert imm_in = imm_exp 
            report "Test " & integer'image(test_num) & " failed: immediate flag for " & inst_desc severity error;
        assert val_in = val_exp 
            report "Test " & integer'image(test_num) & " failed: value field for " & inst_desc severity error;
    end procedure;
    
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: instruction_register port map (
        clk  => clk,
        rst  => rst,
        ce   => ce,
        i    => i,
        o    => o,
        cond => cond,
        op   => op,
        updt => updt,
        imm  => imm,
        val  => val
    );
    
    -- Clock process
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
    
    -- Stimulus process
    stim_proc: process
    begin
        -- Initial reset
        report "Starting instruction register tests";
        rst <= '1';
        wait for clk_period*2;
        rst <= '0';
        wait for clk_period*2;
        
        -- Test case 1: ADD instruction (True condition, update flags, register addressing)
        -- Instruction: 1001 1000 1 0 000001 = ADDT r1
        report "Test 1: ADDT r1";
        test_instruction(
            clk, i, ce, o, cond, op, updt, imm, val,
            1, "1001", "1000", '1', '0', "000001", "ADDT r1"
        );
        
        -- Test case 2: SUB instruction (Zero condition, no update, immediate addressing)
        -- Instruction: 0010 1001 0 1 010101 = SUBZ #0x15
        report "Test 2: SUBZ #0x15";
        test_instruction(
            clk, i, ce, o, cond, op, updt, imm, val,
            2, "0010", "1001", '0', '1', "010101", "SUBZ #0x15"
        );
        
        -- Test case 3: Write disabled (CE=0)
        report "Test 3: Write disabled (CE=0)";
        i <= create_instruction("0000", "0000", '0', '0', "000000");
        ce <= '0';
        wait for clk_period*2;
        -- Should still have values from Test 2
        assert o = create_instruction("0010", "1001", '0', '1', "010101") 
            report "Test 3 failed: value changed when CE=0" severity error;
            
        -- Test case 4: AND instruction (negative condition, update flags, register addressing)
        -- Instruction: 0100 0000 1 0 001010 = ANDN r10
        report "Test 4: ANDN r10";
        test_instruction(
            clk, i, ce, o, cond, op, updt, imm, val,
            4, "0100", "0000", '1', '0', "001010", "ANDN r10"
        );
        
        -- Test case 5: OR instruction (positive condition, no update, immediate addressing)
        -- Instruction: 0101 0001 0 1 111111 = ORP #0x3F
        report "Test 5: ORP #0x3F";
        test_instruction(
            clk, i, ce, o, cond, op, updt, imm, val,
            5, "0101", "0001", '0', '1', "111111", "ORP #0x3F"
        );
        
        -- Test case 6: XOR instruction (always condition, update flags, register addressing)
        -- Instruction: 1111 0010 1 0 000000 = XORT r0 (accumulateur)
        report "Test 6: XORT r0";
        test_instruction(
            clk, i, ce, o, cond, op, updt, imm, val,
            6, "1111", "0010", '1', '0', "000000", "XORT r0"
        );
        
        -- Test case 7: NOT instruction (carry condition, no update, immediate addressing)
        -- Instruction: 0011 0011 0 1 101010 = NOTC #0x2A
        report "Test 7: NOTC #0x2A";
        test_instruction(
            clk, i, ce, o, cond, op, updt, imm, val,
            7, "0011", "0011", '0', '1', "101010", "NOTC #0x2A"
        );
        
        -- Test case 8: LSL instruction (overflow condition, update flags, register addressing)
        -- Instruction: 0001 0100 1 0 111110 = LSLV r62 (RPC)
        report "Test 8: LSLV r62";
        test_instruction(
            clk, i, ce, o, cond, op, updt, imm, val,
            8, "0001", "0100", '1', '0', "111110", "LSLV r62"
        );
        
        -- Test case 9: LSR instruction (carry condition, update flags, immediate addressing)
        -- Instruction: 0011 0101 1 1 000100 = LSRC #0x04
        report "Test 9: LSRC #0x04";
        test_instruction(
            clk, i, ce, o, cond, op, updt, imm, val,
            9, "0011", "0101", '1', '1', "000100", "LSRC #0x04"
        );
        
        -- Test case 10: MTA instruction (positive condition, no update, register addressing)
        -- Instruction: 0101 0110 0 0 111111 = MTAP r63 (PC)
        report "Test 10: MTAP r63";
        test_instruction(
            clk, i, ce, o, cond, op, updt, imm, val,
            10, "0101", "0110", '0', '0', "111111", "MTAP r63"
        );
        
        -- Test case 11: MTR instruction (negative condition, update flags, immediate addressing)
        -- Instruction: 0100 0111 1 1 000111 = MTRN #0x07
        report "Test 11: MTRN #0x07";
        test_instruction(
            clk, i, ce, o, cond, op, updt, imm, val,
            11, "0100", "0111", '1', '1', "000111", "MTRN #0x07"
        );
        
        -- Test case 12: LDR instruction (true condition, no update, register addressing)
        -- Instruction: 1001 1010 0 0 000011 = LDRT r3
        report "Test 12: LDRT r3";
        test_instruction(
            clk, i, ce, o, cond, op, updt, imm, val,
            12, "1001", "1010", '0', '0', "000011", "LDRT r3"
        );
        
        -- Test case 13: STR instruction (zero condition, update flags, immediate addressing)
        -- Instruction: 0010 1011 1 1 010000 = STRZ #0x10
        report "Test 13: STRZ #0x10";
        test_instruction(
            clk, i, ce, o, cond, op, updt, imm, val,
            13, "0010", "1011", '1', '1', "010000", "STRZ #0x10"
        );
        
        -- Test case 14: JMP instruction (overflow condition, no update, register addressing)
        -- Instruction: 0001 1100 0 0 111111 = JMPV r63 (PC)
        report "Test 14: JMPV r63";
        test_instruction(
            clk, i, ce, o, cond, op, updt, imm, val,
            14, "0001", "1100", '0', '0', "111111", "JMPV r63"
        );
        
        -- Test case 15: CAL instruction (always condition, update flags, immediate addressing)
        -- Instruction: 1111 1101 1 1 001000 = CALT #0x08
        report "Test 15: CALT #0x08";
        test_instruction(
            clk, i, ce, o, cond, op, updt, imm, val,
            15, "1111", "1101", '1', '1', "001000", "CALT #0x08"
        );
        
        -- Test case 16: RET instruction (carry condition, no update, register addressing)
        -- Instruction: 0011 1110 0 0 111110 = RETC r62 (RPC)
        report "Test 16: RETC r62";
        test_instruction(
            clk, i, ce, o, cond, op, updt, imm, val,
            16, "0011", "1110", '0', '0', "111110", "RETC r62"
        );
        
        -- Test case 17: Reset behavior
        report "Test 17: Reset behavior";
        rst <= '1';
        wait for clk_period*2;
        rst <= '0';
        wait for clk_period*2;
        
        assert o = x"0000" report "Test 17 failed: register not reset properly" severity error;
        assert cond = "0000" report "Test 17 failed: condition field not reset" severity error;
        assert op = "0000" report "Test 17 failed: opcode field not reset" severity error;
        assert updt = '0' report "Test 17 failed: update flag not reset" severity error;
        assert imm = '0' report "Test 17 failed: immediate flag not reset" severity error;
        assert val = "000000" report "Test 17 failed: value field not reset" severity error;
        
        -- End simulation successfully
        report "All tests completed successfully";
        wait;
    end process;
end Behavioral;