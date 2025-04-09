library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity register_bank is
    Port (
        clk      : in  STD_LOGIC;                       -- Clock signal
        rst      : in  STD_LOGIC;                       -- Reset signal
        
        -- Data input for writing to registers
        din      : in  STD_LOGIC_VECTOR(15 downto 0);   -- Data input
        
        -- Register access for reading any register
        rx_num   : in  STD_LOGIC_VECTOR(5 downto 0);    -- Register number for reading
        rx_out   : out STD_LOGIC_VECTOR(15 downto 0);   -- Output of selected register
        
        -- Direct access to special registers (asynchronous read)
        acc_out  : out STD_LOGIC_VECTOR(15 downto 0);   -- Accumulator output (R0)
        pc_out   : out STD_LOGIC_VECTOR(15 downto 0);   -- Program Counter output (R63)
        
        -- Write control signals
        acc_ce   : in  STD_LOGIC;                       -- Write enable for Accumulator (R0)
        pc_ce    : in  STD_LOGIC;                       -- Write enable for PC (R63)
        rpc_ce   : in  STD_LOGIC;                       -- Write enable for RPC (R62)
        rx_ce    : in  STD_LOGIC;                       -- Write enable for register rx_num
        rx_wr_num: in  STD_LOGIC_VECTOR(5 downto 0)     -- Register number for writing
    );
end register_bank;

architecture Behavioral of register_bank is
    -- Register array type
    type reg_array is array(0 to 63) of STD_LOGIC_VECTOR(15 downto 0);
    
    -- Internal signals
    signal regs : reg_array := (others => (others => '0'));
begin
    -- Register write process
    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset all registers
            for i in 0 to 63 loop
                if i = 63 then
                    -- Reset PC (R63) to 0
                    regs(i) <= (others => '0');
                else
                    -- Reset other registers to 0
                    regs(i) <= (others => '0');
                end if;
            end loop;
        elsif rising_edge(clk) then
            -- Write to accumulator (R0)
            if acc_ce = '1' then
                regs(0) <= din;
            end if;
            
            -- Write to PC (R63)
            if pc_ce = '1' then
                regs(63) <= din;
            end if;
            
            -- Write to RPC (R62)
            if rpc_ce = '1' then
                regs(62) <= din;
            end if;
            
            -- Write to register indexed by rx_wr_num
            if rx_ce = '1' then
                regs(to_integer(unsigned(rx_wr_num))) <= din;
            end if;
        end if;
    end process;
    
    -- Register read (asynchronous)
    rx_out  <= regs(to_integer(unsigned(rx_num)));
    acc_out <= regs(0);   -- Accumulator is R0
    pc_out  <= regs(63);  -- PC is R63
end Behavioral;
