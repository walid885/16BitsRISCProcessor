library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity register_bank_tb is
end register_bank_tb;

architecture Behavioral of register_bank_tb is
    -- Component declaration
    component register_bank
        Port (
            clk       : in  STD_LOGIC;
            rst       : in  STD_LOGIC;
            din       : in  STD_LOGIC_VECTOR(15 downto 0);
            rx_num    : in  STD_LOGIC_VECTOR(5 downto 0);
            rx_out    : out STD_LOGIC_VECTOR(15 downto 0);
            acc_out   : out STD_LOGIC_VECTOR(15 downto 0);
            pc_out    : out STD_LOGIC_VECTOR(15 downto 0);
            acc_ce    : in  STD_LOGIC;
            pc_ce     : in  STD_LOGIC;
            rpc_ce    : in  STD_LOGIC;
            rx_ce     : in  STD_LOGIC;
            rx_wr_num : in  STD_LOGIC_VECTOR(5 downto 0)
        );
    end component;
    
    -- Inputs
    signal clk       : STD_LOGIC := '0';
    signal rst       : STD_LOGIC := '0';
    signal din       : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal rx_num    : STD_LOGIC_VECTOR(5 downto 0) := (others => '0');
    signal acc_ce    : STD_LOGIC := '0';
    signal pc_ce     : STD_LOGIC := '0';
    signal rpc_ce    : STD_LOGIC := '0';
    signal rx_ce     : STD_LOGIC := '0';
    signal rx_wr_num : STD_LOGIC_VECTOR(5 downto 0) := (others => '0');
    
    -- Outputs
    signal rx_out    : STD_LOGIC_VECTOR(15 downto 0);
    signal acc_out   : STD_LOGIC_VECTOR(15 downto 0);
    signal pc_out    : STD_LOGIC_VECTOR(15 downto 0);
    
    -- Clock period definition
    constant clk_period : time := 10 ns;
    
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: register_bank port map (
        clk       => clk,
        rst       => rst,
        din       => din,
        rx_num    => rx_num,
        rx_out    => rx_out,
        acc_out   => acc_out,
        pc_out    => pc_out,
        acc_ce    => acc_ce,
        pc_ce     => pc_ce,
        rpc_ce    => rpc_ce,
        rx_ce     => rx_ce,
        rx_wr_num => rx_wr_num
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
        
        -- Test 1: Write to accumulator (R0)
        din <= X"ABCD";
        acc_ce <= '1';
        wait for clk_period;
        acc_ce <= '0';
        wait for clk_period;
        assert acc_out = X"ABCD" report "Test 1 failed: acc_out" severity error;
        
        -- Test 2: Write to PC (R63)
        din <= X"1234";
        pc_ce <= '1';
        wait for clk_period;
        pc_ce <= '0';
        wait for clk_period;
        assert pc_out = X"1234" report "Test 2 failed: pc_out" severity error;
        
        -- Test 3: Write to RPC (R62)
        din <= X"5678";
        rpc_ce <= '1';
        wait for clk_period;
        rpc_ce <= '0';
        wait for clk_period;
        
        -- Read RPC via rx_out
        rx_num <= "111110";  -- R62
        wait for 1 ns;  -- Small delay for combinational logic
        assert rx_out = X"5678" report "Test 3 failed: rx_out for RPC" severity error;
        
        -- Test 4: Write to arbitrary register R10
        din <= X"BEEF";
        rx_wr_num <= "001010";  -- R10
        rx_ce <= '1';
        wait for clk_period;
        rx_ce <= '0';
        wait for clk_period;
        
        -- Read R10 via rx_out
        rx_num <= "001010";  -- R10
        wait for 1 ns;  -- Small delay for combinational logic
        assert rx_out = X"BEEF" report "Test 4 failed: rx_out for R10" severity error;
        
        -- Test 5: Check that accumulator read through both acc_out and rx_out match
        rx_num <= "000000";  -- R0 (Accumulator)
        wait for 1 ns;  -- Small delay for combinational logic
        assert rx_out = acc_out report "Test 5 failed: acc_out vs rx_out for R0" severity error;
        
        -- Test 6: Reset
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;
        assert acc_out = X"0000" report "Test 6 failed: acc_out after reset" severity error;
        assert pc_out = X"0000" report "Test 6 failed: pc_out after reset" severity error;
        
        -- End simulation
        wait;
    end process;
end Behavioral;
