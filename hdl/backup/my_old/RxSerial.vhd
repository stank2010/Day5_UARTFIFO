library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE ieee.numeric_std.ALL;

Entity RxSerial Is
Port(
	RstB		: in	std_logic;
	Clk			: in	std_logic;

	Fail		: out	std_logic;	
	SerDataIn	: in	std_logic;
	
	RxFfFull	: in	std_logic;
	RxFfWrData	: out	std_logic_vector( 7 downto 0 );
	RxFfWrEn	: out	std_logic
);
End Entity RxSerial;

Architecture rtl Of RxSerial Is

----------------------------------------------------------------------------------
-- Constant declaration
----------------------------------------------------------------------------------
	
	constant cBuadrate : std_logic_vector( 9 downto 0) := "1101100100"; --Equal 868 clock,It has 10 bit 

----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	type StankStateType is 
						(
							stIdle,
							stStart,
							stRecieve,
							stStop,
							stSend
						);
	signal rState	: StankStateType;
	
	signal	rSerDataIn	: std_logic;
	signal  rRxFfFull	: std_logic;
	signal  rFfWrData	: std_logic_vector( 7 downto 0 );
	signal  rFfWrData_OUT	: std_logic_vector( 7 downto 0 );
	signal  rRxFfWrEn	: std_logic;
	
	signal	rBuadEnd 	: std_logic ;
	signal 	rMiddleEnd	: std_logic ;
	
	signal 	rBuadCnt	: std_logic_vector( 9 downto 0 );
	signal 	rDataCnt	: std_logic_vector( 3 downto 0 );

	signal	rExpData		: std_logic_vector( 7 downto 0 );
	signal	rFail			: std_logic;
	
Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------
	RxFfWrData	<= rFfWrData_OUT;
	RxFfWrEn 	<= rRxFfWrEn;
	Fail		<= rFail;
----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------
	
		u_rExpData : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rExpData	<= x"00";
			else
				if ( rRxFfWrEn='1' ) then
					rExpData	<= rExpData + 1;
				else
					rExpData	<= rExpData;
				end if;
			end if;
		end if;
	End Process u_rExpData;

		u_rFail : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rFail	<= '0';
			else
				if ( rRxFfWrEn='1' ) then
					if ( rExpData=rFfWrData_OUT ) then
						rFail	<= '0';
					else
						rFail	<= '1';
					end if;
				else
					rFail	<= '0';
				end if;
			end if;
		end if;
	End Process u_rFail;

	
	u_rSerDataIn : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			rSerDataIn		<= SerDataIn;
		end if;
	End Process u_rSerDataIn;

	u_rRxFfFull	: Process (Clk) Is
	Begin
		if( rising_edge(Clk) )then
			rRxFfFull		<= RxFfFull;
		end if;
	End Process u_rRxFfFull;
	
	u_rBuadCnt	: Process (Clk) Is
	Begin
		if( rising_edge(Clk) )then
			if(RstB='0' or rState=stIdle)then
				rBuadCnt <= cBuadrate-1;
			else 
				if( rState=stStart or rState=stRecieve or rState=stStop )then
					if( rBuadCnt="0000000001" )then
						rBuadCnt <= "1101100100";
					else 
						rBuadCnt <= rBuadCnt-1;
					end if;
				else 
					rBuadCnt <= cBuadrate-1;
				end if;
			end if;
		end if;
	End Process u_rBuadCnt;
	
	u_rMiddleEnd : Process (Clk) Is
	Begin
		if(rising_edge(Clk))then
			if( RstB='0' )then
				rMiddleEnd <= '0';
			else 
				if(rBuadCnt="1010001011")then
					rMiddleEnd <= '1';
				else 
					rMiddleEnd <= '0';
				end if;
			end if;	
		end if;
	End Process u_rMiddleEnd;
	
	u_rDataCnt 	: Process (Clk) Is
	Begin
		if( rising_edge(Clk) ) then
			if( RstB='0' )then
				rDataCnt <= (others=>'0');
			else 
				if(rState=stRecieve)then
					if( rMiddleEnd='1' )then
						rDataCnt <= rDataCnt+1;
					else 
						rDataCnt <= rDataCnt; 
					end if;
				else 
					rDataCnt <= (others=>'0');
				end if;
			end if;
		end if;
	End Process u_rDataCnt;
	
	u_rBuadEnd	: Process (Clk) Is
	Begin
		if( rising_edge(Clk) )then
			if( RstB='0' )then
				rBuadEnd <= '0';
			else 
				if(rBuadCnt="0000000010")then
					rBuadEnd <= '1';
				else 
					rBuadEnd <= '0';
				end if;
			end if;
		end if;
	End Process u_rBuadEnd;
	
	
	u_rState	: Process (Clk) Is
	Begin
		if( rising_edge(Clk) )then
			if(RstB='0')then
				rState <=stIdle;
			else 
				case( rState ) is
					when stIdle =>
						if( rSerDataIn='0' )then --and rStartEnd='1'
							rState <= stStart;
						else 
							rState <= stIdle;
						end if;
					when stStart =>
						if( rBuadEnd='1' )then
							rState <= stRecieve;
						else 
							rState <= stStart;
						end if;
					when stRecieve =>
						if(rBuadEnd='1' and rDataCnt="1000")then
							rState <= stStop;
						else 
							rState <= stRecieve;
						end if;
					when stStop  =>
						if( rBuadEnd='1' )then
							rState <= stSend;
						else 
							rState <= stStop;
						end if;
					when stSend  =>
						rState <= stIdle;
				end case;
			end if;
		end if;
	End Process u_rState;

	u_rFfWrData	: Process (Clk) Is
	Begin
		if(rising_edge(Clk))then
			if( RstB='0' ) then
				rFfWrData <= (others=>'0');
			else 
				if( rState=stRecieve or rState=stStop or rState=stSend)then
					if(rBuadCnt="0110110010" and rState=stRecieve)then --Equal 434
						rFfWrData <= rSerDataIn & rFfWrData(7 downto 1); --right_shift and Concat  
					else 
						rFfWrData <= rFfWrData;
					end if;
				else 
					rFfWrData <= (others=>'0');
				end if;
			end if;
		end if;
	End Process u_rFfWrData;
	
	u_rFfWrData_OUT : Process (Clk) Is
	Begin
		if(rising_edge(Clk))then
			if(RstB='0')then
				rFfWrData_OUT <= (others=>'1');
			else 
				if( RxFfFull='0' and rState=stStop and  rSerDataIn='1' and rBuadEnd='1')then
					rFfWrData_OUT <= rFfWrData;
				else 
					rFfWrData_OUT <= (others=>'1');
				end if;
			end if;
		end if;
	End Process u_rFfWrData_OUT;
	
	u_rRxFfWrEn	: Process (Clk) Is
	Begin
		if(rising_edge(Clk))then
			if(RstB='0')then
				rRxFfWrEn <= '0';
			else 
				if( RxFfFull='0' and rState=stStop and  rSerDataIn='1' and rBuadEnd='1')then
					rRxFfWrEn <= '1';
				else 
					rRxFfWrEn <= '0';
				end if;
			end if;
		end if;		
	End Process u_rRxFfWrEn;
	
End Architecture rtl;