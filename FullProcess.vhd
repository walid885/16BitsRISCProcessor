library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Processor is
    Port ( 
        clk     : in  STD_LOGIC;
        rst     : in  STD_LOGIC;
        -- Optional external interface signals
        debug_pc    : out STD_LOGIC_VECTOR(15 downto 0);
        debug_acc   : out STD_LOGIC_VECTOR(15 downto 0);
        debug_instr : out STD_LOGIC_VECTOR(15 downto 0);
        debug_state : out STD_LOGIC_VECTOR(2 downto 0)
    );
end Processor;

architecture Structural of Processor is
    -- Component declarations
    component InstructReg is
        Port ( 
            clk    : in  STD_LOGIC;
            rst    : in  STD_LOGIC;
            ce     : in  STD_LOGIC;
            i      : in  STD_LOGIC_VECTOR(15 downto 0);
            opcode : out STD_LOGIC_VECTOR(3 downto 0);
            cond   : out STD_LOGIC_VECTOR(3 downto 0);
            updt   : out STD_LOGIC;
            imm    : out STD_LOGIC;
            val    : out STD_LOGIC_VECTOR(5 downto 0)
        );
    end component;
    
    component StatusReg is
        Port ( 
            clk  : in  STD_LOGIC;
            rst  : in  STD_LOGIC;
            ce   : in  STD_LOGIC;
            i    : in  STD_LOGIC_VECTOR(3 downto 0);
            o    : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;
    
    component RegisterBank is
        Port ( 
            clk     : in  STD_LOGIC;
            rst     : in  STD_LOGIC;
            rx_num  : in  STD_LOGIC_VECTOR(5 downto 0);
            rx_ce   : in  STD_LOGIC;
            acc_ce  : in  STD_LOGIC;
            pc_ce   : in  STD_LOGIC;
            rpc_ce  : in  STD_LOGIC;
            din     : in  STD_LOGIC_VECTOR(15 downto 0);
            rx_out  : out STD_LOGIC_VECTOR(15 downto 0);
            acc_out : out STD_LOGIC_VECTOR(15 downto 0);
            pc_out  : out STD_LOGIC_VECTOR(15 downto 0);
            rpc_out : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;
    
    component ALU is
        Port ( 
            op1    : in  STD_LOGIC_VECTOR(15 downto 0);
            op2    : in  STD_LOGIC_VECTOR(15 downto 0);
            opcode : in  STD_LOGIC_VECTOR(3 downto 0);
            result : out STD_LOGIC_VECTOR(15 downto 0);
            status : out STD_LOGIC_VECTOR(3 downto 0)  -- Z, N, C, V
        );
    end component;
    
    component ControlUnit is
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
    
    component RAM is
        Port ( 
            clk  : in  STD_LOGIC;
            rst  : in  STD_LOGIC;
            addr : in  STD_LOGIC_VECTOR(15 downto 0);
            din  : in  STD_LOGIC_VECTOR(15 downto 0);
            we   : in  STD_LOGIC;
            dout : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;
    
    -- State encoding for debug output
    constant STATE_FETCH1 : STD_LOGIC_VECTOR(2 downto 0) := "000";
    constant STATE_FETCH2 : STD_LOGIC_VECTOR(2 downto 0) := "001";
    constant STATE_DECODE : STD_LOGIC_VECTOR(2 downto 0) := "010";
    constant STATE_EXEC   : STD_LOGIC_VECTOR(2 downto 0) := "011";
    constant STATE_STORE  : STD_LOGIC_VECTOR(2 downto 0) := "100";
    
    -- Instruction register signals
    signal instr_i    : STD_LOGIC_VECTOR(15 downto 0);
    signal instr_ce   : STD_LOGIC;
    signal opcode     : STD_LOGIC_VECTOR(3 downto 0);
    signal cond       : STD_LOGIC_VECTOR(3 downto 0);
    signal updt       : STD_LOGIC;
    signal imm        : STD_LOGIC;
    signal val        : STD_LOGIC_VECTOR(5 downto 0);
    
    -- Status register signals
    signal status_i   : STD_LOGIC_VECTOR(3 downto 0);
    signal status_ce  : STD_LOGIC;
    signal status_o   : STD_LOGIC_VECTOR(3 downto 0);
    
    -- Register bank signals
    signal rx_num     : STD_LOGIC_VECTOR(5 downto 0);
    signal rx_ce      : STD_LOGIC;
    signal acc_ce     : STD_LOGIC;
    signal pc_ce      : STD_LOGIC;
    signal rpc_ce     : STD_LOGIC;
    signal reg_din    : STD_LOGIC_VECTOR(15 downto 0);
    signal rx_out     : STD_LOGIC_VECTOR(15 downto 0);
    signal acc_out    : STD_LOGIC_VECTOR(15 downto 0);
    signal pc_out     : STD_LOGIC_VECTOR(15 downto 0);
    signal rpc_out    : STD_LOGIC_VECTOR(15 downto 0);
    
    -- ALU signals
    signal alu_op1    : STD_LOGIC_VECTOR(15 downto 0);
    signal alu_op2    : STD_LOGIC_VECTOR(15 downto 0);
    signal alu_opcode : STD_LOGIC_VECTOR(3 downto 0);
    signal alu_result : STD_LOGIC_VECTOR(15 downto 0);
    signal alu_status : STD_LOGIC_VECTOR(3 downto 0);
	signal alu_op     : STD_LOGIC_VECTOR(3 downto 0);
    
    -- RAM signals
    signal ram_addr   : STD_LOGIC_VECTOR(15 downto 0);
    signal ram_din    : STD_LOGIC_VECTOR(15 downto 0);
    signal ram_we     : STD_LOGIC;
    signal ram_dout   : STD_LOGIC_VECTOR(15 downto 0);
    
    -- Control signals
    signal sel_ram_addr : STD_LOGIC;
    signal sel_op1      : STD_LOGIC;
    signal sel_rf_din   : STD_LOGIC;
    
    -- Intermediate signals for calculations
    signal immediate   : STD_LOGIC_VECTOR(15 downto 0);
    signal pc_plus_one : STD_LOGIC_VECTOR(15 downto 0);
    

    
begin
    -- Connect debug outputs
    debug_pc    <= pc_out;
    debug_acc   <= acc_out;
    debug_instr <= instr_i;
    
    -- Create immediate value by sign-extending val
    immediate <= (15 downto 6 => val(5)) & val when imm = '1' else 
                 (15 downto 0 => '0');
    
    -- PC+1 calculation
    pc_plus_one <= std_logic_vector(unsigned(pc_out) + 1);
    
    -- Multiplexers
    -- RAM address mux
    ram_addr <= acc_out when sel_ram_addr = '1' else pc_out;
    
    -- ALU op1 mux
    alu_op1 <= pc_out when sel_op1 = '1' else acc_out;
    
    -- ALU op2 mux
    alu_op2 <= immediate when imm = '1' else rx_out;
    
    -- Register file data input mux
    reg_din <= ram_dout when sel_rf_din = '1' else alu_result;
    
    -- Register number selection
    rx_num <= val;
    
    -- Connect RAM data input
    ram_din <= acc_out;
    
    -- Pass ALU opcode from control unit

    alu_opcode <= alu_op;
    
    -- Connect status input
    status_i <= alu_status;
    
    -- Component instantiations
    instruction_register: InstructReg
        port map (
            clk    => clk,
            rst    => rst,
            ce     => instr_ce,
            i      => ram_dout,   -- Instruction comes from memory
            opcode => opcode,
            cond   => cond,
            updt   => updt,
            imm    => imm,
            val    => val
        );
    
    status_register: StatusReg
        port map (
            clk    => clk,
            rst    => rst,
            ce     => status_ce,
            i      => status_i,
            o      => status_o
        );
    
    register_bank: RegisterBank
        port map (
            clk     => clk,
            rst     => rst,
            rx_num  => rx_num,
            rx_ce   => rx_ce,
            acc_ce  => acc_ce,
            pc_ce   => pc_ce,
            rpc_ce  => rpc_ce,
            din     => reg_din,
            rx_out  => rx_out,
            acc_out => acc_out,
            pc_out  => pc_out,
            rpc_out => rpc_out
        );
    
    arithmetic_logic_unit: ALU
        port map (
            op1    => alu_op1,
            op2    => alu_op2,
            opcode => alu_opcode,
            result => alu_result,
            status => alu_status
        );
    
    control_unit: ControlUnit
        port map (
            clk         => clk,
            rst         => rst,
            opcode      => opcode,
            cond        => cond,
            updt        => updt,
            imm         => imm,
            val         => val,
            status      => status_o,
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
    
    memory: RAM
        port map (
            clk  => clk,
            rst  => rst,
            addr => ram_addr,
            din  => ram_din,
            we   => ram_we,
            dout => ram_dout
        );

end Structural;