#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
///Elvis Cela
//// Makes a table containing the Recording ID, first and second pulse detected Xpoints as well as time diff
/// from EEG waves containing Chr2 pulses


Function vda()



string list
string name
variable index =0
variable i
wave Time_to_pulse1
wave Time_to_pulse2
wave Time_to_pulse3
wave Time_to_pulse4
wave Time_to_pulse5
Wave Time_diff
wave Length
wave/T Recording_ID
variable k =0
variable h = 0 
variable det = -0.015
//variable wpoints = 35


///variables for time intervals of edge detection

variable a = 0
variable b = 4
variable c = 8
variable d = 12
variable e = 16
variable f = 20
variable g = 25

Make/O/N=1350 Time_to_pulse1
Make/O/N=1350 Time_to_pulse2
Make/O/N=1350 Time_to_pulse3
Make/O/N=1350 Time_to_pulse4
Make/O/N=1350 Time_to_pulse5
Make/O/N=1350 Time_to_pulse6

Make/O/N=1350 Time_diff
Make/O/N=1350 Length
Make/T/O/N=1350 Recording_ID
 

SetDataFolder root:
list = WaveList("Cell_08_*", ";", "")  //get wavelist matching cell
print itemsinlist(list,";")


for(i =0;i < itemsinlist(list);i +=1)
		name = stringfromlist(i,list)
		print name; Recording_ID[k]= name
		print rightx($name); Length[k] = rightx($name)
		FindPeak /M= -0.015 /Q/R =(a,b) $name ; print V_PeakLoc; Time_to_pulse1[k]= V_PeakLoc
		FindPeak /M= -0.015 /Q/R =(b+1,c) $name ; print V_PeakLoc; Time_to_pulse2[k]= V_PeakLoc
		FindPeak /M= -0.015 /Q/R =(c+1,d) $name ; print V_PeakLoc; Time_to_pulse3[k]= V_PeakLoc
		FindPeak /M= -0.015 /Q/R =(d+1,e) $name; print V_PeakLoc; Time_to_pulse4[k]= V_PeakLoc
		FindPeak /M= -0.015 /Q/R =(e+1,f) $name; print V_PeakLoc; Time_to_pulse5[k]= V_PeakLoc
		FindPeak /M= -0.015 /Q/R =(f+1,g) $name; print V_PeakLoc; Time_to_pulse6[k]= V_PeakLoc
		
		index+=1
		k+=1 
	endfor
	

		
edit 	Recording_ID,Time_to_pulse1,Time_to_pulse2,Time_to_pulse3,Time_to_pulse4,Time_to_pulse5,Time_to_pulse6,Length,Time_diff
	
End