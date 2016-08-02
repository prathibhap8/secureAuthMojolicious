require([
    "dojo/_base/declare",
    "dojo/_base/lang",
    "dojo/on",
    "dojo/dom",
    "dojo/Evented",
    "dojo/_base/Deferred",
    "dojo/json",
    "dojo/request",
    
    "dijit/_Widget",
    "dijit/_TemplatedMixin",
    "dijit/_WidgetsInTemplateMixin",
    
    "dojox/grid/DataGrid",
    "dojo/store/Memory",
    "dojo/data/ObjectStore",
    
    "dijit/Dialog",
    "dijit/form/Form",
    "dijit/form/ValidationTextBox",
    "dijit/form/Button",
    
    "dojo/domReady!"
], function(
    declare,
    lang,
    on,
    dom,
    Evented,
    Deferred,
    JSON,
    request,
        
    _Widget,
    _TemplatedMixin, 
    _WidgetsInTemplateMixin,
    
    DataGrid,
    Memory,
    ObjectStore,
        
     Dialog
) {

    var LoginDialog = declare([Dialog, Evented], {
        
        READY: 0,
        BUSY: 1,
        
        title: "Login Dialog",
        message: "",
        busyLabel: "Working...",
        
        // Binding property values to DOM nodes in templates
        // see: http://www.enterprisedojo.com/2010/10/02/lessons-in-widgetry-binding-property-values-to-dom-nodes-in-templates/
        attributeMap: lang.delegate(dijit._Widget.prototype.attributeMap, {
            message: {
                node: "messageNode",
                type: "innerHTML"               
            }            
        }),
        
        constructor: function(/*Object*/ kwArgs) {
            lang.mixin(this, kwArgs);            
            var dialogTemplate = dom.byId("dialog-template").textContent; 
            var formTemplate = dom.byId("login-form-template").textContent;
            var template = lang.replace(dialogTemplate, {
                form: formTemplate                
            });

            var contentWidget = new (declare(
                [_Widget, _TemplatedMixin, _WidgetsInTemplateMixin],
                {
                    templateString: template                   
                }
            )); 
            contentWidget.startup();
            var content = this.content = contentWidget;
            this.form = content.form;
            // shortcuts
            this.submitButton = content.submitButton;
            this.messageNode = content.messageNode;
        },
        
        postCreate: function() {
            this.inherited(arguments);
            
            this.readyState= this.READY;
            this.okLabel = this.submitButton.get("label");
            
            this.connect(this.submitButton, "onClick", "onSubmit");
            
            this.watch("readyState", lang.hitch(this, "_onReadyStateChange"));
            
            this.form.watch("state", lang.hitch(this, "_onValidStateChange"));
            this._onValidStateChange();
        },
        
        onSubmit: function() {
            this.set("readyState", this.BUSY);
            this.set("message", ""); 
            var data = this.form.get("value");
            
            var auth = this.controller.login(data);
            
            Deferred.when(auth, lang.hitch(this, function(loginSuccess) {
                if (loginSuccess.status === "Authenticated") {
                    this.onLoginSuccess();
                    return;                    
                }
                this.onLoginError(loginSuccess.message);
            }));
        },
            
        onLoginSuccess: function() {
            this.set("readyState", this.READY);             
            this.emit("success");
        },
        
        onLoginError: function(setMessage) {
            this.set("readyState", this.READY);
            this.set("message", setMessage); 
            this.emit("error");         
        },

        _onValidStateChange: function() {
            this.submitButton.set("disabled", !!this.form.get("state").length);
        },

        _onReadyStateChange: function() {
            var isBusy = this.get("readyState") == this.BUSY;
            this.submitButton.set("label", isBusy ? this.busyLabel : this.okLabel);
            this.submitButton.set("disabled", isBusy);
        }            
    });
    
    var LoginController = declare(null, {
    
        constructor: function(kwArgs) {
            lang.mixin(this, kwArgs);
        },
        
        login: function(data) {
            // simulate calling web service for authentication
            var def = new Deferred();            
            request.post("/",
                {data: data, handleAs: "json"}
            ).then(
                function(response){
                    def.resolve(response);
                    if (response.status === "Authenticated") {
                        loginDialog.hide();
                        callListing();
                    }
                },
                function(error){
                    def.resolve(error);
                    dojo.byId("response").innerHTML = "Form posted."+error;
                }
            );
            return def;
        }
    });
    
    var objectStore;
    var callListing = function(){
        request.get("/listing",
            {handleAs: "json"}
        ).then(
            function(response){
                
                objectStore = new Memory({data: response.details});
                var grid = new DataGrid({
                    store: ObjectStore({objectStore: objectStore}),
                    structure: [
                        {name:"ID", field:"id", width:"10%"},
                        {name:"Last Active Time", field:"lastactivetime", width:"20%"},
                        {name:"Login Time", field:"logintime", width:"20%"},
                        {name:"Session Key", field:"sessionkey", width:"20%"},
                        {name:"Status", field:"status", width:"10%"},
                        {name:"User Login ID", field:"userlogin_id", width:"20%"}
                    ]
                }, "response");
                grid.startup();
                
                objectStore = new Memory({data: response.validatedDetails});
                var gridProperties = new DataGrid({
                    store: ObjectStore({objectStore: objectStore}),
                    structure: [
                        {name:"#", field:"index", width:"50%"},
                        {name:"Valided Properties", field:"validated_val", width:"50%"}
                    ]
                }, "properties");
                gridProperties.startup();
                dojo.byId("header-panel").innerHTML = '<span>Dashboard</span><a href="/logout">Logout</a>';
                dojo.byId("inserted-data").innerHTML = "Data Inserted to database";
                dojo.byId("validated-data").innerHTML = "Validated Login Details";
            },
            function(error){
                dojo.byId("response").innerHTML = "Form posted."+error;
            }
        );
    };

    // provide username & password in constructor
    // since we do not have web service here to authenticate against    
    var loginController = new LoginController({username: "user", password: "user"});
    
    var loginDialog = new LoginDialog({ controller: loginController});
    loginDialog.startup();
    
    request.get("/checkSession",
                {handleAs: "json"}
    ).then(
        function(response){
            if (response.status === "Authenticated") {
                callListing();
            }
            else {
                loginDialog.show();
            }
        },
        function(error){
            dojo.byId("response").innerHTML = "Form posted."+error;
        }
    );
    
    loginDialog.on("error", function() { 
        console.log("Login error.");
    });
    
    loginDialog.on("success", function() { 
        console.log("Login success.");
        console.log(JSON.stringify(this.form.get("value")));
    });

      
});