component {

	this.name = "&lt;application-name&gt;"; // name of the application context

// regional
	// default locale used for formating dates, numbers ...
	this.locale = "en_US";
	// default timezone used
	this.timezone = "America/Los_Angeles";

// scope handling
	// lifespan of a untouched application scope
	this.applicationTimeout = createTimeSpan( 1, 0, 0, 0 );

	// session handling enabled or not
	this.sessionManagement = true;
	// cfml or jee based sessions
	this.sessionType = "application";
	// untouched session lifespan
	this.sessionTimeout = createTimeSpan( 0, 0, 30, 0 );
	this.sessionStorage = "memory";

	// client scope enabled or not
	this.clientManagement = false;
	this.clientTimeout = createTimeSpan( 90, 0, 0, 0 );
	this.clientStorage = "cookie";

	// using domain cookies or not
	this.setDomainCookies = false;
	this.setClientCookies = true;

	// prefer the local scope at unscoped write
	this.localMode = "classic";

	// buffer the output of a tag/function body to output in case of a exception
	this.bufferOutput = true;
	this.compression = false;
	this.suppressRemoteComponentContent = false;

	// If set to false Lucee ignores type defintions with function arguments and return values
	this.typeChecking = true;


// request
	// max lifespan of a running request
	this.requestTimeout=createTimeSpan(0,0,10,00);

// charset
	this.charset.web="UTF-8";
	this.charset.resource="UTF-8";

	this.scopeCascading = "strict";

//////////////////////////////////////////////
//               MAIL SERVERS               //
//////////////////////////////////////////////
	this.mailservers =[

	];
//////////////////////////////////////////////
//               DATASOURCES                //
//////////////////////////////////////////////

//////////////////////////////////////////////
//                 CACHES                   //
//////////////////////////////////////////////


//////////////////////////////////////////////
//               MAPPINGS                   //
//////////////////////////////////////////////

this.mappings["/lucee/admin"]={
		physical:"{lucee-config}/context/admin"
		,archive:"{lucee-config}/context/lucee-admin.lar"};

this.mappings["/lucee/doc"]={
		archive:"{lucee-config}/context/lucee-doc.lar"};


StartTick=GetTickCount();
include "CustomTags.cfm";
include "environment.cfm";

}

