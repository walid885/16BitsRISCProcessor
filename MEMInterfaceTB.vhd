
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAMTB is
end RAMTB;

architecture Behavioral of RAMTB is
    -- Component declaration
    component RAM
        Port ( 
            clk      : in  STD_LOGIC;
            rst      : in  STD_LOGIC;
            addr     : in  STD_LOGIC_VECTOR(15 downto 0);
            din      : in  STD_LOGIC_VECTOR(15 downto 0);
            we       : in  STD_LOGIC;
            dout     : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;
    
    -- Test bench signals
    signal clk      : STD_LOGIC := '0';
    signal rst      : STD_LOGIC := '1';
    signal addr     : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal din      : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal we       : STD_LOGIC := '0';
    signal dout     : STD_LOGIC_VECTOR(15 downto 0);
    
    -- Clock period definition
    constant clk_period : time := 10 ns;
    
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: RAM
        port map (
            clk  => clk,
            rst  => rst,
            addr => addr,
            din  => din,
            we   => we,
            dout => dout
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
        -- Hold reset state
        rst <= '1';
        wait for clk_period*2;
        rst <= '0';
        
        -- Read pre-initialized values at addresses 0-3
        addr <= X"0000";  -- Read from address 0
        we <= '0';        -- Read operation
        wait for clk_period;
        
        addr <= X"0001";  -- Read from address 1
        wait for clk_period;
        
        addr <= X"0002";  -- Read from address 2
        wait for clk_period;
        
        addr <= X"0003";  -- Read from address 3
        wait for clk_period;
        
        -- Write new value to address 10
        addr <= X"000A";  -- Address 10
        din <= X"ABCD";   -- Data to write
        we <= '1';        -- Write operation
        wait for clk_period;
        we <= '0';        -- Disable write
        
        -- Read back the written value
        -- Should read X"ABCD"
        wait for clk_period;
        
        -- Write to another address
        addr <= X"0020";  -- Address 32
        din <= X"1234";   -- Data to write
        we <= '1';        -- Write operation
        wait for clk_period;
        we <= '0';        -- Disable write
        
        -- Read back the written value
        -- Should read X"1234"
        wait for clk_period;
        
        -- Go back to address 10 to verify it still holds X"ABCD"
        addr <= X"000A";
        wait for clk_period;
        
        -- End simulation
        wait;
    end process;

end Behavioral;