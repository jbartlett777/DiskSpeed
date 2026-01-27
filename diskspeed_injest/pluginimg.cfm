<CFSET ImageData=ImageRead("#RootDir#/HardDrive.png")>
<CFOUTPUT>#BinaryEncode(ImageData,"Base64")#</CFOUTPUT>
