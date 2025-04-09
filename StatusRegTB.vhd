
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity status_register_tb is
end status_register_tb;

architecture Behavioral of status_register_tb is
    -- Component declaration
    component status_register
        Port ( 
            clk     : in  STD_LOGIC;
            rst     : in  STD_LOGIC;
            ce      : in  STD_LOGIC;
            input       : in  STD_LOGIC_VECTOR(3 downto 0);
            output       : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;
    
    -- Inputs
    signal clk  : STD_LOGIC := '0';
    signal rst  : STD_LOGIC := '0';
    signal ce   : STD_LOGIC := '0';
    signal input    : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    
    -- Outputs
    signal output    : STD_LOGIC_VECTOR(3 downto 0);
    
    -- Clock period definition
    constant clk_period : time := 10 ns;
    
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: status_register port map (
        clk => clk,
        rst => rst,
        ce  => ce,
        input   => input,
        output   => output
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
        
        -- Test 1: Write with CE enabled
        input <= "1010";  -- Z=1, N=0, C=1, V=0
        ce <= '1';
        wait for clk_period;
        ce <= '0';
        wait for clk_period;
        assert output = "1010" report "Test 1 failed" severity error;
        
        -- Test 2: Write disabled (CE=0)
        input <= "0101";  -- Z=0, N=1, C=0, V=1
        wait for clk_period;
        assert output = "1010" report "Test 2 failed" severity error;
        
        -- Test 3: Another write with CE enabled
        input <= "1111";  -- Z=1, N=1, C=1, V=1
        ce <= '1';
        wait for clk_period;
        ce <= '0';
        wait for clk_period;
        assert output = "1111" report "Test 3 failed" severity error;
        
        -- Test 4: Reset
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;
        assert output = "0000" report "Test 4 failed" severity error;
        
        -- End simulation
        wait;
    end process;
end Behavioral;