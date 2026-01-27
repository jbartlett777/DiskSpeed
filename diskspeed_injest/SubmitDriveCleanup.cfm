<cfscript>
Skip=0;
if (Find("BD-RE",DriveData[i].Model) OR Find("DVD-ROM",DriveData[i].Model)) Skip=1;
if (DriveData[i].Revision EQ "0") Skip=1;
if (IsUnicode(DriveData[i].Vendor & DriveData[i].Model & DriveData[i].Revision)) Skip=1;
if (FindNoCase(" Flash ",DriveData[i].Model)) Skip=1;
if (ListFindNoCase("CineRAID,Config,HW,MSATA,SATA1,SATA2,SATA3,SSD",DriveData[i].Vendor)) Skip=1;
if (Left(DriveData[i].Vendor,10) EQ "RouterNAS-") Skip=1;

// Vendor Cleanup
if (Left(DriveData[i].Vendor,2) EQ "WD") {DriveData[i].Model=DriveData[i].Vendor;DriveData[i].Vendor="Western Digital";}
if (ListFindNoCase(Left(DriveData[i].Vendor,5),"C300-,C400-") OR DriveData[i].Vendor EQ "CT480") DriveData[i].Vendor="Crucial";
if ((Left(DriveData[i].Vendor,3) EQ "HDS" AND Len(DriveData[i].Vendor) GT 3) OR DriveData[i].Vendor EQ "HL-DT-ST") DriveData[i].Vendor="Hitachi";
if (Left(DriveData[i].Vendor,4) EQ "ASMT" OR DriveData[i].Vendor EQ "SATA" OR DriveData[i].Vendor EQ "PCIe SSD" OR DriveData[i].Vendor EQ "SPCC") DriveData[i].Vendor="Generic";
if ((Left(DriveData[i].Vendor,3) EQ "HUA" OR Left(DriveData[i].Vendor,3) EQ "TPH") AND Len(DriveData[i].Vendor) GT 3);
if (Left(DriveData[i].Vendor,3) EQ "IBM" AND Len(DriveData[i].Vendor) GT 3) DriveData[i].Vendor="IBM";
if (Left(DriveData[i].Vendor,2) EQ "MD" AND IsNumeric(Mid(DriveData[i].Vendor,3,1))) DriveData[i].Vendor="MaxDigital";
if (Left(DriveData[i].Vendor,6) EQ "Micron" OR Left(DriveData[i].Vendor,4) EQ "MTFD") DriveData[i].Vendor="Micron";
if (Left(DriveData[i].Vendor,3) EQ "OCZ") DriveData[i].Vendor="OCZ";
if (Left(DriveData[i].Vendor,5) EQ "P300-") DriveData[i].Vendor="Toshiba";
if (DriveData[i].Vendor EQ "SK") DriveData[i].Vendor="SK hynix";
if (Left(DriveData[i].Vendor,6) EQ "SSD2SC" OR Left(DriveData[i].Vendor,5) EQ "SSDSA") DriveData[i].Vendor="Intel";
if (Left(DriveData[i].Vendor,2) EQ "ST" AND IsNumeric(Mid(DriveData[i].Vendor,3,1))) DriveData[i].Vendor="Seagate";
if (DriveData[i].Vendor EQ "WD" OR DriveData[i].Vendor EQ "WDC") DriveData[i].Vendor="Western Digital";
if (DriveData[i].Vendor EQ "WL4000GSA6454") DriveData[i].Vendor="Generic";
if (DriveData[i].Vendor EQ "-Pretec") DriveData[i].Vendor="Pretec";
if (DriveData[i].Vendor EQ "SPCC") DriveData[i].Vendor="Silicon Power";
if (Left(DriveData[i].Model,6) EQ "Force ") DriveData[i].Vendor="Corsair";
if (Left(DriveData[i].Model,7) EQ "HS-SSD-") DriveData[i].Vendor="Hikvision";
if (DriveData[i].Vendor EQ "APPLE" and Left(DriveData[i].Model,9) EQ "APPLE HDD" AND Mid(DriveData[i].Model,11,2) EQ "ST") {DriveData[i].Vendor=1;DriveData[i].Model=Mid(DriveData[i].Model,11,999);}
if (Left(DriveData[i].Vendor,8) EQ "Apacer (") {DriveData[i].Vender="Apacer";DriveData[i].Model=Mid(DriveData[i],9,9999);DriveData[i].Model=Mid(DriveData[i].Model,1,Len(DriveData[i].Model)-1);}
if (DriveData[i].Vendor EQ "Drive") {
	if (DriveData[i].Model EQ "") Skip=1;
	if (Left(DriveData[i].Model,2) EQ "WD") DriveData[i].Vendor="Western Digital";
	if (DriveData[i].Model EQ "Sabrent") {DriveData[i].Vendor="Sabrent";DriveData[i].Model="No Model ID Given";}
	if (Left(DriveData[i].Model,9) EQ "GIGABYTE ") {DriveData[i].Vendor="GIGABYTE";DriveData[i].Model=Mid(DriveData[i].Model,10,999);}
}
if (Left(DriveData[i].Vendor,9) EQ "GIGABYTE ") {DriveData[i].Vendor="GIGABYTE";DriveData[i].Model=Mid(DriveData[i].Model,10,999);}
if (Left(DriveData[i].Vendor,8) EQ "Sabrent ") {DriveData[i].Vendor="Sabrent";DriveData[i].Model=Mid(DriveData[i].Model,9,999);}

if (Left(DriveData[i].Vendor,7) EQ "KIOXIA-") {DriveData[i].Vendor="KIOXIA";DriveData[i].Model=Mid(DriveData[i],8,999) & " " & DriveData[i].Model;}
if (REFindNoCase("SSDPR-[A-Z0-9]+?-\d+?-",DriveData[i].Vendor)) DriveData[i].Vendor="GOODRAM";
if (REFindNoCase("TP\w\d+?GB",DriveData[i].Vendor)) {DriveData[i].Model=DriveData[i].Vendor;DriveData[i].Vendor="HGST";}
if (REFindNoCase("WL\d{4}\w{3}\d+",DriveData[i].Vendor)) {DriveData[i].Model=DriveData[i].Vendor;DriveData[i].Vendor="Unknown";}
if (ListFirst(DriveData[i].Vendor," ") EQ "TOSHIBA") {DriveData[i].Vendor="Toshiba";DriveData[i].Vendor=ListDeleteAt(DriveData[i].Vendor,1," ");}

if (ListFindNoCase("MaxDigital,Seagate,Hitachi,Toshiba,Intel",DriveData[i].Vendor) AND ListLen(DriveData[i].Model," ") GT 1) DriveData[i].Model=ListFirst(DriveData[i].Model," ");
if (ListFindNoCase("Seagate,Intel",DriveData[i].Vendor) AND ListLen(DriveData[i].Model,"-") GT 1) DriveData[i].Model=ListFirst(DriveData[i].Model,"-");
if (DriveData[i].Vendor EQ "Seagate" AND Left(DriveData[i].Model,14) EQ "BarraCuda SSD ") DriveData[i].Model=Mid(DriveData[i].Model,15,999);
if (DriveData[i].Vendor EQ "Seagate" AND Left(DriveData[i].Model,2) EQ "ST" AND ListLen(DriveData[i].Model,"-") GT 1) DriveData[i].Model=ListFirst(DriveData[i].Model,"-");
if (DriveData[i].Vendor EQ "Samsung" AND Left(DriveData[i].Model,2) EQ "MZ" AND Mid(DriveData[i].Model,3,1) NEQ "-") DriveData[i].Model=ListFirst(DriveData[i].Model,"-");
if (DriveData[i].Vendor EQ "Samsung" AND Left(DriveData[i].Model,2) EQ "ST") DriveData[i].Model=ListFirst(DriveData[i].Model,"-");
if (DriveData[i].Vendor EQ "Generic" AND ListFirst(DriveData[i].Model," ") EQ "Hitachi") {DriveData[i].Vendor="Hitachi";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (DriveData[i].Vendor EQ "Generic" AND ListFirst(DriveData[i].Model,"-") EQ "OZC") {DriveData[i].Vendor="OZC";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1,"-");}
if (DriveData[i].Vendor EQ "LITEONIT") DriveData[i].Vendor="LITEON";
if (DriveData[i].Vendor EQ "LITEON" AND Left(DriveData[i].Model,3) EQ "IT ") DriveData[i].Model=Mid(DriveData[i].Model,4,999);
if (DriveData[i].Vendor EQ "LITEON" AND Find("mm",DriveData[i].Model)) DriveData[i].Model=ListFirst(DriveData[i].Model," ");
if (DriveData[i].Vendor EQ "LITEON" AND Find("MSATA",DriveData[i].Model)) DriveData[i].Model=ListFirst(DriveData[i].Model," ");
if (DriveData[i].Vendor EQ "Micron" AND Left(DriveData[i].Model,12) EQ "Micron 1100 ") DriveData[i].Model=Mid(DriveData[i].Model,13,999);
if (DriveData[i].Vendor EQ "Micron" AND Left(DriveData[i].Model,12) EQ "Micron 5100 ") DriveData[i].Model=Mid(DriveData[i].Model,13,999);
if (DriveData[i].Vendor EQ "Micron" AND Left(DriveData[i].Model,13) EQ "Micron P400e-") DriveData[i].Model=Mid(DriveData[i].Model,14,999);
if (DriveData[i].Vendor EQ "Micron" AND Left(DriveData[i].Model,2) EQ "MT") DriveData[i].Model=ListFirst(DriveData[i].Model,"-");
if (DriveData[i].Vendor EQ "SK hynix" AND ListFirst(DriveData[i].Model," ") EQ "hynix") DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");

if (DriveData[i].Vendor EQ "Unknown") {
	if (ListFindNoCase("ADATA,Apacer,Corsair,KINGSTON,Netac,Patriot,PNY,Reletech,Sabrent,Seagate,XPG,ZHITAI",ListFirst(DriveData[i].Model," "))) DriveData.Vendor=ListFirst(DriveData[i].Model," ");
	if (ListFindNoCase("Western Digital",ListFirst(DriveData[i].Model," ") & " " & ListGetAt(DriveData[i],2," "))) DriveData.Vendor=ListFirst(DriveData[i].Model," ") & " " & ListGetAt(DriveData[i],2," ");
	if (ListFirst(DriveData[i].Model," ") EQ "WD") DriveData[i].Vendor="Western Digital";
	if (ListFirst(DriveData[i].Model," ") EQ "TEAM") DriveData[i].Vendor="Team Group";
	if (ListFirst(DriveData[i].Model," ") EQ "WD_BLACK") DriveData[i].Vendor="Western Digital";
	if (Find("Sk Hynix",DriveData[i].Model)) DriveData[i].Vendor="Sk hynix";
}

if (IsNumeric(Val(DriveData[i].Vendor)) AND ListFindNoCase("MB,GB,TB,PB",Right(DriveData[i].Vendor,2))) Skip=1;

if (DriveData[i].Vendor EQ "SK Hynix") DriveData[i].Vendor="SK hynix";
if (DriveData[i].Vendor EQ "gigabyte") DriveData[i].Vendor="GIGABYTE";
if (DriveData[i].Model EQ "LOGICAL VOLUME") Skip=1;

if (DriveData[i].Vendor EQ "QEMU") Skip=1;
if (ListFindNoCase("SDLF1CRR-019T-1H",DriveData[i].Vendor)) DriveData[i].Vendor='SanDisk';
if (ListFindNoCase("SSDSC2BA400G3I",DriveData[i].Vendor)) DriveData[i].Vendor='Intel';

if (ListFindNoCase("CT1000P,CT1000T,CT2000P,CT2000T",Left(DriveData[i].Vendor,7))) DriveData[i].Vendor='Crucial';
if (ListFindNoCase("CT500P,CT500T",Left(DriveData[i].Vendor,6))) DriveData[i].Vendor='Crucial';
if (ListFindNoCase("HDWG,HDWT,MG04,MG06,MG07,MG08,MG09,MG10,MQ01",Left(DriveData[i].Vendor,4))) DriveData[i].Vendor='Toshiba';
if (ListFindNoCase("MZPLJ",Left(DriveData[i].Vendor,5))) DriveData[i].Vendor='Samsung';
if (ListFindNoCase("SHGP,SHPP",Left(DriveData[i].Vendor,4))) DriveData[i].Vendor='SK hynix';
if (ListFindNoCase("SP00,SPCC",Left(DriveData[i].Vendor,4))) DriveData[i].Vendor='SK hynix';


if (Find("ADATA",DriveData[i].Vendor) AND DriveData[i].Vendor NEQ "ADATA") DriveData[i].Vendor='ADATA';
if (Left(DriveData[i].Vendor,5) EQ "Lexar" AND DriveData[i].Vendor NEQ "Lexar") DriveData[i].Vendor="Lexar";
if (ListFirst(DriveData[i].Model," ") EQ "Lexar" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="Lexar";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,8) EQ "Fanxiang" AND DriveData[i].Vendor NEQ "Fanxiang") DriveData[i].Vendor="Fanxiang";
if (ListFirst(DriveData[i].Model," ") EQ "Fanxiang" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="Fanxiang";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,8) EQ "GIGABYTE" AND DriveData[i].Vendor NEQ "GIGABYTE") DriveData[i].Vendor="GIGABYTE";
if (ListFirst(DriveData[i].Model," ") EQ "GIGABYTE" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="GIGABYTE";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,8) EQ "KingSpec" AND DriveData[i].Vendor NEQ "KingSpec") DriveData[i].Vendor="KingSpec";
if (ListFirst(DriveData[i].Model," ") EQ "KingSpec" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="KingSpec";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (ListFirst(DriveData[i].Model,"-") EQ "KingSpec" AND ListLen(DriveData[i].Model,"-" GT 1)) {DriveData[i].Vendor="KingSpec";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1,"-");}
if (Left(DriveData[i].Vendor,8) EQ "KINGSTON" AND DriveData[i].Vendor NEQ "KINGSTON") DriveData[i].Vendor="KINGSTON";
if (ListFirst(DriveData[i].Model," ") EQ "KINGSTON" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="KINGSTON";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,6) EQ "KIOXIA" AND DriveData[i].Vendor NEQ "KIOXIA") DriveData[i].Vendor="KIOXIA";
if (ListFirst(DriveData[i].Model,"-") EQ "KIOXIA" AND ListLen(DriveData[i].Model,"-" GT 1)) {DriveData[i].Vendor="KIOXIA";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1,"-");}
if (Left(DriveData[i].Vendor,8) EQ "Memblaze" AND DriveData[i].Vendor NEQ "Memblaze") DriveData[i].Vendor="Memblaze";
if (ListFirst(DriveData[i].Model," ") EQ "Memblaze" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="Memblaze";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,3) EQ "MSI" AND DriveData[i].Vendor NEQ "MSI") DriveData[i].Vendor="MSI";
if (ListFirst(DriveData[i].Model," ") EQ "MSI" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="MSI";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,7) EQ "Patriot" AND DriveData[i].Vendor NEQ "Patriot") DriveData[i].Vendor="Patriot";
if (ListFirst(DriveData[i].Model," ") EQ "Patriot" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="Patriot";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,7) EQ "Sabrent" AND DriveData[i].Vendor NEQ "Sabrent") DriveData[i].Vendor="Sabrent";
if (ListFirst(DriveData[i].Model," ") EQ "Sabrent" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="Sabrent";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,5) EQ "SSSTC" AND DriveData[i].Vendor NEQ "SSSTC") DriveData[i].Vendor="SSSTC";
if (ListFirst(DriveData[i].Model," ") EQ "SSSTC" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="SSSTC";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,7) EQ "T-FORCE" AND DriveData[i].Vendor NEQ "T-FORCE") DriveData[i].Vendor="T-FORCE";
if (ListFirst(DriveData[i].Model," ") EQ "T-FORCE" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="T-FORCE";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,8) EQ "DAPUSTOR" AND DriveData[i].Vendor NEQ "DAPUSTOR") DriveData[i].Vendor="DAPUSTOR";
if (ListFirst(DriveData[i].Model," ") EQ "DAPUSTOR" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="DAPUSTOR";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}

if (Left(DriveData[i].Vendor,17) EQ "Seagate Barracuda") DriveData[i].Vendor="Seagate";
if (Left(DriveData[i].Vendor,16) EQ "Seagate FireCuda") DriveData[i].Vendor="Seagate";
if (Left(DriveData[i].Vendor,9) EQ "SK hynix ") DriveData[i].Vendor="SK hynix";


if (ListLast(DriveData[i].Model," ") EQ "KIOXIA") {DriveData[i].Vendor="KIOXIA";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,ListLen(DriveData[i].Model," ")," ");}


if (Left(DriveData[i].Vendor,4) EQ "JAJP") DriveData[i].Vendor="Lares";

if (ListFindNoCase("PCIe SSD,Generic,QEMU",DriveData[i].Vendor)) Skip=1;
if (ListFindNoCase("LOGICAL VOLUME",DriveData[i].Model)) Skip=1;

if (DriveData[i].Vendor EQ "Toshbia") DriveData[i].Vendor="Toshiba"


</cfscript>
