#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

///////////////////////  Procedure file written by Elvis Cela
/////////////////////// useful alongside FFT panel when doing seizure analysis

//// also updated for use in FI curves on Feb 4 2017/////////////////////////////////////////////////



// This code overwrites the waves in the top graph and renames them to oldname + _v2
// to use this function simply duplicate the graph containing all the waves first and then run this 
// on the duplicated graph so the original waves are untouched



Function Dupandgraph(v2)
	String v2

	String wnames =wavelist("*",";","WIN:") //WIN: means top graph
	String name, newname
	Variable i
	
	
 
	for(i =0;i < itemsinlist(wnames);i +=1)
		name = stringfromlist(i,wnames)
		newname = name + "_"+ v2  					//////////////// option for appending suffix
									
		Rename $name $newname
		
		
	endfor
End


///// FFT analysis of EEGs
function filtbtncurs()
wave filtered, filtered_FFT
FFT/OUT=4/RP=[pcsr(A),pcsr(B)]/DEST=filtered_FFT filtered;DelayUpdate
///outputs FFT of filtered trace between cursors for quick frequency check

End

///notch filter at 60HZ original EEG to produce filtered wave

Function filter(notch)
String notch
String wnames =wavelist("*",";","WIN:") //WIN: means top graph
	String name, newname
	Variable i
 
	for(i =0;i < itemsinlist(wnames);i +=1)
		name = stringfromlist(i,wnames)
		newname = name + "_"+ notch
		Rename $name $newname
	endfor

Make/O/D/N=0 coefs; DelayUpdate
FilterFIR/DIM=0/NMF={0.06,0.005,9.09495e-13,2}/COEF coefs, $newname

Display $newname
End




//Find Y Max between different X values
Function d()

String wnames =wavelist("*",";","WIN:") //WIN: means top graph
	String name
	Variable i
 
	for(i =0;i < itemsinlist(wnames);i +=1)
		name = stringfromlist(i,wnames)
		print name
		print rightx($name)
		FindLevel /Edge=2 /Q/R =(0,10) $name ,-0.4; print V_LevelX
		FindLevel /Edge=2 /Q/R =(15,30) $name ,-0.4; print V_LevelX
		FindLevel /Edge=2 /Q/R =(31,50) $name ,-0.4; print V_LevelX
		 
	endfor
End


///Window clean-up functions
Function deletewin()

String wlist = WinList("*FFT*",";","WIN:1") //WIN: 1 means graphs
String name
Variable i
Variable nWaves = itemsinlist(wlist)
Make/O/T/N=(nWaves) labelWave

 
	for(i=0;i < nWaves;i +=1)
		name = stringfromlist(i,wlist)
		wave w0 = $name
		print w0[i]
		labelwave[i] =name
		killwindow name
		 
	endfor
End

function killwindows()
 
string list = winlist("*FFT*", ";", "WIN:64,FLT:1,FLT:2")
variable i 
 
for (i=0;i<itemsinlist(list); i+=1)
 
string windowname = stringfromlist (i,list, ";")
 
killwindow $windowname
 
endfor
 
 
end


///Additional analysis tool used with FFT_v02 during seizure detection
function go() ////// appends additional values onto seizure tables for further analysis

nw("Seizure Stats") 

wave wSeizureLoc
Wave /T  Seizure_Comments ,Seizure_decision
wave /T  time_in_mins
Wave xel
Wave yel

Make /O /N=  (numpnts(wSeizureLoc)) xel
Make /O /N= (numpnts(wSeizureLoc)) yel

xel= (wSeizureLoc/60)
yel = ((xel-floor(xel)) * 60)

Make /O/T/N= (numpnts(xel)) time_in_mins =  num2str (floor(xel[p])) + ":" + (num2str(round(yel[p])))
 

print xel,yel,time_in_mins

Make /O/T Seizure_Comments
Make /O/T Seizure_decision

Appendtotable time_in_mins,Seizure_Comments,Seizure_decision

end


/// Function to work on IOC curves
function show23()

string current_list
string cell_list
string current_name
string cell_name
variable i
string new_curr
string new_cell
wave/T cell_identifier

String graphName
Variable index, numXYPairs
wave slope_fi
wave error_slope_fi
wave More_than_zero
wave max_current


SetDataFolder root:
current_list = WaveList("IOC_curr*",";","")  //get wavelist matching current 
cell_list = WaveList("IOC_freq*",";","")  //get wavelist matching current


		
		new_curr = sortlist (current_list,";",16)
		//print new_curr
		
		new_cell = sortlist (cell_list,";",16)
		//print new_cell
		
		numXYPairs = ItemsInList(new_curr)
			
		Make/O /N= 46 slope_fi
		Make/O /N= 46 error_slope_fi
		Make/O /N= 46 More_than_zero
		Make/O /N= 46 max_current
		Make/O /T= 46 cell_identifier

	
	if (numXYPairs != ItemsInList(new_cell))
		DoAlert 0, "The number of X waves must equal the number of Y waves."
		return -1
	endif
 
	for(index=0; index<numXYPairs; index+=1)
		String xWaveName = StringFromList(index, new_curr)
		Wave xWave = $xWaveName
		String yWaveName = StringFromList(index, new_cell)
		Wave yWave = $yWaveName
		wave cell_num
		//wave More_than_zero
		//wave max_current
		cell_num[index] =yWave[index]
		cell_identifier[index]=yWaveName
		
		
		//FitAndGraphXYPair(xWave, yWave)
		Display yWave vs xWave
		ModifyGraph mode=3,marker=19,rgb=(0,0,65535)		// Round blue markers
		DoUpdate
		

		
		// get x-range that will be used to fit the slope
		Findlevel /Edge=1 /Q /P yWave, 0 ; More_than_zero[index] = V_levelX+1
		WaveStats  /M=2 /Q /R = (0,) yWave; max_current[index]= pnt2x(xWave,V_maxloc) 
		

 
 /// fitting to the whole x-range , set /X=xWave
		CurveFit /TBOX=256 line yWave[More_than_zero[index], max_current[index]] /X= xWave /D 
		wave w_coef
		wave w_sigma
		wave cell_num
		slope_fi[index] = w_coef[index]
		error_slope_fi[index]= w_sigma[index]
 
		String textboxName = "CF_" + NameOfWave(yWave)
		String text
 
	// Append Rab - the correlation between the intercept (a) and the slope (b)
		sprintf text "V_Rab = %g", V_Rab
		AppendText /N=$textboxName text
		Appendtext /N=$textboxName yWaveName
		TextBox/C/N=$textboxName/A=LT/X=0.00/Y=0.00
		
		

 
		
	endfor
 
	return 0


	do
		
	appendtograph $(stringfromlist(i+1,new_cell, ";")) vs $(stringfromlist(i+1,new_curr, ";"))
	i+=1				
   while (i < itemsinlist(new_cell))
	
	
end

//Order of operations for working on matrices//
/// Related to CRACM/RMP data analysis//


concatenate/NP=2/O {n1,n2,n3},wdest_stim //concatenates matrices n1,n2.n3 intor #n layers while
														//retaining dimensions
														
MatrixOP/O ab=transposeVol(wdest_stim,4)  // transposes the matrix


Redimension/N=(n,64)/E=1 ab  /// Redimension matrix from #n layers into 64 values (ex for 8X8 matrix)

MatrixOP/O theVar_stim=varCols(ab)               //// perform statistics on columns
MatrixOP/O theavg_stim=averageCols(ab)


Make/O/N=(8,8)/D stim_var,stim_avg // reconstitue matrix from 1X64 array manuall



function normalize(w,low,high)
wave w
variable low //= -5.649615387584264e-05
variable high //= 0.0003004366010120268


												
MatrixOP/O var1= maxVal(w)
MatrixOP/O col1 = normalizeCols(w)
MatrixOP/O mat1 = scale(w,low,high)

end

///Function to select subsets of data for graphing (ex. IOC analysis)

Function select()

//	Display /W=(762,168,1424,596) rseries_stim vs half_w_stim
//	AppendToGraph rseries_ctrl vs half_w

	WAVE	rseries_stim, half_w_stim
	WAVE	rseries_ctrl, half_w
	WAVE spike_height_stim, spike_height_ctrl
	WAVE ih,ih_stim
	WAVE ahp,ahp_stim
	Wave quality_ctrl,quality_stim
	Wave vm, vm_stim
	Wave rin,rin_stim
	Wave rheo, rheo_stim
	Wave latency, latency_stim      
	wave spike_thresh,spike_thresh_stim
	wave min_dv_dt_ctrl, min_dv_dt_stim
	wave max_dv_dt_ctrl, max_dv_dt_stim


	Variable	upperT = 40 //28.491847826087*1.08  //30 usually
	Variable	lowerT = 0 //14.2554347826087*0.92 // 0 usually 
	Variable	hw_T = 1  // 1 usually
	Variable quality_crit= 0  ///0 usually
	wave Rs_sel_mean
	wave color
	wave hw_sel_mean
	wave rin_sel_mean
	wave Spheig_sel_mean
	wave ahp_sel_mean
	wave ih_sel_mean
	wave spike_thresh_sel_mean
	wave latency_sel_mean
	wave vm_sel_mean
	wave rheo_sel_mean
	wave min_dvdt_sel_mean
	wave max_dvdt_sel_mean
	 
	
	
	Print "Quality", quality_crit
	Print "upper Thesh", upperT
	Print "lower thresh",lowerT
	Print "half_width", hw_T
	
	Variable	i
	Variable	n

	// Stim
	n = numpnts(rseries_stim)
	i = 0
	Make/O/N=(0) Rs_stim_select,hw_stim_select,spike_height_stim_sel,ih_stim_select,ahp_stim_select,vm_stim_select,rin_stim_select,rheo_stim_select,latency_stim_select,spike_thresh_stim_select, min_dvdt_stim_select, max_dvdt_stim_select
	do
		if ((rseries_stim[i]<upperT) %& (rseries_stim[i]>LowerT) %& (half_w_stim[i]>hw_T) %& (quality_stim[i] >= quality_crit))
			Rs_stim_select[numpnts(Rs_stim_select)] = {rseries_stim[i]}
			hw_stim_select[numpnts(hw_stim_select)] = {half_w_stim[i]}
			spike_height_stim_sel[numpnts(spike_height_stim_sel)] = {spike_height_stim[i]}
			ih_stim_select[numpnts(ih_stim_select)]= {ih_stim[i]}
			ahp_stim_select[numpnts(ahp_stim_select)]= {ahp_stim[i]}
			vm_stim_select[numpnts(vm_stim_select)]= {vm_stim[i]}
			rin_stim_select[numpnts(rin_stim_select)]= {rin_stim[i]}
			rheo_stim_select[numpnts(rheo_stim_select)]= {rheo_stim[i]}
			latency_stim_select[numpnts(latency_stim_select)]= {latency_stim[i]}
			spike_thresh_stim_select[numpnts(spike_thresh_stim_select)]= {spike_thresh_stim[i]}
			min_dvdt_stim_select[numpnts(min_dvdt_stim_select)]= {min_dv_dt_stim[i]}
			max_dvdt_stim_select[numpnts(max_dvdt_stim_select)] = {max_dv_dt_stim[i]}
			
		endif
		i += 1
	while(i<n)

	// Ctrl
	n = numpnts(rseries_ctrl)
	i = 0
	Make/O/N=(0) Rs_ctrl_select,hw_ctrl_select,spike_height_ctrl_sel,ih_ctrl_select,ahp_ctrl_select,vm_ctrl_select,rin_ctrl_select,rheo_ctrl_select,latency_ctrl_select,spike_thresh_ctrl_select,min_dvdt_ctrl_select, max_dvdt_ctrl_select
	do
		if ((rseries_ctrl[i]<upperT) %& (rseries_ctrl[i]>LowerT) %& (half_w[i]>hw_T) %& (quality_ctrl[i] >= quality_crit))
			Rs_ctrl_select[numpnts(Rs_ctrl_select)] = {rseries_ctrl[i]}
			hw_ctrl_select[numpnts(hw_ctrl_select)] = {half_w[i]}
			spike_height_ctrl_sel[numpnts(spike_height_ctrl_sel)] = {spike_height_ctrl[i]}
			ih_ctrl_select[numpnts(ih_ctrl_select)]= {ih[i]}
			ahp_ctrl_select[numpnts(ahp_ctrl_select)]= {ahp[i]}
			vm_ctrl_select[numpnts(vm_ctrl_select)]= {vm[i]}
			rin_ctrl_select[numpnts(rin_ctrl_select)]= {rin[i]}
			rheo_ctrl_select[numpnts(rheo_ctrl_select)]= {rheo[i]}
			latency_ctrl_select[numpnts(latency_ctrl_select)]= {latency[i]}
			spike_thresh_ctrl_select[numpnts(spike_thresh_ctrl_select)]= {spike_thresh[i]}
			min_dvdt_ctrl_select[numpnts(min_dvdt_ctrl_select)]= {min_dv_dt_ctrl[i]}
			max_dvdt_ctrl_select[numpnts(max_dvdt_ctrl_select)] = {max_dv_dt_ctrl[i]}
			
		endif
		i += 1
	while(i<n)
	
	Variable	 p_val
	Variable t_stat
	
	p_val = JT_BarGraphFromDataWithName("Rs_stim_select","Rs_ctrl_select","Rs_sel")
	QuickStars(JT_p2sigStr(p_val))
	WAVE/T Rs_sel_xLabel
	Rs_sel_xLabel = {"stim","ctrl"}
	label left,"Rs (MOhm)"
	ModifyGraph zColor(Rs_sel_mean)={vm_sel_mean,*,*,ctableRGB,0,color}
	
	p_val = JT_BarGraphFromDataWithName("min_dvdt_stim_select","min_dvdt_ctrl_select","min_dvdt_sel")
	QuickStars(JT_p2sigStr(p_val))
	WAVE/T min_dvdt_sel_xLabel
	min_dvdt_sel_xLabel = {"stim","ctrl"}
	label left,"min dv/dt (mV/ms)"
	ModifyGraph zColor(min_dvdt_sel_mean)={vm_sel_mean,*,*,ctableRGB,0,color}
	
	p_val = JT_BarGraphFromDataWithName("max_dvdt_stim_select","max_dvdt_ctrl_select","max_dvdt_sel")
	QuickStars(JT_p2sigStr(p_val))
	WAVE/T max_dvdt_sel_xLabel
	max_dvdt_sel_xLabel = {"stim","ctrl"}
	label left,"max dv/dt (mV/ms)"
	ModifyGraph zColor(max_dvdt_sel_mean)={vm_sel_mean,*,*,ctableRGB,0,color}
	
	


	p_val = JT_BarGraphFromDataWithName("hw_stim_select","hw_ctrl_select","HW_sel")
	QuickStars(JT_p2sigStr(p_val))
	WAVE/T HW_sel_xLabel
	HW_sel_xLabel = {"stim","ctrl"}
	label left,"spike half-width (ms)"
	ModifyGraph zColor(Hw_sel_mean)={vm_sel_mean,*,*,ctableRGB,0,color}
	
	p_val = JT_BarGraphFromDataWithName("spike_height_stim_sel","spike_height_ctrl_sel","SPheig_sel")
	QuickStars(JT_p2sigStr(p_val))
	WAVE/T SPheig_sel_xLabel
	SPheig_sel_xLabel = {"stim","ctrl"}
	label left,"spike height (mV)"
	ModifyGraph zColor(Spheig_sel_mean)={vm_sel_mean,*,*,ctableRGB,0,color}
	
	p_val = JT_BarGraphFromDataWithName("ih_stim_select","ih_ctrl_select","ih_sel")
	QuickStars(JT_p2sigStr(p_val))
	WAVE/T ih_sel_xLabel
	ih_sel_xLabel = {"stim","ctrl"}
	label left,"ih (mV)"
	ModifyGraph zColor(ih_sel_mean)={vm_sel_mean,*,*,ctableRGB,0,color}
	
	p_val = JT_BarGraphFromDataWithName("ahp_stim_select","ahp_ctrl_select","ahp_sel")
	QuickStars(JT_p2sigStr(p_val))
	WAVE/T ahp_sel_xLabel
	ahp_sel_xLabel = {"stim","ctrl"}
	label left,"ahp (mV)"
	ModifyGraph zColor(ahp_sel_mean)={vm_sel_mean,*,*,ctableRGB,0,color}
	
	p_val = JT_BarGraphFromDataWithName("vm_stim_select","vm_ctrl_select","vm_sel")
	QuickStars(JT_p2sigStr(p_val))
	WAVE/T vm_sel_xLabel
	vm_sel_xLabel = {"stim","ctrl"}
	label left,"Vm (mV)"
	ModifyGraph zColor(vm_sel_mean)={vm_sel_mean,*,*,ctableRGB,0,color}
	
	p_val = JT_BarGraphFromDataWithName("rin_stim_select","rin_ctrl_select","rin_sel") 
	QuickStars(JT_p2sigStr(p_val))
	WAVE/T rin_sel_xLabel
	rin_sel_xLabel = {"stim","ctrl"}
	label left,"rin (MOhm)"
	ModifyGraph zColor(rin_sel_mean)={vm_sel_mean,*,*,ctableRGB,0,color}
	
	
	p_val = JT_BarGraphFromDataWithName("rheo_stim_select","rheo_ctrl_select","rheo_sel")
	QuickStars(JT_p2sigStr(p_val))
	WAVE/T rheo_sel_xLabel
	rheo_sel_xLabel = {"stim","ctrl"}
	label left,"rheo (nA)"
	ModifyGraph zColor(rheo_sel_mean)={vm_sel_mean,*,*,ctableRGB,0,color}
	
	
	p_val = JT_BarGraphFromDataWithName("latency_stim_select","latency_ctrl_select","latency_sel")
	QuickStars(JT_p2sigStr(p_val))
	WAVE/T latency_sel_xLabel
	latency_sel_xLabel = {"stim","ctrl"}
	label left,"latency (ms)"
	ModifyGraph zColor(latency_sel_mean)={vm_sel_mean,*,*,ctableRGB,0,color}
	
	p_val = JT_BarGraphFromDataWithName("spike_thresh_stim_select","spike_thresh_ctrl_select","spike_thresh_sel")
	QuickStars(JT_p2sigStr(p_val))
	WAVE/T spike_thresh_sel_xLabel
	spike_thresh_sel_xLabel = {"stim","ctrl"}
	label left,"spike thresh (mV)"
	ModifyGraph zColor(spike_thresh_sel_mean)={vm_sel_mean,*,*,ctableRGB,0,color}

	
	
	

	Concatenate/O/NP {Rs_stim_select,Rs_ctrl_select},Rs_both_select
	Concatenate/O/NP {hw_stim_select,hw_ctrl_select},hw_both_select
	Concatenate/O/NP {spike_height_stim_sel,spike_height_ctrl_sel},spike_height_both_select
	qp("hw_both_select","Rs_both_select")

	qp("spike_height_both_select","Rs_both_select")
	
	
	JT_ArrangeGraphs2("Rs_sel_graph;HW_sel_graph;SPheig_sel_graph;ih_sel_graph;ahp_sel_graph;vm_sel_graph;rin_sel_graph;rheo_sel_graph;latency_sel_graph;spike_thresh_sel_graph;hw_both_select_vs_Rs_both_selec;spike_height_both_select_vs_Rs_;max_dvdt_sel_graph;min_dvdt_sel_graph;",4,4)
	
End
