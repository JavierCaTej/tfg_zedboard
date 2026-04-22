library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_tfg_axi_lite_regs_v1_0 is
end tb_tfg_axi_lite_regs_v1_0;

architecture sim of tb_tfg_axi_lite_regs_v1_0 is
  signal s00_axi_aclk         : std_logic := '0';
  signal s00_axi_aresetn      : std_logic := '0';
  signal s00_axi_awaddr       : std_logic_vector(5 downto 0) := (others => '0');
  signal s00_axi_awprot       : std_logic_vector(2 downto 0) := (others => '0');
  signal s00_axi_awvalid      : std_logic := '0';
  signal s00_axi_awready      : std_logic;
  signal s00_axi_wdata        : std_logic_vector(31 downto 0) := (others => '0');
  signal s00_axi_wstrb        : std_logic_vector(3 downto 0) := (others => '1');
  signal s00_axi_wvalid       : std_logic := '0';
  signal s00_axi_wready       : std_logic;
  signal s00_axi_bresp        : std_logic_vector(1 downto 0);
  signal s00_axi_bvalid       : std_logic;
  signal s00_axi_bready       : std_logic := '0';
  signal s00_axi_araddr       : std_logic_vector(5 downto 0) := (others => '0');
  signal s00_axi_arprot       : std_logic_vector(2 downto 0) := (others => '0');
  signal s00_axi_arvalid      : std_logic := '0';
  signal s00_axi_arready      : std_logic;
  signal s00_axi_rdata        : std_logic_vector(31 downto 0);
  signal s00_axi_rresp        : std_logic_vector(1 downto 0);
  signal s00_axi_rvalid       : std_logic;
  signal s00_axi_rready       : std_logic := '0';
  signal reg_counter_l_before : std_logic_vector(31 downto 0) := (others => '0');
begin
  -- Reloj AXI de 100 MHz
  s00_axi_aclk <= not s00_axi_aclk after 5 ns;

  -- Instancia del periférico bajo prueba.
  dut : entity work.tfg_axi_lite_regs_v1_0
    generic map (
      C_S00_AXI_DATA_WIDTH => 32,
      C_S00_AXI_ADDR_WIDTH => 6
    )
    port map (
      s00_axi_aclk    => s00_axi_aclk,
      s00_axi_aresetn => s00_axi_aresetn,
      s00_axi_awaddr  => s00_axi_awaddr,
      s00_axi_awprot  => s00_axi_awprot,
      s00_axi_awvalid => s00_axi_awvalid,
      s00_axi_awready => s00_axi_awready,
      s00_axi_wdata   => s00_axi_wdata,
      s00_axi_wstrb   => s00_axi_wstrb,
      s00_axi_wvalid  => s00_axi_wvalid,
      s00_axi_wready  => s00_axi_wready,
      s00_axi_bresp   => s00_axi_bresp,
      s00_axi_bvalid  => s00_axi_bvalid,
      s00_axi_bready  => s00_axi_bready,
      s00_axi_araddr  => s00_axi_araddr,
      s00_axi_arprot  => s00_axi_arprot,
      s00_axi_arvalid => s00_axi_arvalid,
      s00_axi_arready => s00_axi_arready,
      s00_axi_rdata   => s00_axi_rdata,
      s00_axi_rresp   => s00_axi_rresp,
      s00_axi_rvalid  => s00_axi_rvalid,
      s00_axi_rready  => s00_axi_rready
    );

  -- Reset síncrono con el reloj AXI. Se mantiene varios ciclos para arrancar
  -- el periférico en una situación conocida.
  reset_process : process
  begin
    s00_axi_aresetn <= '0';
    wait for 50 ns;
    s00_axi_aresetn <= '1';
    wait;
  end process;

  stimulus_process : process
  begin
    -- Espera a que termine el reset y deja pasar dos flancos de reloj para
    -- estabilizar la interfaz AXI antes de empezar los accesos.
    wait until s00_axi_aresetn = '1';
    wait until rising_edge(s00_axi_aclk);
    wait until rising_edge(s00_axi_aclk);

    -- Caso 1:
    -- lectura de REG_ID tras reset para verificar que el mapeo básico del IP
    -- responde con la firma esperada.
    s00_axi_araddr  <= std_logic_vector(to_unsigned(16#00#, s00_axi_araddr'length));
    s00_axi_arvalid <= '1';
    s00_axi_rready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_arready = '1';
    s00_axi_arvalid <= '0';
    s00_axi_araddr  <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_rvalid = '1';
    assert s00_axi_rresp = "00"
      report "La respuesta AXI de lectura NO es correcta al leer REG_ID"
      severity failure;
    assert s00_axi_rdata = x"54464700"
      report "REG_ID no coincide tras el reset"
      severity failure;
    s00_axi_rready <= '0';
    report "Caso 1 OK!!" severity note;

    -- Caso 2:
    -- lectura de REG_VERSION para verificar que la versión visible por
    -- software coincide con la especificación del IP.
    s00_axi_araddr  <= std_logic_vector(to_unsigned(16#04#, s00_axi_araddr'length));
    s00_axi_arvalid <= '1';
    s00_axi_rready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_arready = '1';
    s00_axi_arvalid <= '0';
    s00_axi_araddr  <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_rvalid = '1';
    assert s00_axi_rresp = "00"
      report "La respuesta AXI de lectura NO es correcta al leer REG_VERSION"
      severity failure;
    assert s00_axi_rdata = x"00010000"
      report "REG_VERSION no coincide tras el reset"
      severity failure;
    s00_axi_rready <= '0';
    report "Caso 2 OK!!" severity note;

    -- Caso 3:
    -- lectura de REG_STATUS tras reset. Debe indicar READY = 1.
    s00_axi_araddr  <= std_logic_vector(to_unsigned(16#0C#, s00_axi_araddr'length));
    s00_axi_arvalid <= '1';
    s00_axi_rready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_arready = '1';
    s00_axi_arvalid <= '0';
    s00_axi_araddr  <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_rvalid = '1';
    assert s00_axi_rresp = "00"
      report "La respuesta AXI de lectura NO es correcta al leer REG_STATUS"
      severity failure;
    assert s00_axi_rdata = x"00000001"
      report "REG_STATUS no coincide tras el reset"
      severity failure;
    s00_axi_rready <= '0';
    report "Caso 3 OK!!" severity note;

    -- Caso 4:
    -- escritura sobre REG_WDATA con un valor de prueba.
    s00_axi_awaddr  <= std_logic_vector(to_unsigned(16#10#, s00_axi_awaddr'length));
    s00_axi_wdata   <= x"12345678";
    s00_axi_awvalid <= '1';
    s00_axi_wvalid  <= '1';
    s00_axi_bready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_awready = '1' and s00_axi_wready = '1';
    s00_axi_awvalid <= '0';
    s00_axi_wvalid  <= '0';
    s00_axi_awaddr  <= (others => '0');
    s00_axi_wdata   <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_bvalid = '1';
    assert s00_axi_bresp = "00"
      report "La respuesta AXI de escritura NO es correcta al escribir REG_WDATA"
      severity failure;
    s00_axi_bready <= '0';
    report "Caso 4 OK!!" severity note;

    -- Caso 5:
    -- lectura de REG_RDATA para verificar el eco exacto del dato anterior.
    s00_axi_araddr  <= std_logic_vector(to_unsigned(16#14#, s00_axi_araddr'length));
    s00_axi_arvalid <= '1';
    s00_axi_rready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_arready = '1';
    s00_axi_arvalid <= '0';
    s00_axi_araddr  <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_rvalid = '1';
    assert s00_axi_rresp = "00"
      report "La respuesta AXI de lectura NO es correcta al leer REG_RDATA"
      severity failure;
    assert s00_axi_rdata = x"12345678"
      report "REG_RDATA no devuelve el eco de REG_WDATA"
      severity failure;
    s00_axi_rready <= '0';
    report "Caso 5 OK!!" severity note;

    -- Caso 6:
    -- comprobación del contador de escrituras tras la primera escritura
    -- válida sobre REG_WDATA.
    s00_axi_araddr  <= std_logic_vector(to_unsigned(16#18#, s00_axi_araddr'length));
    s00_axi_arvalid <= '1';
    s00_axi_rready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_arready = '1';
    s00_axi_arvalid <= '0';
    s00_axi_araddr  <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_rvalid = '1';
    assert s00_axi_rresp = "00"
      report "La respuesta AXI de lectura NO es correcta al leer REG_WRITE_COUNT"
      severity failure;
    assert s00_axi_rdata = x"00000001"
      report "REG_WRITE_COUNT no coincide tras la primera escritura"
      severity failure;
    s00_axi_rready <= '0';
    report "Caso 6 OK!!" severity note;

    -- Caso 7:
    -- comprobación del contador de lecturas tras la primera lectura válida
    -- de REG_RDATA.
    s00_axi_araddr  <= std_logic_vector(to_unsigned(16#1C#, s00_axi_araddr'length));
    s00_axi_arvalid <= '1';
    s00_axi_rready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_arready = '1';
    s00_axi_arvalid <= '0';
    s00_axi_araddr  <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_rvalid = '1';
    assert s00_axi_rresp = "00"
      report "La respuesta AXI de lectura NO es correcta al leer REG_READ_COUNT"
      severity failure;
    assert s00_axi_rdata = x"00000001"
      report "REG_READ_COUNT no coincide tras la primera lectura de REG_RDATA"
      severity failure;
    s00_axi_rready <= '0';
    report "Caso 7 OK!!" severity note;

    -- Caso 8:
    -- segunda escritura sobre REG_WDATA para comprobar accesos repetidos.
    s00_axi_awaddr  <= std_logic_vector(to_unsigned(16#10#, s00_axi_awaddr'length));
    s00_axi_wdata   <= x"BEBECAFE";
    s00_axi_awvalid <= '1';
    s00_axi_wvalid  <= '1';
    s00_axi_bready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_awready = '1' and s00_axi_wready = '1';
    s00_axi_awvalid <= '0';
    s00_axi_wvalid  <= '0';
    s00_axi_awaddr  <= (others => '0');
    s00_axi_wdata   <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_bvalid = '1';
    assert s00_axi_bresp = "00"
      report "La respuesta AXI de escritura NO es correcta en la segunda escritura de REG_WDATA"
      severity failure;
    s00_axi_bready <= '0';
    report "Caso 8 OK!!" severity note;

    -- Caso 9:
    -- segunda lectura de REG_RDATA. Debe reflejar el último dato escrito.
    s00_axi_araddr  <= std_logic_vector(to_unsigned(16#14#, s00_axi_araddr'length));
    s00_axi_arvalid <= '1';
    s00_axi_rready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_arready = '1';
    s00_axi_arvalid <= '0';
    s00_axi_araddr  <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_rvalid = '1';
    assert s00_axi_rresp = "00"
      report "La respuesta AXI de lectura NO es correcta en la segunda lectura de REG_RDATA"
      severity failure;
    assert s00_axi_rdata = x"BEBECAFE"
      report "REG_RDATA no coincide tras los accesos repetidos"
      severity failure;
    s00_axi_rready <= '0';
    report "Caso 9 OK!!" severity note;

    -- Caso 10:
    -- el contador de escrituras debe reflejar dos accesos válidos a REG_WDATA.
    s00_axi_araddr  <= std_logic_vector(to_unsigned(16#18#, s00_axi_araddr'length));
    s00_axi_arvalid <= '1';
    s00_axi_rready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_arready = '1';
    s00_axi_arvalid <= '0';
    s00_axi_araddr  <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_rvalid = '1';
    assert s00_axi_rresp = "00"
      report "La respuesta AXI de lectura NO es correcta al releer REG_WRITE_COUNT"
      severity failure;
    assert s00_axi_rdata = x"00000002"
      report "REG_WRITE_COUNT no coincide tras la segunda escritura"
      severity failure;
    s00_axi_rready <= '0';
    report "Caso 10 OK!!" severity note;

    -- Caso 11:
    -- el contador de lecturas debe reflejar dos lecturas válidas de REG_RDATA.
    s00_axi_araddr  <= std_logic_vector(to_unsigned(16#1C#, s00_axi_araddr'length));
    s00_axi_arvalid <= '1';
    s00_axi_rready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_arready = '1';
    s00_axi_arvalid <= '0';
    s00_axi_araddr  <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_rvalid = '1';
    assert s00_axi_rresp = "00"
      report "La respuesta AXI de lectura NO es correcta al releer REG_READ_COUNT"
      severity failure;
    assert s00_axi_rdata = x"00000002"
      report "REG_READ_COUNT no coincide tras la segunda lectura"
      severity failure;
    s00_axi_rready <= '0';
    report "Caso 11 OK!!" severity note;

    -- Caso 12:
    -- lectura de un offset no implementado. Debe devolver cero.
    s00_axi_araddr  <= std_logic_vector(to_unsigned(16#28#, s00_axi_araddr'length));
    s00_axi_arvalid <= '1';
    s00_axi_rready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_arready = '1';
    s00_axi_arvalid <= '0';
    s00_axi_araddr  <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_rvalid = '1';
    assert s00_axi_rresp = "00"
      report "La respuesta AXI de lectura NO es correcta al leer un offset no implementado"
      severity failure;
    assert s00_axi_rdata = x"00000000"
      report "La lectura de un offset no implementado no devolvio cero"
      severity failure;
    s00_axi_rready <= '0';
    report "Caso 12 OK!!" severity note;

    -- Caso 13:
    -- captura del contador libre bajo para verificar que avanza con el reloj.
    s00_axi_araddr  <= std_logic_vector(to_unsigned(16#20#, s00_axi_araddr'length));
    s00_axi_arvalid <= '1';
    s00_axi_rready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_arready = '1';
    s00_axi_arvalid      <= '0';
    s00_axi_araddr       <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_rvalid = '1';
    assert s00_axi_rresp = "00"
      report "La respuesta AXI de lectura NO es correcta al leer REG_COUNTER_L"
      severity failure;
    reg_counter_l_before <= s00_axi_rdata;
    s00_axi_rready <= '0';
    report "Caso 13 OK!!" severity note;

    wait for 30 ns;

    -- Caso 14:
    -- segunda lectura del contador libre bajo. Debe ser mayor que en la
    -- lectura anterior.
    s00_axi_araddr  <= std_logic_vector(to_unsigned(16#20#, s00_axi_araddr'length));
    s00_axi_arvalid <= '1';
    s00_axi_rready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_arready = '1';
    s00_axi_arvalid <= '0';
    s00_axi_araddr  <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_rvalid = '1';
    assert s00_axi_rresp = "00"
      report "La respuesta AXI de lectura NO es correcta al releer REG_COUNTER_L"
      severity failure;
    assert unsigned(s00_axi_rdata) > unsigned(reg_counter_l_before)
      report "REG_COUNTER_L no avanzo entre dos lecturas"
      severity failure;
    s00_axi_rready <= '0';
    report "Caso 14 OK!!" severity note;

    -- Caso 15:
    -- lectura del contador libre alto. En una simulación corta debe seguir a
    -- cero, lo que además sirve para comprobar que el registro responde.
    s00_axi_araddr  <= std_logic_vector(to_unsigned(16#24#, s00_axi_araddr'length));
    s00_axi_arvalid <= '1';
    s00_axi_rready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_arready = '1';
    s00_axi_arvalid <= '0';
    s00_axi_araddr  <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_rvalid = '1';
    assert s00_axi_rresp = "00"
      report "La respuesta AXI de lectura NO es correcta al leer REG_COUNTER_H"
      severity failure;
    assert s00_axi_rdata = x"00000000"
      report "REG_COUNTER_H deberia permanecer a cero en una simulacion corta"
      severity failure;
    s00_axi_rready <= '0';
    report "Caso 15 OK!!" severity note;

    -- Caso 16:
    -- escritura en REG_CONTROL con CLEAR_COUNTERS = 1 para borrar contadores.
    s00_axi_awaddr  <= std_logic_vector(to_unsigned(16#08#, s00_axi_awaddr'length));
    s00_axi_wdata   <= x"00000001";
    s00_axi_awvalid <= '1';
    s00_axi_wvalid  <= '1';
    s00_axi_bready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_awready = '1' and s00_axi_wready = '1';
    s00_axi_awvalid <= '0';
    s00_axi_wvalid  <= '0';
    s00_axi_awaddr  <= (others => '0');
    s00_axi_wdata   <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_bvalid = '1';
    assert s00_axi_bresp = "00"
      report "La respuesta AXI de escritura NO es correcta al escribir REG_CONTROL"
      severity failure;
    s00_axi_bready <= '0';
    report "Caso 16 OK!!" severity note;

    -- Caso 17:
    -- comprobación de que REG_WRITE_COUNT ha sido borrado.
    s00_axi_araddr  <= std_logic_vector(to_unsigned(16#18#, s00_axi_araddr'length));
    s00_axi_arvalid <= '1';
    s00_axi_rready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_arready = '1';
    s00_axi_arvalid <= '0';
    s00_axi_araddr  <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_rvalid = '1';
    assert s00_axi_rresp = "00"
      report "La respuesta AXI de lectura NO es correcta al comprobar REG_WRITE_COUNT tras el borrado"
      severity failure;
    assert s00_axi_rdata = x"00000000"
      report "REG_WRITE_COUNT no fue borrado por REG_CONTROL[0]"
      severity failure;
    s00_axi_rready <= '0';
    report "Caso 17 OK!!" severity note;

    -- Caso 18:
    -- comprobación de que REG_READ_COUNT también ha sido borrado.
    s00_axi_araddr  <= std_logic_vector(to_unsigned(16#1C#, s00_axi_araddr'length));
    s00_axi_arvalid <= '1';
    s00_axi_rready  <= '1';
    wait until rising_edge(s00_axi_aclk) and s00_axi_arready = '1';
    s00_axi_arvalid <= '0';
    s00_axi_araddr  <= (others => '0');
    wait until rising_edge(s00_axi_aclk) and s00_axi_rvalid = '1';
    assert s00_axi_rresp = "00"
      report "La respuesta AXI de lectura NO es correcta al comprobar REG_READ_COUNT tras el borrado"
      severity failure;
    assert s00_axi_rdata = x"00000000"
      report "REG_READ_COUNT no fue borrado por REG_CONTROL[0]"
      severity failure;
    s00_axi_rready <= '0';
    report "Caso 18 OK!!" severity note;

    report "Las comprobaciones del testbench de T3.23 han finalizado correctamente" severity note;
    wait;
  end process;
end sim;
