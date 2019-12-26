library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

Entity TxSerial Is
Port(
	RstB		: in	std_logic;
	Clk			: in	std_logic;
	
	TxFfEmpty	: in	std_logic;
	TxFfRdData	: in	std_logic_vector( 7 downto 0 );
	TxFfRdEn	: out	std_logic;
	
	SerDataOut	: out	std_logic
);
End Entity TxSerial;

Architecture rtl Of TxSerial Is
	constant cbuadCnt	:integer := 434;
	
	type SerStateType is 
						(
							stIdle ,
							stRdReq ,
							stWtData ,
							stWtEnd
						);
						
	signal rState 		: SerStateType;
	
	signal rTxFfRdEn	: std_logic_vector (1 downto 0);
	signal rSerData		: std_logic_vector (9 downto 0);
	signal rDataCnt		: std_logic_vector (3 downto 0);
	signal rBuadCnt		: std_logic_vector (9 downto 0);
	signal rBuadEnd		: std_logic;
	

Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------
	TxFfRdEn  <= rTxFfRdEn(0);
	SerDataOut	<= rSerData(0);
----------------------------------------------------------------------------------
-- DFF 
	u_rState : Process(Clk) Is
	Begin
		if (rising_edge(Clk))	then
			if (RstB = '0' ) then
				rState <= stIdle;
			else
				case ( rState ) is
					when stIdle		=>
						if(TxFfEmpty = '0') then
							rState <= stRdReq;
						else
							rState <= stIdle;
						end if;
					when stRdReq	=>
						rState <= stWtData;
					when stWtData	=>
						if (rTxFfRdEn(1) = '1') then
							rState <= stWtEnd;
						else
							rState <= stWtData;
						end if;
						
					when stWtEnd	=>
						if ( rDataCnt(3 downto 0) = "1001" and rBuadEnd = '1') then
							rState <= stIdle;
						else
							rState <= stWtEnd;
						end if;
					 
				
				end case;
			end if;
		end if;
	End Process u_rState;
	
	u_TxFfRdEn : Process(Clk) Is 
	Begin 
		if(rising_edge(Clk)) then
			if(RstB= '0') then
				rTxFfRdEn <= (others  => '0');
			else
				rTxFfRdEn(1)	<= rTxFfRdEn(0);
				if (rState = stRdReq ) then
					rTxFfRdEn(0) <= '1';
				else
					rTxFfRdEn(0) <= '0';
				end if;
			end if;
		end if;
		
	End Process u_TxFfRdEn;
	
	u_rSerData : Process(Clk) Is
	Begin
		if(rising_edge(Clk)) then
			if(RstB = '0') then
				rSerData <= (others => '1');
				
			else
			
				if (rTxFfRdEn(1) = '1' and rState = stWtData) then
					rSerData(9) 			<= '1';
					rSerData(8 downto 1)	<= TxFfRdData;
					rSerData(0)				<= '0';
				elsif (rBuadEnd = '1') then
					rSerData	<= '1'  & rSerData(9 downto 1);
				else
					rSerData	<= rSerData;
				end if;				
			end if; 
		end if;
	End Process u_rSerData;
	
	
		
	u_rBuadCnt	: Process(Clk) Is
	Begin
		if ( rising_edge(Clk)) then
			if (RstB = '0') then
				rBuadCnt	<= conv_std_logic_vector(cbuadCnt,10);
			else
			
				if (rState = stWtEnd) then
					if (rBuadCnt = 1 ) then 
						rBuadCnt	<= conv_std_logic_vector(cbuadCnt,10);
						
					else
						rBuadCnt	<= rBuadCnt - 1;
					end if;
				end if;
			end if;
		end if;
	End Process u_rBuadCnt;
	
	u_rBuadEnd : Process(Clk) Is
	Begin
		if (rising_edge(Clk)) then
			if (RstB = '0') then
				rBuadEnd	<= '0';
			else
				if (rBuadCnt =2 ) then
					rBuadEnd	<= '1';
				else
					rBuadEnd	<= '0';
				end if;
			end if;
		end if;
	End Process u_rBuadEnd;
	u_rDataCnt : Process(Clk) Is
	Begin 
		if (rising_edge(Clk)) then
			if (RstB = '0') then
				rDataCnt	<= "0000";
			else
				if (rDataCnt = "1001" and rBuadEnd = '1') then
					rDataCnt <= (others => '0') ;
				elsif (rBuadEnd = '1' ) then
					rDataCnt <= rDataCnt + 1; 
				else 
					rDataCnt <= rDataCnt;
				end if;
			end if;
		end if;
	End Process u_rDataCnt;



					
	----------------------------------------------------------------------------------
	
End Architecture rtl;