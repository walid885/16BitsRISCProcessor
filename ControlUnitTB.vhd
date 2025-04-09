library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ControlUnitTB is
end ControlUnitTB;

architecture Behavioral of ControlUnitTB is
    -- Component Declaration
    component ControlUnit
        Port ( 
            clk         : in  STD_LOGIC;
            rst         : in  STD_LOGIC;
            opcode      : in  STD_LOGIC_VECTOR(3 downto 0);
            cond        : in  STD_LOGIC_VECTOR(3 downto 0);
            updt        : in  STD_LOGIC;
            imm         : in  STD_LOGIC;
            val         : in  STD_LOGIC_VECTOR(5 downto 0);
            status      : in  STD_LOGIC_VECTOR(3 downto 0);
            instr_ce    : out STD_LOGIC;
            status_ce   : out STD_LOGIC;
            acc_ce      : out STD_LOGIC;
            pc_ce       : out STD_LOGIC;
            rpc_ce      : out STD_LOGIC;
            rx_ce       : out STD_LOGIC;
            ram_we      : out STD_LOGIC;
            sel_ram_addr: out STD_LOGIC;
            sel_op1     : out STD_LOGIC;
            sel_rf_din  : out STD_LOGIC;
            alu_op      : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;
    
    -- Test bench signals
    signal clk          : STD_LOGIC := '0';
    signal rst          : STD_LOGIC := '1';
    signal opcode       : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal cond         : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal updt         : STD_LOGIC := '0';
    signal imm          : STD_LOGIC := '0';
    signal val          : STD_LOGIC_VECTOR(5 downto 0) := (others => '0');
    signal status       : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal instr_ce     : STD_LOGIC;
    signal status_ce    : STD_LOGIC;
    signal acc_ce       : STD_LOGIC;
    signal pc_ce        : STD_LOGIC;
    signal rpc_ce       : STD_LOGIC;
    signal rx_ce        : STD_LOGIC;
    signal ram_we       : STD_LOGIC;
    signal sel_ram_addr : STD_LOGIC;
    signal sel_op1      : STD_LOGIC;
    signal sel_rf_din   : STD_LOGIC;
    signal alu_op       : STD_LOGIC_VECTOR(3 downto 0);
    
    -- Clock period definition
    constant clk_period : time := 10 ns;
    
    -- Helper signals to track state
    signal state_count : integer := 0;
    
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: ControlUnit
        port map (
            clk         => clk,
            rst         => rst,
            opcode      => opcode,
            cond        => cond,
            updt        => updt,
            imm         => imm,
            val         => val,
            status      => status,
            instr_ce    => instr_ce,
            status_ce   => status_ce,
            acc_ce      => acc_ce,
            pc_ce       => pc_ce,
            rpc_ce      => rpc_ce,
            rx_ce       => rx_ce,
            ram_we      => ram_we,
            sel_ram_addr=> sel_ram_addr,
            sel_op1     => sel_op1,
            sel_rf_din  => sel_rf_din,
            alu_op      => alu_op
        );
        
    -- Clock process
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
    
    -- State counter (to keep track of the FSM state)
    state_counter: process(clk, rst)
    begin
        if rst = '1' then
            state_count <= 0;
        elsif rising_edge(clk) then
            if state_count = 4 then
                state_count <= 0;
            else
                state_count <= state_count + 1;
            end if;
        end if;
    end process;
    
    -- Stimulus process
    stim_proc: process
    begin
        -- Hold reset state
        rst <= '1';
        wait for clk_period*2;
        rst <= '0';
        
        -- Test Case 1: ADD instruction (always condition, update flags)
        wait until state_count = 0;  -- Start at fetch1
        opcode <= "0000";  -- ADD
        cond <= "0000";    -- Always
        updt <= '1';       -- Update flags
        imm <= '0';        -- Register addressing
        val <= "000001";   -- Register R1
        status <= "0000";  -- All flags clear
        
        -- Wait for full instruction cycle
        wait for clk_period*5;
        
        -- Test Case 2: SUB instruction with zero flag set
        opcode <= "0001";  -- SUB
        cond <= "0001";    -- Z=1 (Equal)
        updt <= '1';       -- Update flags
        imm <= '1';        -- Immediate addressing
        val <= "001010";   -- Value 10
        status <= "1000";  -- Z=1, others=0
        
        -- Wait for full instruction cycle
        wait for clk_period*5;
        
        -- Test Case 3: JMP instruction with condition not met
        opcode <= "1100";  -- JMP
        cond <= "0101";    -- N=1 (Negative)
        updt <= '0';       -- Don't update flags
        imm <= '1';        -- Immediate addressing
        val <= "100000";   -- Address value
        status <= "0000";  -- All flags clear (N=0, so condition not met)
        
        -- Wait for full instruction cycle
        wait for clk_period*5;
        
        -- Test Case 4: CAL instruction
        opcode <= "1110";  -- CAL
        cond <= "0000";    -- Always
        updt <= '0';       -- Don't update flags
        imm <= '1';        -- Immediate addressing
        val <= "000100";   -- Function address
        status <= "0000";  -- All flags clear
        
        -- Wait for full instruction cycle
        wait for clk_period*5;
        
        -- Test Case 5: LDA instruction (load from memory)
        opcode <= "1010";  -- LDA
        cond <= "0000";    -- Always
        updt <= '1';       -- Update flags
        imm <= '0';        -- Not used for LDA
        val <= "000000";   -- Not used for LDA
        status <= "0000";  -- All flags clear
        
        -- Wait for full instruction cycle
        wait for clk_period*5;
        
        -- End simulation
        wait;
    end process;

end Behavioral;
