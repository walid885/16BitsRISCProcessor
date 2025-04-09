
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

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
        -- Reset
        rst <= '1';
        wait for clk_period*2;
        rst <= '0';
        wait for clk_period;
        
        -- Test 1: Load ADD instruction (True condition, update flags, register addressing)
        -- Instruction: 1001 1000 1 0 000001 = 0x9841
        -- ADDT r1
        i <= "1001100010000001";  -- cond=1001(T), op=1000(ADD), updt=1, imm=0, val=000001(r1)
        ce <= '1';
        wait for clk_period;
        ce <= '0';
        wait for clk_period;
        assert o = "1001100010000001" report "Test 1 failed: full instruction" severity error;
        assert cond = "1001" report "Test 1 failed: condition field" severity error;
        assert op = "1000" report "Test 1 failed: opcode field" severity error;
        assert updt = '1' report "Test 1 failed: update flag" severity error;
        assert imm = '0' report "Test 1 failed: immediate flag" severity error;
        assert val = "000001" report "Test 1 failed: value field" severity error;
        
        -- Test 2: Load SUB instruction (Zero condition, no update, immediate addressing)
        -- Instruction: 0010 1001 0 1 010101 = 0x2955
        -- SUBZ #0x15
        i <= "0010100101010101";  -- cond=0010(Z), op=1001(SUB), updt=0, imm=1, val=010101(0x15)
        ce <= '1';
        wait for clk_period;
        ce <= '0';
        wait for clk_period;
        assert o = "0010100101010101" report "Test 2 failed: full instruction" severity error;
        assert cond = "0010" report "Test 2 failed: condition field" severity error;
        assert op = "1001" report "Test 2 failed: opcode field" severity error;
        assert updt = '0' report "Test 2 failed: update flag" severity error;
        assert imm = '1' report "Test 2 failed: immediate flag" severity error;
        assert val = "010101" report "Test 2 failed: value field" severity error;
        
        -- Test 3: Write disabled (CE=0)
        i <= "0000000000000000";
        wait for clk_period;
        assert o = "0010100101010101" report "Test 3 failed" severity error;
        
        -- Test 4: Reset
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;
        assert o = "0000000000000000" report "Test 4 failed" severity error;
        
        -- End simulation
        wait;
    end process;
end Behavioral;