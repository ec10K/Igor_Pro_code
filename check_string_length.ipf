#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


function check()
wave/T recID

variable i


for(i =121;i < 144;i +=1)
		print "\""+recID[i]+"\""
	
	
	endfor

end

function check2()
wave/T recID
variable i

if	(strlen(recID[i]) !=22 || strlen(recID[i]) !=19 || strlen(recID[i]) !=28 )
		print "There are extra spaces"
	else 
		print "no problems"
	endif
	
end

