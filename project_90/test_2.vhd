-----------------------------------------------------------------------------------
--IMPLEMENTAZIONE LOGICA DELLA MACCHINA:
--IL PRIMO STATO S0 PERMANE IN ATTESA DEL PASSAGGIO DEL BADGE DA SINISTRA
--IL SECONDO STATO S1 CONTIENE TUTTA LA LOGICA DELLA MACCHINA, ESSO CONTIENE UNO
--SWITCH CHE MUTA A SECONDA DELL'INPUT CHE CI ASPETTIAMO 
--LA GESTIONE ERRORE PREVEDE UN CONTATORE STRETTAMENTE LEGATO A 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Progetto_90 is
    Port ( clk : in STD_LOGIC;
			  rst : in STD_LOGIC;
			  col : in STD_LOGIC_VECTOR(0 to 2);
			  row : in STD_LOGIC_VECTOR(0 to 3);
			  dir : in STD_LOGIC_VECTOR(0 to 1);
           session_open : out  STD_LOGIC;
           errore : out  STD_LOGIC);
end Progetto_90;

architecture Behavioral of Progetto_90 is

type stato is (s0,s1,s3,pressure_state,s_errore,s_canc);


signal next_state,current_state : stato;
signal count, new_count : integer range 0 to 30;
signal phase_count,new_phase_count : integer ;
signal avvio_contatore : STD_LOGIC:='0';
signal timeover : STD_LOGIC:='0';

begin

current_state_register: process(clk,rst)
begin
	if rising_edge(clk) then
		if rst='1' then current_state<=s0; count<=0; phase_count<=0;
		else current_state<=next_state; count<=new_count; phase_count<=new_phase_count;
		end if;
	end if;
end process;

state_transition : process(current_state,phase_count,col,row,dir,timeover)
begin
new_phase_count<=phase_count;


case current_state is         
	
	when s0=> 	avvio_contatore<='0';
					if(col="000" and row="0000" and dir="01") then next_state<= s1;new_phase_count<=1;
					else next_state <= s0;
					end if;
					
					
	when s1=> 	avvio_contatore<='1';

case phase_count is 
						when 1=> avvio_contatore<='1';
							if(timeover='0' and col="010" and row="0001") then next_state <= pressure_state; 
							elsif(timeover='0' and (col="000" and row="0000" and (dir="01" or dir="00"))) then       next_state<= current_state;
							elsif(timeover='1' or (col="000" and row="0000" and dir="10")) then next_state<= s0;
							else next_state<=s_errore;	
							end if;
						when 2=> avvio_contatore<='1';
					       if(timeover='0' and ((col="010" and row="0001") or (col="100" and row="1000"))) then next_state <= pressure_state;
							 elsif(timeover='0' and (col="000" and row="0000" and dir="00")) then next_state <= current_state;
							 elsif(timeover='1' or (col="000" and row="0000" and dir="10")) then next_state <= s0;
							 elsif(timeover='0' and (col="000" and row="0000" and dir="01")) then next_state <= current_state;new_phase_count <= 1;
							 else next_state<=s_errore;
							 end if;
						when 3=>   avvio_contatore<='1';
							 if(timeover='0' and ((col="010" and row="1000") or (col="100" and row="1000"))) then next_state <= pressure_state; 
						  	 elsif(timeover='0' and (col="000" and row="0000" and dir="00")) then next_state <= current_state;
							 elsif(timeover='1' or (col="000" and row="0000" and dir="10")) then next_state <= s0;
							 elsif(timeover='0' and (col="000" and row="0000" and dir="01")) then next_state <= current_state;new_phase_count <= 1;
							 else next_state<=s_errore;
						    end if;
						when 4=>   avvio_contatore<='1';
							 if(timeover='0' and ((col="100" and row="0001"))) then next_state<= s3;
							 elsif(timeover='0' and (col="000" and row="0000" and dir="00")) then next_state<= current_state;
						    elsif(timeover='1' or (col="000" and row="0000" and dir="10")) then next_state<= s0;
						    elsif(timeover='0' and (col="000" and row="0000" and dir="01")) then next_state<= current_state;new_phase_count <= 1;
							 else next_state<=s_errore;
						    end if;
					   when others=> next_state<=current_state; new_phase_count <= 1;
					end case;
					
	when pressure_state => 	avvio_contatore<='0';
					if(col="000" and row="0000") then next_state<= s1 ; new_phase_count<= phase_count + 1;
					elsif(((col="010" and row="0001") and phase_count=1) or
					      (((col="010" and row="0001") or (col="100" and row="1000")) and phase_count=2) or                                                  
							(((col="010" and row="1000") or (col="100" and row="1000"))	and phase_count=3)) or
                     (((col="100" and row="0001")) and phase_count=4)                             	then next_state<=current_state;
					else next_state<=s_errore;
					end if;

	when s_errore=>	avvio_contatore<='1';
							if(timeover='0' and (col="001" and row="0001")) then next_state<=s_canc;
							elsif(timeover='1' or (col="000" and row="0000" and dir="10")) then next_state<= s0;
							else next_state<=current_state;								
							end if;
							
	
	when s_canc=>	avvio_contatore<='0';
						if(not(col="001" and row="0001") and not(col="000" and row="0000")) then next_state<= s_errore;
						elsif(col="001" and row="0001") then next_state<=current_state;
						else 
								next_state<=s1; new_phase_count<= phase_count - 1;
						end if;
   when s3=>  avvio_contatore<='0';
	               if(col="001" and row="0001" and dir="10") then next_state<=s0;
						else next_state<=current_state;
						end if;
end case;
end process;

output_function : process(current_state)
begin

session_open<='0';
errore<='0';

	case(current_state) is
		when s0 =>
			session_open<='0'; errore<='0';
		when s1 =>
			session_open<='0'; errore<='0';
		when pressure_state =>
			session_open<='0'; errore<='0';
		when s3 =>
			session_open<='1'; errore<='0';
		when s_errore => 
			session_open<='0'; errore<='1';
		when s_canc =>
			session_open<='0'; errore<='1';
			
end case;
end process;

Contatore_timer : process(avvio_contatore,count,col,row)
begin
	if (avvio_contatore='1' and col="000" and row="0000")then
		if count = 30 then
			new_count<= 0;
			timeover<='1';
		else
			new_count<= count + 1;
			timeover<='0';
		end if;
	else
		new_count<=0;
		timeover<='0';
	end if;
end process;


end Behavioral;
