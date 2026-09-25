<cfscript>
function YesNo(YN) {
	if (ListFindNoCase("No,N,False,0",Arguments.YN)) return "No";
	return "Yes";
}

function SanitizeFN(FN) {
	var OutFN=Arguments.FN;
	OutFn=Replace(OutFN,":","_","ALL");
	OutFn=Replace(OutFN,"\","_","ALL");
	OutFn=Replace(OutFN,"/","_","ALL");
	Return OutFN;
}

function s(n)
{
	if (val(Arguments.n) NEQ 1) return "s";
}
function ts()
{
	return TimeFormat(Now(),"HH:mm:ss");
}

function ReturnRegExAsString(reg,txt)
{
	var Match=REMatch(Arguments.Reg,Arguments.txt);
	var i=0;
	var RetStr="";
	var Sep="";

	if (ArrayLen(Arguments) EQ 3) Sep=Arguments[3];

	for (i=1;i LTE ArrayLen(Match);i=i+1)
	{
		if (i LT ArrayLen(Match))
		{
			if (Len(Match[i])) RetStr=RetStr & Match[i] & Sep;
		} else {
			RetStr=RetStr & Match[i];
		}
	}

	return RetStr;
}

function StripLF(txt)
{
	return Replace(Arguments.txt,Chr(10),"","ALL");
}
function StripCRLF(txt)
{
	return Replace(StripCR(Arguments.txt),Chr(10),"","ALL");
}

function UNRAIDSlot(id)
{
	if (Arguments.id EQ 0) return "Parity";
	if (Arguments.id EQ 27) return "Parity 2";
	if (Arguments.id GTE 1 AND Arguments.id LTE 26) return "Drive " & Arguments.id;
	return "";
}

function KBytes(bytes)
{
	var b=0;
	var NF="9,999.99";
	if (ArrayLen(Arguments) GT 1) NF=Arguments[2];

	if(Abs(arguments.bytes) lt 1000) return trim(numberFormat(arguments.bytes,"9,999")) & " bytes";

	b=Val(arguments.bytes) / 1000;

	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " KB";
		return trim(numberFormat(b,NF)) & " KB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " MB";
		return trim(numberFormat(b,NF)) & " MB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " GB";
		return trim(numberFormat(b,NF)) & " GB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " TB";
		return trim(numberFormat(b,NF)) & " TB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " PB";
		return trim(numberFormat(b,NF)) & " PB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " EB";
		return trim(numberFormat(b,NF)) & " EB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " ZB";
		return trim(numberFormat(b,NF)) & " ZB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " YB";
		return trim(numberFormat(b,NF)) & " YB";
	}
}

function Hash36(txt)
{
	// Returns a short 6 character psudo-hash value in base 36, saves user having to copy 4 Hash Hex strings 128 characters long
	// InputBaseN can't handle a full Hash value, break it up
	var H=Hash(Arguments.txt);
	var H1=InputBaseN(Left(H,4),16);
	var H2=InputBaseN(Mid(H,8,4),16);
	var H3=InputBaseN(Mid(H,12,4),16);
	var H4=InputBaseN(Mid(H,16,4),16);
	var H5=InputBaseN(Mid(H,20,4),16);
	var H6=InputBaseN(Mid(H,24,4),16);
	var H7=InputBaseN(Mid(H,28,4),16);
	return UCase(Replace(RJustify(FormatBaseN(H1+H2+H3+H4+H5+H6+H7,36),4)," ","0","ALL"));
}
function ShortSHA1(txt) {
	// Convert a SHA1 from Hex to Base36, Every 9 Hex will convert to base 36
//          1         2         3         4
// 1234567890123456789012345678901234567890
// bcf22dfc6fb76b7366b1f1675baf2332a0e6a7ce
// ........|........|........|........|....
// 1        2        3        4        5   
// B36:  nat9jgmv0ctg86d7k3jvfllie5n29cjy
	var H=Hash(Arguments.txt,"SHA");
	var H1=FormatBaseN(InputBaseN(Mid(H,1,9),16),36);
	var H2=FormatBaseN(InputBaseN(Mid(H,10,9),16),36);
	var H3=FormatBaseN(InputBaseN(Mid(H,18,9),16),36);
	var H4=FormatBaseN(InputBaseN(Mid(H,27,9),16),36);
	var H5=FormatBaseN(InputBaseN(Mid(H,36,9),16),36);

	return H1 & H2 & H3 & H4 & h5;
}
function FormatBase42(txt) { // Not done, needs to be case insenstive
	var Str="0123456789abcdefghijklmnopqrstuvwxyz,_-=;%";
	var i=0;
	var p=0;
	var b="";
	var H=LCase(Hash(Arguments.txt,"SHA"));
	// Convert Hash to 4 bit binary
	for (i=1; i LTE 40; i=i+1) {
		b=b & Replace(RJustify(FormatBaseN(InputBaseN(Mid(H,i,1),16),2),4)," ","0","ALL");
	}
	var H1=InputBaseN("111111",2);
	return b & "-" & H1;
}
function GetSaveDir(Key,PortNo) {
	var DriveDir=HW[Arguments.Key].Ports[Arguments.PortNo].Attrib.Model & "_" & 
				 HW[Arguments.Key].Ports[Arguments.PortNo].Attrib.Rev & "_" &
				 HW[Arguments.Key].Ports[Arguments.PortNo].Attrib.Serial & "_" &
				 Replace(HW[Arguments.Key].Ports[Arguments.PortNo].Attrib.Size.DispSize,".","_","ALL");
	DriveDir=ReturnRegExAsString("[A-Za-z0-9]*",DriveDir,"_");
	DriveDir=LCase(Replace(DriveDir," ","_","ALL"));
	DriveDir=Replace(DriveDir,"__","_","ALL");
	DriveDir=Replace(DriveDir,"__","_","ALL");
	DriveDir=Replace(DriveDir,"__","_","ALL");
	DriveDir=Replace(DriveDir,"__","_","ALL");
	return DriveDir;
}
</cfscript>



<CFFUNCTION name="GetReadAvg" returntype="any">
	<CFARGUMENT name="FN" required="true" type="string">
	<CFARGUMENT name="RPM" required="true" type="string">
	<CFARGUMENT name="SkipLines" required="false" type="number">
	<CFARGUMENT name="MaxGap" required="false" type="number" default="45000000"> <!--- "0" disables max gap detection --->
	<CFSET VAR BytesRead=0>
	<CFSET VAR LastBytesRead=0>
	<CFSET VAR BytesDiff=0>
	<CFSET VAR Results="">
	<CFSET VAR CurrLine="">
	<CFSET VAR AVG=0>
	<CFSET VAR MaxAvg=0>
	<CFSET VAR MinRead=9999999999>
	<CFSET VAR MaxRead=0>
	<CFSET VAR LC=0>
	<CFSET VAR Skip=1> <!--- How many lines to skip from the start --->
	<CFSET VAR MaxFN=ListDeleteAt(Arguments.FN,ListLen(Arguments.FN,"."),".") & "_max.txt">

	<CFIF IsNumeric(Arguments.SkipLines)>
		<CFSET Skip=Arguments.SkipLines>
	</CFIF>

	<CFFILE action="read" file="#Arguments.FN#" variable="Results">
	<CFLOOP index="CurrLine" list="#Results#" delimiters="#Chr(13)#">
		<CFIF ListLen(CurrLine," ") GT 1 AND Find("record",CurrLine) EQ 0>
			<CFSET BytesRead=ListFirst(CurrLine," ")>
			<CFSET BytesDiff=BytesRead - LastBytesRead>
			<CFSET LastBytesRead=BytesRead>
			<CFIF Skip GT 0>
				<CFSET Skip=Skip - 1>
			<CFELSE>
				<CFSET LC=LC+1>
				<CFIF BytesDiff LT MinRead>
					<CFSET MinRead=BytesDiff>
				</CFIF>
				<CFIF BytesDiff GT MaxRead>
					<CFSET MaxRead=BytesDiff>
				</CFIF>
				<CFSET Avg=Avg + BytesDiff>
			</CFIF>
		</CFIF>
	</CFLOOP>
	<CFIF Arguments.MaxGap GT 0>
		<CFIF Arguments.RPM NEQ "Solid State Device" AND MaxRead - MinRead GT Arguments.MaxGap>
			<CFRETURN "Speed Gap of #KBytes(MaxRead-MinRead)# (max allowed is #KBytes(Arguments.MaxGap)#), retrying">
		</CFIF>
	</CFIF>
	<CFIF LC EQ 0>
		<CFSET Avg=0>
	<CFELSE>
		<CFSET Avg=Int(Avg / LC)>
	</CFIF>
	<CFIF FileExists(MaxFN) EQ "NO">
		<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
			<CFFILE action="write" file="#MaxFN#" mode="666" output="#Avg#" addnewline="NO">
		</cflock>
	<CFELSE>
		<CFFILE action="read" file="#MaxFN#" variable="MaxAvg">
		<CFIF Avg GT ListFirst(MaxAvg,"|")>
			<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
				<CFFILE action="write" file="#MaxFN#" mode="666" output="#Avg#|#MinRead#|#MaxRead#" addnewline="NO">
			</cflock>
		<!--- <CFELSE>
			<CFSET Avg=MaxAvg> --->
		</CFIF>
	</CFIF>

	<CFRETURN "#Avg#|#MinRead#|#MaxRead#">

</CFFUNCTION>


<CFFUNCTION name="GetLastSpeed" returntype="any">
	<CFARGUMENT name="FN" required="true" type="string">
	<CFSET VAR BytesRead=0>
	<CFSET VAR LastBytesRead=0>
	<CFSET VAR BytesDiff=0>
	<CFSET VAR CurrLine="">
	<CFSET VAR Result="">

	<CFFILE action="read" file="#Arguments.FN#" variable="Results">
	<CFLOOP index="CurrLine" list="#Results#" delimiters="#Chr(13)#">
		<CFIF ListLen(CurrLine," ") GT 1>
			<CFSET BytesRead=ListFirst(CurrLine," ")>
			<CFSET BytesDiff=BytesRead - LastBytesRead>
			<CFSET LastBytesRead=BytesRead>
		</CFIF>
	</CFLOOP>
	<CFRETURN BytesDiff>
</CFFUNCTION>

<CFFUNCTION name="ParseSpotScan" returntype="any">
	<CFARGUMENT name="Results" required="true" type="any">

	<CFSET VAR Results="">
	<CFSET VAR CurrLine="">
	<CFSET VAR LastSpeed=0>

	<CFLOOP index="CurrLine" list="#Arguments.Results#" delimiters="#Chr(13)#">
		<CFIF ListLen(CurrLine) EQ 4>
			<CFIF ListLast(CurrLine," ") NEQ "MB/s">
				<CFSET LastSpeed=0>
			<CFELSE>
				<CFSET LastSpeed=ListFirst(ListLast(CurrLine,",")," ")>
			</CFIF>
		</CFIF>
	</CFLOOP>
	<CFRETURN LastSpeed>

</CFFUNCTION>

<CFFUNCTION name="ParseSurfaceScan" returntype="any">
	<CFARGUMENT name="Blocks" required="true" type="array">
	<CFARGUMENT name="FN" required="true" type="string">
	<CFARGUMENT name="BlockSize" required="true" type="number">
	<CFARGUMENT name="ChunkSize" required="true" type="number">
	<CFARGUMENT name="UpdateExisting" required="true" type="number">

	<CFSET VAR CurrLine="">
	<CFSET VAR BadBlocks="">
	<CFSET VAR i=0>
	<CFSET VAR CurrBlock=0>
	<CFSET VAR LastBlock=0>
	<CFSET VAR EOF=0>
	<CFSET VAR LineCnt=0>
	<CFSET VAR TotalLines=0>
	<CFSET VAR PercentComplete=0>
	<CFSET VAR LastPercentComplete=-1>
	<CFSET VAR FileNamePrefix=ListFirst(GetFileFromPath(Arguments.FN),".")>
	<CFSET VAR BadBlockFlag=0>
	<CFSET VAR BlockOffset=FileNamePrefix * Arguments.ChunkSize>
	<!--- <cfoutput>BlockOffset: [#BlockOffset#]<br></cfoutput> --->

	<CFIF FileExists("#HeatDir#/BadBlocks.txt")>
		<CFFILE action="Read" file="#HeatDir#/BadBlocks.txt" variable="BadBlocks">
	</CFIF>
	<CFFILE action="Read" file="#Arguments.FN#" variable="Results">
	<!--- <CFFILE action="Delete" file="#Arguments.FN#"> --->
	<CFSET Results=Replace(Results,Chr(13),Chr(10),"ALL")>
	<CFSET TotalLines=ListLen(Results,Chr(10))>
	<CFLOOP index="CurrLine" list="#Results#" delimiters="#Chr(10)#">
		<CFSET LineCnt=LineCnt + 1>
		<CFSET PercentComplete=int(LineCnt/TotalLines/0.01)>
		<CFIF PercentComplete NEQ LastPercentComplete>
			<CFSET LastPercentComplete=PercentComplete>
			<CFOUTPUT><script>document.getElementById('Parsing').innerHTML='Parsing scan data block #FileNamePrefix#... (#PercentComplete#%)';</script></CFOUTPUT><CFFLUSH>
		</CFIF>
		<CFIF FindNoCase("error reading",CurrLine)>
			<CFSET BadBlockFlag=1>
		<CFELSE>
			<CFIF FindNoCase("records in",CurrLine)>
				<CFIF Find("+0",CurrLine) AND BadBlockFlag EQ 1>
					<CFSET BadBlockFlag=0>
					<CFSET Block=BlockOffset + ListFirst(CurrLine,"+")>
					<CFIF ListFind(BadBlocks,Block) EQ 0>
						<CFSET BadBlocks=ListAppend(BadBlocks,Block)>
					</CFIF>
				</CFIF>
			</CFIF>
			<CFIF Find("bytes",CurrLine)>
				<CFSET CurrBlock=BlockOffset + Int(ListFirst(CurrLine," ") / Arguments.BlockSize)>
				<CFSET CurrSpeed=ListLast(CurrLine)>
				<CFIF ListLast(CurrSpeed," ") NEQ "MB/s">
					<CFSET CurrSpeed=0>
				<CFELSE>
					<CFSET CurrSpeed=ListFirst(CurrSpeed," ")>
				</CFIF>

				<CFLOOP index="i" from="#LastBlock#" to="#CurrBlock#">
					<CFIF (Arguments.UpdateExisting EQ 0 AND SpeedData[i+1] EQ -1) OR Arguments.UpdateExisting EQ 1>
						<CFSET SpeedData[i+1]=CurrSpeed>
					</CFIF>
				</CFLOOP>
				<CFSET LastBlock=CurrBlock + 1>
			</CFIF>
		</CFIF>
	</CFLOOP>

	<!--- Mark bad blocks --->
	<CFIF BadBlocks NEQ "">
		<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
			<CFFILE action="write" file="#HeatDir#/BadBlocks.txt" output="#BadBlocks#" addnewline="NO" mode="666">
		</cflock>
		<CFLOOP index="CurrBlock" list="#BadBlocks#">
			<CFSET SpeedData[CurrBlock+1]="B">
		</CFLOOP>
	<CFELSE>
		<CFIF FileExists("#HeatDir#/BadBlocks.txt")>
			<CFFILE action="Delete" file="#HeatDir#/BadBlocks.txt">
		</CFIF>
	</CFIF>

	<CFRETURN>
</CFFUNCTION>

<CFFUNCTION name="ShrinkDriveBlocksx" returntype="Any">
	<CFARGUMENT name="GroupCap" required="true" type="number">
	<CFARGUMENT name="DriveBytes" required="true" type="number">
	<CFARGUMENT name="BlockSize" required="true" type="number">

</CFFUNCTION>

<CFFUNCTION name="ShrinkDriveBlocks" returntype="Any">
	<CFARGUMENT name="GroupCap" required="true" type="number">
	<CFARGUMENT name="DriveBytes" required="true" type="number">
	<CFARGUMENT name="BlockSize" required="true" type="number">

	<CFSET VAR GroupSize=int(Arguments.GroupCap/Arguments.BlockSize) + (int(Arguments.DriveBytes/1000000000000)*2)> <!--- Increase group size based on TB size --->
	<!--- <CFSET VAR GroupedBlocks=ArrayNew(1)> --->
	<CFSET VAR GroupedTotal=0>
	<CFSET VAR LineCnt=0>
	<CFSET VAR TotalLines=0>
	<CFSET VAR PercentComplete=0>
	<CFSET VAR LastPercentComplete=-1>
	<CFSET VAR MinSpeed=999999>
	<CFSET VAR MaxSpeed=0>
	<CFSET VAR CurrSpeed=0>
	<CFSET VAR LastBlock=0>
	<CFSET VAR CR=0>
	<CFSET VAR BadBlocks=0>
	<CFSET VAR i=0>

	<!--- Shrink block array down --->
	<CFSET LastBlock=Int(ArrayLen(SpeedData) / GroupSize) * GroupSize>
	<CFSET PercentComplete=0>
	<CFSET LastPercentComplete=-1>
	<CFLOOP index="CR" from="1" to="#LastBlock#" step="#GroupSize#">
		<CFSET PercentComplete=int(CR/LastBlock/0.01)>
		<CFIF LastPercentComplete NEQ PercentComplete>
			<CFOUTPUT><script>document.getElementById('Parsing').innerHTML='Analyzing... (#PercentComplete#%)';</script></CFOUTPUT><CFFLUSH>
			<CFSET LastPercentComplete=PercentComplete>
		</CFIF>
		<CFSET GroupedTotal=0>
		<CFSET BadBlocks=0>
		<CFSET TotalInGroup=0>
		<CFLOOP index="i" from="#CR#" to="#CR+GroupSize#">
			<CFIF SpeedData[i] NEQ -1>
				<CFSET TotalInGroup=TotalInGroup + 1>
				<CFSET GroupedTotal=GroupedTotal + SpeedData[i]>
				<CFIF SpeedData[i] EQ 0>
					<CFSET BadBlocks=1>
				</CFIF>
			</CFIF>
		</CFLOOP>
		<CFIF TotalInGroup EQ 0>
			<CFSET GroupedTotal=-1>
		<CFELSE>
			<CFSET GroupedTotal=int(GroupedTotal / TotalInGroup)>

			<CFIF GroupedTotal LT MinSpeed>
				<CFSET MinSpeed=GroupedTotal>
			</CFIF>
			<CFIF GroupedTotal GT MaxSpeed>
				<CFSET MaxSpeed=GroupedTotal>
			</CFIF>
			<CFIF BadBlocks EQ 1>
				<CFSET GroupedTotal=0>
			</CFIF>
			<CFSET GroupedBlocks[ArrayLen(GroupedBlocks)+1]=GroupedTotal>
		</CFIF>

	</CFLOOP>
	<!--- Average blocks after the last segment --->
	<CFSET LastBlock=LastBlock + GroupSize + 1>
	<CFSET GroupedTotal=0>
	<CFSET BadBlocks=0>
	<CFSET i=0>
	<CFLOOP index="CR" from="#LastBlock#" to="#ArrayLen(SpeedData)#">
		<CFSET i=i+1>
		<CFIF SpeedData[i] EQ "B">
			<CFSET BadBlocks=1>
		<CFELSE>
			<CFSET GroupedTotal=GroupedTotal + SpeedData[i]>
		</CFIF>
	</CFLOOP>
	<CFIF i GT 0>
		<CFSET GroupedTotal=int(GroupedTotal / i)>
		<CFIF BadBlocks EQ 1>
			<CFSET GroupedTotal=0>
		</CFIF>
		<CFIF GroupedTotal LT MinSpeed>
			<CFSET MinSpeed=GroupedTotal>
		</CFIF>
		<CFIF GroupedTotal GT MaxSpeed>
			<CFSET MaxSpeed=GroupedTotal>
		</CFIF>
		<CFSET GroupedBlocks[ArrayLen(GroupedBlocks)+1]=GroupedTotal>
	</CFIF>

	<CFSET MinSpeed=Int(MinSpeed/5)*5>
	<CFSET MaxSpeed=Int(MaxSpeed/5)*5+5>

	<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
		<CFFILE action="write" file="#HeatDir#/MinSpeed.txt" output="#MinSpeed#" addnewline="NO" mode="666">
		<CFFILE action="write" file="#HeatDir#/MaxSpeed.txt" output="#MaxSpeed#" addnewline="NO" mode="666">
	</cflock>

	<CFRETURN>

</CFFUNCTION>


<CFFUNCTION name="BuildSpeedMap" returntype="any">
	<!--- <CFARGUMENT name="Blocks" required="true" type="Array"> --->
	<CFARGUMENT name="BlocksWide" required="true" type="Number">
	<CFARGUMENT name="BlockSize" required="true" type="number">
	<CFARGUMENT name="GroupCap" required="true" type="number">
	<CFARGUMENT name="DriveBytes" required="true" type="number">

	<CFSET VAR X=0>
	<CFSET VAR Y=0>
	<CFSET VAR Map1="">
	<CFSET VAR Map2="">
	<CFSET VAR i=0>
	<CFSET VAR GroupSize=int(Arguments.GroupCap/Arguments.BlockSize) + (int(Arguments.DriveBytes/1000000000000)*2)> <!--- Increase group size based on TB size --->
	<CFSET VAR BlockBytes=0>
	<CFSET VAR PercentComplete=0>
	<CFSET VAR LastPercentComplete=-1>
	<CFSET VAR TotalBlocks=ArrayLen(SpeedData)>
	<CFSET VAR LastSpeed=-1>

	<CFLOOP index="i" FROM="1" to="#TotalBlocks#">
		<CFSET PercentComplete=int(i/TotalBlocks/0.01)>
		<CFIF PercentComplete NEQ LastPercentComplete>
			<CFSET LastPercentComplete=PercentComplete>
			<CFOUTPUT><script>document.getElementById('Parsing').innerHTML='Building Heatmap Data... (#PercentComplete#%)';</script></CFOUTPUT><CFFLUSH>
		</CFIF>
		<CFIF SpeedData[i] NEQ -1>
			<CFSET UseSpeed=LastSpeed>
		<CFELSE>
			<CFSET UseSpeed=SpeedData[i]>
			<CFSET LastSpeed=UseSpeed>
		</CFIF>
		<CFSET Y=int((i-1)/Arguments.BlocksWide)>
		<CFSET X=(i-1)-Y*Arguments.BlocksWide>
		<CFSET BlockBytes=i*GroupSize*Arguments.BlockSize>
		<CFIF UseSpeed EQ "B">
			<CFSET Map1=ListAppend(Map1,"{x:#X#,y:#Y#,value:null,l:'#KBytes(BlockBytes)#',b:1}")>
		<CFELSE>
			<CFSET Map1=ListAppend(Map1,"{x:#X#,y:#Y#,value:#SpeedData[i]#,b:0,l:'#KBytes(BlockBytes)#'}")>
		</CFIF>
		<CFIF Len(Map1) GT 102400>
			<CFSET Map2=ListAppend(Map2,Map1) & Chr(10)>
			<CFSET Map1="">
		</CFIF>
	</CFLOOP>
	<CFSET Map2=ListAppend(Map2,Map1)>

	<CFRETURN Map2>

</CFFUNCTION>


<CFFUNCTION name="Old2ParseSurfaceScan" returntype="any">
	<CFARGUMENT name="Blocks" required="true" type="Query">
	<CFARGUMENT name="FN" required="true" type="string">
	<CFARGUMENT name="BlockSize" required="true" type="number">
	<CFSET VAR CurrLine="">
	<CFSET VAR Result=ArrayNew(1)>
	<CFSET VAR CurrBlock="">
	<CFSET VAR CurrSpeed="">
	<CFSET VAR Block=0>
	<CFSET VAR StartBlock=0>
	<CFSET VAR Duration=0>
	<CFSET VAR LastSpeed=-1>
	<CFSET VAR EOF=0>
	<CFSET VAR i=0>
	<CFSET VAR BlockOffset=ListFirst(GetFileFromPath(Arguments.FN),".") * Arguments.BlockSize>

	<CFFILE action="read" file="#Arguments.FN#" variable="Results">
	<CFLOOP index="CurrLine" list="#Results#" delimiters="#Chr(13)#">
		<CFIF FindNoCase("records in",CurrLine)>
			<CFIF Find("+0",CurrLine)>
				<CFSET Block=BlockOffset + ListFirst(CurrLine,"+")>
				<CFIF Blocks.Start[Blocks.RecordCount] NEQ Block>
					<CFSET QueryAddRow(Blocks)>
					<CFSET QuerySetCell(Blocks,"Start",StartBlock)>
					<CFSET QuerySetCell(Blocks,"End",Block)>
					<CFSET QuerySetCell(Blocks,"Speed",0)>
					<CFSET StartBlock=Block + 1>
				</CFIF>
			<CFELSEIF Find("+1",CurrLine)>
				<CFSET EOF=1>
			</CFIF>
		</CFIF>
		<CFIF Find("bytes",CurrLine)>
			<CFIF EOF EQ 1>
				<CFSET Duration=Int(ListGetAt(CurrLine,ListLen(CurrLine," ")-3," "))>
			<CFELSE>
				<CFSET CurrBlock=BlockOffset + Int(ListFirst(CurrLine," ") / Arguments.BlockSize)>
				<CFSET CurrSpeed=ListLast(CurrLine)>
				<CFIF ListLast(CurrSpeed," ") NEQ "MB/s">
					<CFSET CurrSpeed=0>
				<CFELSE>
					<CFSET CurrSpeed=ListFirst(CurrSpeed," ")>
				</CFIF>
				<CFIF LastSpeed EQ -1>
					<CFSET LastSpeed=CurrSpeed>
				<CFELSE>
					<CFIF CurrSpeed NEQ LastSpeed>
						<CFSET i=Blocks.RecordCount>
						<CFIF Blocks.Start[i] LT StartBlock>
							<CFSET QueryAddRow(Blocks)>
							<CFSET QuerySetCell(Blocks,"Start",StartBlock)>
							<CFSET QuerySetCell(Blocks,"End",CurrBlock)>
							<CFSET QuerySetCell(Blocks,"Speed",LastSpeed)>
						</CFIF>
						<CFSET StartBlock=CurrBlock + 1>
						<CFSET LastSpeed=CurrSpeed>
					</CFIF>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>
	<CFSET Result[1]=Blocks>
	<CFSET Result[2]=Duration>
	<CFRETURN Result>
</CFFUNCTION>

<CFFUNCTION name="OldBuildSpeedMap" returntype="any">
	<CFARGUMENT name="Blocks" required="true" type="Query">
	<CFARGUMENT name="BlocksWide" required="true" type="Number">
	<CFSET VAR X=0>
	<CFSET VAR Y=0>
	<CFSET VAR Map1="">
	<CFSET VAR Map2="">
	<CFSET VAR CR=0>
	<CFSET VAR i=0>
	<CFSET VAR BlockStart=0>
	<CFSET VAR BlockEnd=0>
	<CFSET VAR BlockSpeed=0>

	<CFLOOP index="CR" from="1" to="#Blocks.RecordCount#">
		<CFSET BlockStart=Arguments.Blocks.Start[CR]>
		<CFSET BlockEnd=Arguments.Blocks.End[CR]>
		<CFSET BlockSpeed=Arguments.Blocks.Speed[CR]>
		<CFLOOP index="i" FROM="#BlockStart#" to="#BlockEnd#">
			<CFSET Y=int(i/Arguments.BlocksWide)>
			<CFSET X=i-Y*Arguments.BlocksWide>
			<CFSET Map1=ListAppend(Map1,"[#X#,#Y#,#BlockSpeed#]")>
			<CFIF Len(Map1) GT 102400>
				<CFSET Map2=ListAppend(Map2,Map1)>
				<CFSET Map1="">
			</CFIF>
		</CFLOOP>
		<CFSET Map2=ListAppend(Map2,Map1)>
	</CFLOOP>

	<CFRETURN Map2>

</CFFUNCTION>

<CFFUNCTION name="OldParseSurfaceScan" returntype="any">
	<CFARGUMENT name="FN" required="true" type="string">
	<CFSET VAR Speed="">
	<CFSET VAR MBReadSec=0>
	<CFSET VAR CurrLine="">
	<CFSET VAR Result=ArrayNew(1)>
	<CFSET VAR CurrDuration=0>
	<CFSET VAR LastDuration=0>
	<CFSET VAR Duration=0>
	<CFSET VAR i=0>

	<CFFILE action="read" file="#Arguments.FN#" variable="Results">
	<CFSET Results=Left(Results,Find("+0",Results)-3)>
	<CFLOOP index="CurrLine" list="#Results#" delimiters="#Chr(13)#">
		<!--- <cfoutput>[#CurrLine#]<br></cfoutput> --->
		<CFIF ListLen(CurrLine," ") GT 1>
			<CFIF Find("records in",CurrLine)>
				<CFBREAK>
			</CFIF>
			<CFSET MBReadSec=0>
			<CFSET Speed=Trim(ListLast(CurrLine,","))>
			<CFIF ListLast(Speed," ") EQ "MB/s">
				<CFSET MBReadSec=Val(ListFirst(Speed," "))>
			</CFIF>
			<CFSET CurrDuration=ListFirst(ListGetAt(CurrLine,ListLen(CurrLine,",")-1,",")," ")>
			<CFSET Duration=CurrDuration - LastDuration>
			<CFSET LastDuration=CurrDuration>
			<CFSET i=i+1>
			<CFSET Result[i][1]=MBReadSec>
			<CFSET Result[i][2]=Duration>
		</CFIF>
	</CFLOOP>
	<CFRETURN Result>
</CFFUNCTION>


<CFFUNCTION name="GetTotalBytesRead" returntype="any">
	<CFARGUMENT name="FN" required="true" type="string">
	<CFSET VAR BytesRead=0>
	<CFSET VAR TotalBytesRead=0>
	<CFSET VAR CurrLine="">

	<CFFILE action="read" file="#Arguments.FN#" variable="Results">
	<CFLOOP index="CurrLine" list="#Results#" delimiters="#Chr(13)#">
		<CFIF ListLen(CurrLine," ") GT 1>
			<CFSET BytesRead=ListFirst(CurrLine," ")>
			<CFSET TotalBytesRead=TotalBytesRead + BytesRead>
		</CFIF>
	</CFLOOP>
	<CFRETURN TotalBytesRead>
</CFFUNCTION>


<CFFUNCTION name="JSONQuerytoCFQuery" returntype="query" output="true">
	<CFARGUMENT name="Q" required="true" type="struct">
	<CFARGUMENT name="FieldTypes" required="true" type="string">

	<CFSET VAR RetQ="">
	<CFSET VAR ColList="">
	<CFSET VAR i=0>
	<CFSET VAR c=0>
	<CFSET VAR Cell="">

	<CFLOOP index="i" from="1" to="#ArrayLen(Arguments.Q.Columns)#">
		<CFSET ColList=ListAppend(ColList,Arguments.Q.Columns[i])>
	</CFLOOP>
	<CFSET RetQ=QueryNew(ColList,Arguments.FieldTypes)>
	<CFLOOP index="i" from="1" to="#ArrayLen(Arguments.Q.Data)#">
		<CFSET QueryAddRow(RetQ)>
		<CFLOOP index="c" from="1" to="#ListLen(ColList)#">
			<CFSET Cell=ListGetAt(ColList,c)>
			<CFSET QuerySetCell(RetQ,Cell,Arguments.Q.Data[i][c])>
		</CFLOOP>
	</CFLOOP>

	<CFRETURN RetQ>

</CFFUNCTION>


<CFFUNCTION name="CFExecuteBash" returntype="any" output="true">
	<CFARGUMENT name="Name" required="true" type="string">
	<CFARGUMENT name="Arguments" required="true" type="string">
	<CFARGUMENT name="timeout" required="true" type="numeric">

	<CFSET VAR FN="/tmp/DiskSpeed/run/" & GetTickCount() & ".sh">
	<CFSET VAR O="#Arguments.Name# #Arguments.Arguments#" & Chr(10) & "rm #FN#" & Chr(10)>
	<CFSET VAR Result="">

	<CFFILE action="WRITE" file="#FN#" output="#O#" mode="766" addnewline="NO">
	<CFEXECUTE name="#FN#" timeout="#Arguments.Timeout#" variable="Result" />
	<CFRETURN Result>
</CFFUNCTION>

<CFFUNCTION name="ExecuteBash" returntype="any" output="true">
	<CFARGUMENT name="CMD" required="true" type="Array">

	<CFSET VAR i=0>
	<CFSET VAR Script="">
	<CFSET VAR CurrCmd="">
	<CFSET VAR FN="/tmp/DiskSpeed/run/" & GetTickCount() & ".sh">

	<CFLOOP index="i" from="1" to="#ArrayLen(Arguments.CMD)#">
		<CFSET CurrCmd=Arguments.CMD[i]>
		<CFSET Script=Script & "echo ""Executing command ###i#""" & Chr(10)>
		<CFSET Script=Script & "#CurrCmd# &" & Chr(10)>
		<CFSET Script=Script & "PID_#i#=$!" & Chr(10)>
	</CFLOOP>
	<CFLOOP index="i" from="1" to="#ArrayLen(Arguments.CMD)#">
		<CFSET Script=Script & "echo ""Waiting for command ###i# to finish""" & Chr(10)>
		<CFSET Script=Script & "wait $PID_#i#" & Chr(10)>
	</CFLOOP>
	<CFSET Script=Script & "echo ""Batch complete""" & Chr(10)>
	<CFSET Script=Script & "rm #FN#" & Chr(10)>

	<CFFILE action="WRITE" file="#FN#" output="#Script#" mode="766" addnewline="NO">
	<CFEXECUTE name="#FN#" timeout="999" />

	<CFRETURN "">
</CFFUNCTION>

<CFSET Config=StructNew()>
<CFSET Config["var"]=StructNew()>
<CFSET Config.Disks=StructNew()>
<CFSET RunningUNRAID=0>
<CFIF DirectoryExists("/var/local/emhttp")>
	<CFSET RunningUNRAID=1>
	<CFDIRECTORY action="list" directory="/var/local/emhttp" type="file" filter="*.ini" name="dir" sort="name">
	<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
		<CFIF ListFindNoCase("disks.ini,var.ini",Dir.Name[cr])>
			<CFSET ININame=ListDeleteAt(Dir.Name[CR],ListLen(Dir.Name[CR],"."),".")>
			<CFSET Config[ININame]=StructNew()>
			<CFFILE action="read" file="/var/local/emhttp/#Dir.Name[CR]#" variable="Data">
			<CFSET Sub=StructNew()>
			<CFSET SubName="">
			<CFLOOP index="CurrLine" list="#Data#" delimiters="#Chr(10)#">
				<CFIF Left(CurrLine,1) EQ "[">
					<CFIF NOT StructIsEmpty(Sub)>
						<CFSET Config[ININame][SubName]=Sub>
					</CFIF>
					<CFSET SubName=Replace(Mid(CurrLine,2,Len(CurrLine)-2),Chr(34),"","ALL")>
					<CFSET Sub=StructNew()>
				<CFELSE>
					<CFSET ConfigName=ListFirst(CurrLine,"=")>
					<CFSET ConfigVal=Trim(ListDeleteAt(CurrLine,1,"="))>
					<CFIF Left(ConfigVal,1) EQ Chr(34) AND Right(ConfigVal,1) EQ Chr(34)>
						<CFSET ConfigVal=Mid(ConfigVal,2,Len(ConfigVal)-2)>
					</CFIF>
					<CFSET Sub[ConfigName]=ConfigVal>
				</CFIF>
			</CFLOOP>
			<CFIF NOT StructIsEmpty(Sub)>
				<CFIF SubName NEQ "">
					<CFSET Config[ININame][SubName]=Sub>
				<CFELSE>
					<CFSET Config[ININame]=Sub>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFIF>

<CFFUNCTION name="CSSName" returntype="string" output="true">
	<CFARGUMENT name="Text" required="true" type="string">

	<CFSET VAR txt=Arguments.Text>
	<CFSET VAR Invalid="~!@$%^&*()_+-=,./';:""?><[]{}|`##">
	<CFSET VAR RetTxt="hd_">
	<CFSET VAR i=0>
	<CFSET VAR C="">

	<CFLOOP index="i" from="1" to="#Len(txt)#">
		<CFSET C=Mid(txt,i,1)>
		<CFIF Find(C,Invalid)>
			<CFSET RetTxt=RetTxt & "_">
		<CFELSE>
			<CFSET RetTxt=RetTxt & C>
		</CFIF>
	</CFLOOP>
	<CFSET RetTxt=Replace(RetTxt," ","_","ALL")>

	<CFRETURN RetTxt>
</CFFUNCTION>

<CFFUNCTION name="ConTree" returntype="any" output="true">
	<CFARGUMENT name="Tree" required="true" type="Struct">
	<CFARGUMENT name="Key" required="true" type="Any">

	<CFSET VAR Keys="">
	<CFSET VAR Loc=0>
	<CFSET VAR CurrKey="">
	<CFSET VAR SubCall="">

	<CFOUTPUT>
	<tr>
		<td colspan="2" valign="top" class="Arial Size12 NOBR">
			<CFIF StructKeyExists(Arguments.Tree,"Desc")>
				#Arguments.Tree.Desc#
			<CFELSE>
				No Desc
			</CFIF>
			<CFIF StructKeyExists(Arguments.Tree,"TotalDrives")>
				<br>
				&nbsp;&nbsp;&nbsp;&nbsp;<span class="Bold">#HW[Arguments.Key].TotalDrives# Drive<CFIF HW[Arguments.Key].TotalDrives NEQ 1>s</CFIF></span>
			</CFIF>
			<!---
			<CFIF StructKeyExists(HW,Arguments.Key)>
				<CFIF HW[Arguments.Key].TotalDrives GT 1>
					-
					<CFIF HW[Arguments.Key].ControllerOptimized EQ 0>
						Controller has not been tested for bandwidth optimization <a href="TestControllerBandwidth.cfm?controller=#URLEncodedFormat(Arguments.Key)#">[test]</a>
					<CFELSE>
						#HW[Arguments.Key].MaxReadDrives# drive<CFIF HW[Arguments.Key].MaxReadDrives NEQ 1>s</CFIF> will be simultaneously tested
					</CFIF>
				</CFIF>
			</CFIF>
			--->
		</td>
	</tr>
	</CFOUTPUT>
	<CFSET Keys=StructKeyList(Arguments.Tree)>
	<CFSET Loc=ListFindNoCase(Keys,"Desc")>
	<CFIF Loc GT 0>
		<CFSET Keys=ListDeleteAt(Keys,Loc)>
	</CFIF>
	<CFSET Loc=ListFindNoCase(Keys,"TotalDrives")>
	<CFIF Loc GT 0>
		<CFSET Keys=ListDeleteAt(Keys,Loc)>
	</CFIF>
	<CFLOOP index="CurrKey" list="#Keys#">
		<CFOUTPUT>
		<tr>
			<CFIF CurrKey NEQ ListLast(Keys) AND ListLen(Keys) GT 1>
				<td class="Nav2"></td>
			<CFELSE>
				<td class="Nav3"></td>
			</CFIF>
			<td valign="top"><table border="0" cellpadding="0" cellspacing="0">
		</CFOUTPUT>
		<CFSET SubCall=Duplicate(Arguments.Tree[CurrKey])>
		<cftry>
		<CFSET ConTree(SubCall,CurrKey)>
		<cfcatch type="any"><cfdump var=#subcall#><cfabort></cfcatch>
		</cftry>
		<CFOUTPUT>
			</table></td>
		</tr>
		</CFOUTPUT>
	</CFLOOP>

</CFFUNCTION>

<CFFUNCTION name="ReadFile" returntype="string">
	<CFARGUMENT name="FN" required="true" type="string">
	<CFARGUMENT name="Default" required="False" type="string" default="">
	<CFSET var Out="">
	<CFIF FileExists(Arguments.FN)>
		<CFFILE action="Read" file="#Arguments.FN#" variable="Out">
		<CFRETURN Out>
	<CFELSE>
		<CFRETURN Arguments.Default>
	</CFIF>
</CFFUNCTION>

<CFFUNCTION name="FlatFileToQuery" returntype="query">
	<CFARGUMENT name="txt" required="true" type="string">
	<CFSET var Columns="">
	<CFSET var CurrCol="">
	<CFSET var CurrLine="">
	<CFSET var Fields=ArrayNew(1)>
	<CFSET var i=0>
	<CFSET var CR=0>
	<CFSET var Pos=1>
	<CFSET var QFields="">
	<CFSET var Out="">

	<!--- Identify flat file field lengths --->
	<CFLOOP index="CurrCol" list="#ListGetAt(Arguments.Txt,2,Chr(10))#" delimiters=" ">
		<CFSET i=i+1>
		<CFSET Fields[i]=StructNew()>
		<CFSET Fields[i].Start=Pos>
		<CFSET Fields[i].Length=Len(CurrCol)>
		<CFSET Fields[i].Name=Trim(Mid(ListFirst(Arguments.Txt,Chr(10)),Pos,Len(CurrCol)))>
		<CFSET QFields=ListAppend(QFields,Fields[i].Name)>
		<CFSET Pos=Pos + Len(CurrCol) + 1>
	</CFLOOP>

	<CFSET Out=QueryNew(QFields)>
	<CFLOOP index="CR" from="3" to="#ListLen(Arguments.txt,Chr(10))#">
		<CFSET QueryAddRow(Out)>
		<CFSET CurrLine=ListGetAt(Arguments.txt,CR,Chr(10))>
		<CFLOOP index="i" from="1" to="#ArrayLen(Fields)#">
			<CFSET QuerySetCell(Out,Fields[i].Name,Trim(Mid(CurrLine,Fields[i].Start,Fields[i].Length)))>
		</CFLOOP>
	</CFLOOP>

	<CFRETURN Out>
</CFFUNCTION>

<CFFUNCTION name="ColumnsToStruct" returntype="struct" output="true">
	<CFARGUMENT name="txt" required="true" type="string">
	<CFSET var Out=StructNew()>
	<CFSET var CurrLine="">
	<CFSET var Col="">

	<CFLOOP index="CurrLine" list="#Arguments.txt#" delimiters="#Chr(10)#">
		<CFSET Out[Trim(ListFirst(CurrLine,":"))]=Trim(ListDeleteAt(CurrLine,1,":"))>
	</CFLOOP>

	<CFRETURN Out>
</CFFUNCTION>

<cffunction name="IsUnicode" returntype="Any">
    <cfargument name="Txt" required="true" type="string">

    <CFSET VAR CR=0>
    <CFSET VAR Return=0>

    <CFLOOP index="CR" from="1" to="#Len(Arguments.Txt)#">
        <CFIF Asc(Mid(Arguments.Txt,CR,1)) GT 126>
            <CFSET Return=1>
            <CFBREAK>
        </CFIF>
    </CFLOOP>

    <CFRETURN Return>
</cffunction>




<cffunction name="BashLS" returntype="Any">
    <cfargument name="Dir" required="true" type="string">

	<CFSET VAR LS="">
	<CFSET VAR Ret=QueryNew("Type,Name,Size,Date,Link","varchar,varchar,integer,date,varchar")>
	<CFSET VAR CurrLine="">
	<CFSET VAR Loc=0>
	<CFSET VAR tmp1="">
	<CFSET VAR tmp2="">
	<CFSET VAR tmpDate=Now()>
	<CFSET VAR LinkPath="">

	<cfexecute name="/bin/ls" arguments="-lgo --full-time #Arguments.Dir#" variable="LS" timeout="10" />
	<!--- <cfoutput><pre>#ls#</pre></cfoutput> --->

	<CFLOOP index="CurrLine" list="#LS#" delimiters="#Chr(10)#">
		<CFIF ListFirst(CurrLine," ") NEQ "total">
			<CFSET QueryAddRow(Ret)>
			<CFSET QuerySetCell(Ret,"Type",Left(CurrLine,1))>
			<CFSET tmp1=ListGetAt(CurrLine,4," ")>
			<CFSET tmp2=ListFirst(ListGetAt(CurrLine,5," "),".")>
			<CFSET tmpDate=CreateDateTime(ListFirst(tmp1,"-"),ListGetAt(tmp1,2,"-"),ListLast(tmp1,"-"),ListFirst(tmp2,":"),ListGetAt(tmp2,2,":"),ListLast(tmp2,":"))>
			<CFSET QuerySetCell(Ret,"Date",tmpDate)>


			<CFSET CurrLine=ListDeleteAt(CurrLine,1," ")>
			<CFSET CurrLine=ListDeleteAt(CurrLine,1," ")>
			<CFSET CurrLine=ListDeleteAt(CurrLine,1," ")>
			<CFSET CurrLine=ListDeleteAt(CurrLine,1," ")>
			<CFSET CurrLine=ListDeleteAt(CurrLine,1," ")>
			<CFSET CurrLine=ListDeleteAt(CurrLine,1," ")>

			<CFSET Loc=Find("->",CurrLine)>
			<CFIF Loc EQ 0>
				<CFSET QuerySetCell(Ret,"Name",CurrLine)>
			<CFELSE>
				<CFSET QuerySetCell(Ret,"Name",Left(CurrLine,Loc-2))>
				<CFSET Link=Mid(CurrLine,Loc+3,Len(CurrLine))>
				<CFSET OK=0>
				<CFSET LinkPath=Arguments.Dir>
				<CFLOOP condition="NOT OK">
					<CFIF ListFirst(Link,"/") EQ "..">
						<CFSET LinkPath=ListDeleteAt(LinkPath,ListLen(LinkPath,"/"),"/")>
						<CFSET Link=ListDeleteAt(Link,1,"/")>
					<CFELSE>
						<CFSET OK=1>
					</CFIF>
				</CFLOOP>
				<CFSET QuerySetCell(Ret,"Link",LinkPath & "/" & Link)>
			</CFIF>
		</CFIF>
	</CFLOOP>

	<CFRETURN Ret>
</cffunction>

<cffunction name="ParseUSB" returntype="Any">
    <cfargument name="Dir" required="true" type="string">
    <cfargument name="Bus" required="false" type="numeric" default="0">

	<CFSET VAR Dir="">
	<CFSET VAR PortInfo=StructNew()>
	<CFSET VAR LSUSB="">
	<CFSET VAR CurrLine="">
	<CFSET VAR Line="">
	<CFSET VAR VarName="">
	<CFSET VAR VarValue="">
	<CFSET VAR PortDir="">
	<CFSET VAR PortNo=0>
	<CFSET VAR Loc=0>
	<CFSET VAR PortIdx=0>
	<CFSET VAR Devices="">
	<CFSET VAR DeviceIdx=0>
	<CFSET VAR BlockDir="">
	<CFSET VAR BlockDirlist="">
	<CFSET VAR DriveID="">

	<CFIF Arguments.Bus EQ 0>
		<CFSET Arguments.Bus=Right(Arguments.Dir,1)>
	</CFIF>
	<CFSET PortInfo.Path=Arguments.Dir>
	<CFSET PortInfo.bInterfaceClass="">

	<CFSET PortInfo.Ports=ArrayNew(1)>

	<CFDIRECTORY action="list" directory="#Arguments.Dir#" name="Dir" filter="*:1.0">
	<CFIF Dir.RecordCount NEQ 0>
		<!--- Hub --->
		<CFSET PortInfo.MaxPower=StripCRLF(ReadFile("#Arguments.Dir#/bMaxPower"))>
		<CFSET PortInfo.DevNum=StripCRLF(ReadFile("#Arguments.Dir#/devnum"))>
		<CFSET PortInfo.Removable=StripCRLF(ReadFile("#Arguments.Dir#/removable"))>
		<CFSET PortInfo.Speed=StripCRLF(ReadFile("#Arguments.Dir#/speed"))>
		<CFSET PortInfo.Version=StripCRLF(ReadFile("#Arguments.Dir#/version"))>

		<!--- Get LSUSB info --->
		<CFTRY>
			<cfexecute name="/usr/bin/lsusb" arguments="-v -s #Arguments.Bus#:#PortInfo.DevNum#" variable="LSUSB" timeout="30" />
		<CFCATCH Type="Any">
			<CFSET LSUSB="">
			<CFSET PortInfo.idVendor="Unable to Determine">
			<CFSET PortInfo.idProduct="Unable to Determine">
			<CFSET PortInfo.iProduct="Unable to Determine">
			<CFSET PortInfo.iManufacturer="">
			<CFSET PortInfo.bInterfaceClass="Unable to Determine">
			<CFSET PortInfo.bInterfaceProtocol="Unable to Determine">
		</CFCATCH>
		</CFTRY>
		<!--- <cfoutput>lsusb -v -s #Arguments.Bus#:#PortInfo.DevNum#<pre>#lsusb#</pre><hr></cfoutput> --->
		<CFLOOP index="Line" list="#LSUSB#" delimiters="#Chr(10)#">
			<CFSET CurrLine=Trim(Line)>
			<CFSET VarName=ListFirst(CurrLine," ")>
			<CFIF ListFindNoCase("idVendor,idProduct,iProduct,iManufacturer,bInterfaceClass,bInterfaceProtocol",VarName)>
				<CFSET VarValue=ListDeleteAt(CurrLine,1," ")>
				<CFSET VarValue=ListDeleteAt(VarValue,1," ")>
				<CFIF VarName EQ "iManufacturer" AND ListFindNoCase("Generic,Unknown",VarValue)>
					<CFSET VarValue="">
				</CFIF>
				<CFSET PortInfo[VarName]=VarValue>
			</CFIF>
		</CFLOOP>
		<CFIF PortInfo.bInterfaceClass EQ "Hub">
			<!--- Get Ports --->
			<CFDIRECTORY action="list" directory="#Arguments.Dir#/#Dir.Name#" name="PortDir" filter="*-port*" sort="name">
			<CFLOOP index="PortIdx" from="1" to="#PortDir.RecordCount#">
				<CFSET Loc=FindNoCase("-port",PortDir.Name[PortIdx]) + 5>
				<CFSET PortNo=Mid(PortDir.Name[PortIdx],Loc,99)>
				<CFDIRECTORY action="list" directory="#Arguments.Dir#/#Dir.Name#/#PortDir.Name[PortIdx]#" name="Devices" type="dir" sort="name" listinfo="all">
				<CFSET Devices=BashLS("#Arguments.Dir#/#Dir.Name#/#PortDir.Name[PortIdx]#")>
				<CFLOOP index="DeviceIdx" from="1" to="#Devices.RecordCount#">
					<CFIF Devices.Name[DeviceIdx] EQ "device">
						<CFSET PortInfo.Ports[PortNo]=ParseUSB(Devices.Link[DeviceIdx],Arguments.Bus)>
					</CFIF>
					<CFIF Devices.Name[DeviceIdx] EQ "peer">
						<CFSET PortInfo.Ports[PortNo].Peer=Devices.Link[DeviceIdx]>
					</CFIF>
				</CFLOOP>
				<CFSET PortInfo.Ports[PortNo].PortNo=PortNo>
				<CFIF FileExists("#Arguments.Dir#/#Dir.Name#/#PortDir.Name[PortIdx]#/connect_type")>
					<CFSET PortInfo.Ports[PortNo].ConnectType=StripCRLF(ReadFile("#Arguments.Dir#/#Dir.Name#/#PortDir.Name[PortIdx]#/connect_type"))>
				</CFIF>
				<CFIF StructKeyExists(PortInfo.Ports[PortNo],"bInterfaceClass")>
					<CFSWITCH expression="#PortInfo.Ports[PortNo].bInterfaceClass#">
						<CFCASE value="Mass Storage">
							<CFSET DriveID="">
							<CFEXECUTE name="/usr/bin/find" arguments="#PortInfo.Ports[PortNo].Path# -name block" variable="BlockDir" timeout="30" />
							<CFSET BlockDir=StripCRLF(BlockDir)>
							<CFIF BlockDir NEQ "">
								<CFDIRECTORY action="list" directory="#BlockDir#" Name="BlockDirlist">
								<CFSET DriveID=BlockDirlist.Name>
							</CFIF>
							<CFSET PortInfo.Ports[PortNo].DriveID=DriveID>
						</CFCASE>
					</CFSWITCH>
				</CFIF>
			</CFLOOP>
		</CFIF>
	</CFIF>

	<CFIF ArrayLen(PortInfo.Ports) EQ 0>
		<CFSET StructDelete(PortInfo,"Ports")>
	<CFELSE>
		<!--- Delete empty ports --->
		<CFSET PortInfo.TotalPorts=ArrayLen(PortInfo.Ports)>
		<CFLOOP index="PortNo" from="#ArrayLen(PortInfo.Ports)#" to="1" step="-1">
			<CFIF StructKeyExists(PortInfo.Ports[PortNo],"bInterfaceClass") EQ "NO">
				<CFSET ArrayDeleteAt(PortInfo.Ports,PortNo)>
			</CFIF>
		</CFLOOP>
	</CFIF>

	<CFRETURN PortInfo>

</cffunction>

<cffunction name="LoadJSONFile" returntype="Any">
    <cfargument name="FilePath" required="true" type="string">

	<CFSET VAR Data="">

	<CFIF FileExists(Arguments.FilePath) EQ "NO">
		<CFRETURN "-2">
	</CFIF>

	<CFFILE action="read" file="#Arguments.FilePath#" variable="Data">

	<CFTRY>
		<CFRETURN DeserializeJSON(Data)>
	<CFCATCH Type="Any">
	</CFCATCH>
	</CFTRY>

	<CFRETURN "{}">

</cffunction>

<CFFUNCTION name="DeleteTestFiles">
	<CFARGUMENT name="MountPoint" type="string" required="false" default="">

	<CFSET VAR Dir="">
	<CFSET VAR CR=0>
	<CFSET VAR Key="">
	<CFSET VAR PortNo=0>
	<CFSET VAR MP="">
	<CFSET VAR PartID=0>

	<CFIF Arguments.MountPoint EQ "">
		<CFLOOP index="Key" list="#StructKeyList(HW)#">
			<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
				<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
					<CFLOOP index="PartID" from="1" to="#ArrayLen(HW[Key].Ports[PortNo].Partitions.Partitions)#">
						<CFSET MP=HW[Key].Ports[PortNo].Partitions.Partitions[PartID].MountPoint>
						<CFIF MP NEQ "">
							<CFDIRECTORY action="List" directory="#MP#" type="File" filter="DiskSpeedTestFile*.*" name="Dir">
							<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
								<CFTRY>
									<CFFILE action="delete" file="#MP#/#Dir.Name[CR]#">
								<CFCATCH Type="Any">
								</CFCATCH>
								</CFTRY>
							</CFLOOP>
						</CFIF>
					</CFLOOP>
				</CFIF>
			</CFLOOP>
		</CFLOOP>
	<CFELSE>
		<CFDIRECTORY action="List" directory="#Arguments.MountPoint#" type="File" filter="DiskSpeedTestFile*.*" name="Dir">
		<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
			<CFTRY>
				<CFFILE action="delete" file="#Arguments.MountPoint#/#Dir.Name[CR]#">
			<CFCATCH Type="Any">
			</CFCATCH>
			</CFTRY>
		</CFLOOP>
	</CFIF>
</CFFUNCTION>

<CFFUNCTION name="FlushTestFiles">
	<CFARGUMENT name="MountPoint" type="string" required="false" default="">
	<CFSET VAR Dir="">
	<CFSET VAR CR=0>

	<CFDIRECTORY action="List" directory="#Arguments.MountPoint#" type="File" filter="DiskSpeedTestFile*.*" name="Dir">
	<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
		<CFTRY>
			<cfexecute name="/bin/sync" arguments="#Arguments.MountPoint#/#Dir.Name[CR]#" timeout="90" />
		<CFCATCH Type="Any">
		</CFCATCH>
		</CFTRY>
	</CFLOOP>
</CFFUNCTION>

<CFFUNCTION name="CountRange">
	<!--- Returns total represented such as "1,2,4-8" = 10 --->
	<CFARGUMENT name="Ranges" type="string" required="true">

	<CFSET VAR Total=0>
	<CFSET VAR i=0>
	<CFSET VAR Range="">
	<CFSET VAR Start=0>
	<CFSET VAR ENd=0>
	<CFSET VAR i2=0>
	<CFLOOP index="i" from="1" to="#ListLen(Arguments.Ranges)#">
		<CFSET Range=ListGetAt(Arguments.Ranges,i)>
		<CFIF ListLen(Range,"-") EQ 1>
			<CFSET Total=Total + 1>
		<CFELSE>
			<CFSET Start=ListFirst(Range,"-")>
			<CFSET End=ListLast(Range,"-")>
			<CFLOOP index="i2" from="#Start#" to="#End#">
				<CFSET Total=Total + 1>
			</CFLOOP>
		</CFIF>
	</CFLOOP>
	<CFRETURN Total>
</CFFUNCTION>

<CFFUNCTION Name="CheckDockerCPUCount">
	<CFSET VAR Ret="">
	<CFSAVECONTENT variable="Ret">
	<CFOUTPUT>
	<CFIF DockerInfo.CPU.Total EQ 0>
		<CFIF DockerInfo.CPU.Assigned LT 4>
			<span class="Red">
			<br>
			WARNING: You have #DockerInfo.CPU.Assigned# CPUs assigned to the DiskSpeed Docker app. The Solid State benchmark requires 4 CPU
			threads in order to get an accurate benchmark. Solid State Benchmarking is not available.<br>
			</span>
			<script>document.getElementById('SkipSSD').disabled=true;</script>
		</CFIF>
	<CFELSE>
		<CFIF DockerInfo.CPU.Total LT 4>
			<span class="Red">
			<br>
			WARNING: You have less than 4 CPUs available (#DockerInfo.CPU.Assigned# total). The Solid State benchmark requires 4 CPU threads in order to get an accurate benchmark.
			Solid State Benchmarking is not available.<br>
			</span>
			<script>document.getElementById('SkipSSD').disabled=true;</script>
		<CFELSEIF DockerInfo.CPU.Total GTE 4 AND DockerInfo.CPU.Assigned LT 4>
			<span class="Red">
			<br>
			WARNING: You have #DockerInfo.CPU.Assigned# CPUs assigned to the DiskSpeed Docker app out of #DockerInfo.CPU.Total# CPUs. The Solid State benchmark requires 4 CPU
			threads in order to get an accurate benchmark. Solid State Benchmarking is not available.<br>
			</span>
			<script>document.getElementById('SkipSSD').disabled=true;</script>
		</CFIF>
	</CFIF>
	</CFOUTPUT>
	</CFSAVECONTENT>
	<CFIF Find("a",Ret) EQ 0>
		<CFSET Ret="">
	</CFIF>
	<CFRETURN Ret>
</CFFUNCTION>

<CFFUNCTION name="WaitForDriveActivityToStop">
	<!--- Returns total represented such as "1,2,4-8" = 10 --->
	<CFARGUMENT name="BlockDevice" type="string" required="true">
	<CFARGUMENT name="Timeout" type="numeric" default="5000" hint="Max number of MS to wait for BlockDevice activity to stop">
	<CFARGUMENT name="RetryCnt" type="numeric" default="5" hint="Number of zeros in a row before returning valid">

	<CFSET VAR StartTick=GetTickCount()>
	<CFSET VAR iostat="">
	<CFSET VAR OK=0>
	<CFSET VAR TimedOut=0>
	<CFSET VAR Retry=0>
	<CFSET VAR Inflight=0>
	<CFSET VAR Interval=100> <!--- Number of ms to wait between checks --->

	<CFLOOP condition="NOT OK">
		<CFSET iostat=ReadFile("/sys/block/#Arguments.BlockDevice#/stat")>
		<CFIF iostat EQ "">
			<CFSET OK=1>
		</CFIF>
		<CFSET Inflight=ListGetAt(iostat,9," ")>
		<CFIF Inflight EQ "0"> <!--- Number of inflight IO, if zero, drive is idle --->
			<CFSET Retry=Retry + 1>
		<CFELSE>
			<CFSET Retry=0>
		</CFIF>
		<CFIF Retry GTE Arguments.RetryCnt>
			<CFSET OK=1>
		</CFIF>
		<CFIF GetTickCount() GTE StartTick + Arguments.TimeOut>
			<CFSET OK=1>
			<CFSET TimedOut=1>
		</CFIF>
		<!---<CFOUTPUT>InFlight: #Inflight# Retry: #Retry# TimedOut: #TimedOut# OK: #OK#<br></CFOUTPUT><CFFLUSh>--->
		<CFSET Sleep(Interval)>
	</CFLOOP>

	<CFRETURN TimedOut>

</CFFUNCTION>

<CFFUNCTION name="SyncBlockDevice">
	<CFARGUMENT name="BlockDevice" type="string" required="false" default="">

	<CFTRY>
		<cfexecute name="/bin/sync" arguments="/dev/#Arguments.BlockDevice#" timeout="90" />
	<CFCATCH Type="Any">
	</CFCATCH>
	</CFTRY>
</CFFUNCTION>

