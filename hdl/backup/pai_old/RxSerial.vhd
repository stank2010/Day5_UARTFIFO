library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

Entity RxSerial Is
Port(
	RstB		: in	std_logic;
	Clk			: in	std_logic;
	
	SerDataIn	: in	std_logic;
	
	RxFfFull	: in	std_logic;
	RxFfWrData	: out	std_logic_vector(7 downto 0);
	RxFfWrEn	: out	std_logic

);

End Entity RxSerial;

Architecture rtl Of RxSerial Is

----------------------------------------------------------------------------------
-- Constant declaration
	constant cBuadrate :integer := 868;
----------------------------------------------------------------------------------
	
----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	type	StateType is 
					(
						stwait,
						stStart,
						strecive,
						stsend
					);
	signal	rSerDataIn		: std_logic;
	signal	rRxFfWrData		: std_logic_vector(7 downto 0);	
	signal 	rRxFfWrEn		: std_logic;
	signal	rRxFfWrDatatemp : std_logic_vector(9 downto 0);
	signal 	rState			: StateType ;
	signal	rBuadCnt		: std_logic_vector(9 downto 0);
	signal	rBuadEnd		: std_logic;
	signal	rDataCnt		: std_logic_vector(3 downto 0);
	
	
	
Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------
	RxFfWrData <= rRxFfWrData;
	RxFfWrEn   <= rRxFfWrEn;
	
----------------------------------------------------------------------------------
-- DFF 
	u_rRxFfWrDatatemp :Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if (RstB ='0') then
				rRxFfWrDatatemp <= (others => '0') ;
			else
				if (rState /= stwait) then
					if (rBuadCnt = "1010100100") then
						rRxFfWrDatatemp(9 downto 0) <= rSerDataIn & rRxFfWrDatatemp(9 downto 1);
					else
						rRxFfWrDatatemp <= rRxFfWrDatatemp;
					end if;
				else
					rRxFfWrDatatemp <= (others=> '0');
				end if;
			end if ;
		end if;
	End Process;


----------------------------------------------------------------------------------
	u_State :Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if (RstB = '0') then
				rState <= stwait;
			else
				case (rState) Is
					when stwait =>
						if (rSerDataIn = '0' ) then
							rState <= stStart;
						else 
							rState <= stwait;
						end if;
					when (stStart) =>
						if( rBuadEnd = '1') then
							rState <= strecive;
						else
							rState <= stStart;
						end if;
						
					when (strecive) =>
						if (rBuadEnd = '1'and rDataCnt = "1000") then
							rState <= stsend;
						else
							rState <= strecive;
						end if;
					when (stsend) =>
						rState <= stwait;
						
				end case;
				
			end if;
		end if;
	End Process;
	
	
	u_rSerDataIn : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			rSerDataIn		<= SerDataIn;
		end if;
	End Process u_rSerDataIn;
	
	u_BuadCnt : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if (RstB = '0') then
				rBuadCnt <= conv_std_logic_vector(cBuadrate, 10);
			else
				if (rState = stwait) then
					rBuadCnt <= conv_std_logic_vector(cBuadrate, 10);
				else
					if (rBuadCnt = "0000000001") then
						rBuadCnt <=conv_std_logic_vector(cBuadrate,10);
					else
						rBuadCnt <= rBuadCnt-1;
					end if;
				end if;
			end if;
		end if;
	End Process;
	
	u_rBuadEnd :Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then	
			if (RstB = '0') then
				rBuadEnd <= '0';
			else
				if (rBuadCnt = "0000000010") then
					rBuadEnd <= '1';
				else
					rBuadEnd <= '0';
				end if;
			end if;
		end if;
	End Process;

	u_DataCnt : Process (Clk) Is
	Begin 
		if ( rising_edge(Clk) ) then
			if (RstB = '0') then
				rDataCnt <= (others=> '0');
			else
				if (rState = stwait) then
						rDataCnt <= (others => '0');

				elsif (rBuadEnd = '1') then
					if (rDataCnt = "1001") then
						rDataCnt <= (others => '0');
					else
						rDataCnt <= rDataCnt + '1';
					end if;
				else
					rDataCnt <= rDataCnt; 
				end if;
			end if;
		end if;
	End Process;
	
	u_rRxFfWrData : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if (RstB = '0') then
				rRxFfWrData <= (others => '0');
			else
				if (rState = stsend and RxFfFull = '0' and rSerDataIn = '1') then
					rRxFfWrData <= rRxFfWrDatatemp(9 downto 2);
				else
					rRxFfWrData <= rRxFfWrData;
				end if;
			end if;
		end if;
	End Process;

	u_RxFfWrEn : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if (RstB = '0') then
				rRxFfWrEn <= '0';
			else
				if (rState = stsend and RxFfFull = '0' and SerDataIn = '1' )then
					rRxFfWrEn <= '1';
				else
					rRxFfWrEn <= '0';
				end if;
			end if;
		end if;
	End Process;
	

End Architecture rtl;