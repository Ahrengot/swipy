// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
Parse.Cloud.useMasterKey();
require('cloud/app.js');
Parse.Cloud.beforeSave("ToDo",function(request,response){
  var user = request.user;
  if(!user && !request.master) return sendError(response,'You have to be logged in to save ToDo');
  var attrWhitelist = ["title","order","schedule","completionDate","repeatOption","repeatDate","repeatCount","tags","notes","location","priority"];
  handleObject(request.object, attrWhitelist);
  response.success();
});
function handleObject(object,attrWhiteList){
  var user = Parse.User.current();
  var _ = require('underscore');
  var defAttributes = ["deleted","attributeChanges","tempId","owner"];
  if(attrWhiteList){
    for(var attribute in object.attributes){
      if(_.indexOf(attrWhiteList,attribute) == -1 && _.indexOf(defAttributes,attribute) == -1) delete object.attributes[attribute];
    }
  }
  makeAttributeChanges(object);
  if(object.isNew() && user){ 
    object.set('owner',user);
    var ACL = new Parse.ACL();
    ACL.setReadAccess(user.id,true);
    ACL.setWriteAccess(user.id,true);
    object.setACL(ACL);
  }
}
Parse.Cloud.beforeSave('Payment',function(request,response){
  var user = request.user;
  if(!user && !request.master) return sendError(response,'You have to be logged in to save Payment');
  var payment = request.object;
  payment.set('user',user);
  var productIdentifier = payment.get('productIdentifier');
  var callback = {
    success: function(savedUser) {
      response.success();
    },
  	error: function(savedUser, error) {
      console.error("Error upgrading user: "+ savedUser.id);
      console.error(error);
      response.success();
    }
  };
  if(productIdentifier == 'plusMonthlyTier1'){
    user.set('userLevel',2);
    user.save(null,callback);
  }
  else if(productIdentifier == 'plusYearlyTier10'){
    user.set('userLevel',3);
    user.save(null,callback);
  }
});
Parse.Cloud.beforeSave("Tag",function(request,response){
  var user = request.user;
  if(!user && !request.master) return sendError(response,'You have to be logged in to save Tag');
  var attrWhitelist = ["title"];
  handleObject(request.object);
  response.success();
});
function makeAttributeChanges(object){
  var attributes = object.attributes;
  var updateTime = new Date();
  var changes = object.get('attributeChanges');
  if(!changes) changes = {};
  if(attributes){
    var hasChanged = false;
    for(var attribute in attributes){
      if(object.dirty(attribute) && attribute != 'attributeChanges'){ 
        hasChanged = true;
        changes[attribute] = updateTime;
      }
    }
    if(hasChanged) object.set('attributeChanges',changes);
  }
}
function scrapeChanges(object,lastUpdateTime){
  var attributes = object.attributes;
  var updateTime = new Date();
  if(!attributes['attributeChanges']) return;
  if(!lastUpdateTime) return delete attributes['attributeChanges'];
  var changes = object.get('attributeChanges');
  if(!changes) changes = {};
  if(attributes){
    for(var attribute in attributes){
      var lastChange = changes[attribute];  
      if(attribute == "deleted" || attribute == "tempId") continue;
      if(!lastChange || lastChange <= lastUpdateTime) delete attributes[attribute];
    }
  }
}
Parse.Cloud.define('checkEmail',function(request,response){
  var email = request.params.email;
  if(!email) return sendError(response,'You need to include email');
  var query = new Parse.Query(Parse.User);
  query.equalTo('username',email);
  query.count({success:function(counter){
    if(counter > 0) response.success(1);
    else response.success(0);
  },error:function(error){ sendError(response,error); }});
});
Parse.Cloud.define('cleanup',function(request,response){
  var query = new Parse.Query('ServerError');
  query.limit(1000);
  query.find({success:function(objects){ 
    Parse.Object.destroyAll(objects,{
      success:function(){
        response.success(); 
      },error:function(error){ 
        response.error(error); 
      }});},error:function(error){
      response.error(error);
      }
    });
  });


Parse.Cloud.define("subscribe", function(request, response) {
  var email = request.params.email;
  if(!email) return response.error('Must include email');
  var Signup = Parse.Object.extend("Signup");
  var testQuery = new Parse.Query("Signup");
  testQuery.equalTo("email", email);
  testQuery.first({
    success: function(object) {
      if(object) return response.success('already');
      object = new Signup();
      object.set('email',email);
      object.save(null,{success:function(object){
        response.success('success');
      },error:function(object,error){
        response.error(error);
      }});
    },
    error: function() {
      response.error("movie lookup failed");
    }
  });
});
Parse.Cloud.define('update',function(request,response){
  var user = Parse.User.current();
  var updateTime = new Date(new Date().getTime());
  if(!user) return sendError(response,'You have to be logged in');

  var limit = 1000;
  var skip = request.params.skip;
  var lastUpdate = false;
  if(request.params.lastUpdate) lastUpdate = new Date(request.params.lastUpdate);
  var changesOnly = request.params.changesOnly ? lastUpdate : false;

  var queue = require('cloud/queue.js');
  var tagQuery = new Parse.Query('Tag');
  tagQuery.equalTo('owner',user);
  tagQuery.limit(limit);
  if(skip) tagQuery.skip(skip);
  if(lastUpdate) tagQuery.greaterThan('updatedAt',lastUpdate);
  else tagQuery.notEqualTo('deleted',true);
  queue.addToQueue(tagQuery);

  var taskQuery = new Parse.Query('ToDo');
  taskQuery.equalTo('owner',user);
  taskQuery.limit(limit);
  if(skip) taskQuery.skip(skip);
  if(lastUpdate) taskQuery.greaterThan('updatedAt',lastUpdate);
  else taskQuery.notEqualTo('deleted',true);
  queue.addToQueue(taskQuery);

  runQueue(queue.getQueue(),function(objects,error){
    if(error) sendError(response,error);
    else{
      objects.updateTime = updateTime.toISOString();
      objects.serverTime = new Date().toISOString();
      response.success(objects);
    }
  },{recurring:3,changesSince:changesOnly,limit:limit});
});
Parse.Cloud.define("unsubscribe",function(request,response){
  var email = request.params.email;
  if(!email) return response.error('Must include email');
  var mailjet = req('mailjet');
  mailjet.request("listsUnsubcontact",{"id":"370097","contact":email},function(result,error){
    if(error) response.error(error);
    else response.success(result);
  });
});
Parse.Cloud.beforeSave("Signup",function(request,response){
  var mailchimp = req('mailchimp');
  var conf = require('cloud/conf.js');
  var keys = conf.keys;
  mailchimp.subscribe(keys.subscribeList,request.object.get('email'),false,function(result,error){
    if(error) response.error(error);
    else response.success();
  });
});
Parse.Cloud.define('test',function(request,response){
  var paymentQuery = new Parse.Query('Payment');
  paymentQuery.include('user');
  paymentQuery.limit(1000);
  paymentQuery.find({success:function(payments){ 
    var userQuery = new Parse.Query(Parse.User);
    userQuery.limit(1000);
    userQuery.doesNotExist('userLevel');
    var contained = new Array();
    for(var i = 0 ; i < payments.length ; i++){
      contained.push(payments[i].get('user').id);
    }
    userQuery.containedIn('objectId',contained);
    userQuery.find({success:function(payments){ response.success(payments); },error:function(error){ response.error(error); }});
  },error:function(error){ response.error(error); }});

  
});
Parse.Cloud.beforeSave(Parse.User,function(request,response){
  var object = request.object;
  if(object.dirty("username")){
    if(validateEmail(object.get('username'))){
      var conf = require('cloud/conf.js');
      var keys = conf.keys;
      var mandrill = req('mandrill');
      var mailjet = req('mailjet');
      mailjet.request("listsAddcontact",{"id":"370097","contact":object.get('username')});
      mandrill.sendTemplate("welcome-again",object.get('username'),"Welcome news & tips");
    }
  }
  if(object.dirty('userLevel') && !request.master){
    return sendError(response,'User not allowed to change this');
  }
  response.success();
});
function req(module){
  return require('cloud/'+module+'.js');
}
function validateEmail(email) {
    var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(email);
}
function sendError(response,error){
  var user = Parse.User.current();
  var ServerError = Parse.Object.extend("ServerError");
  var serverError = new ServerError();
  console.error(error);
  serverError.set('user',user);
  serverError.set('error',error);
  serverError.save({
    success:function(){
      if(response) response.error(error);
    },error:function(error2){
      if(response) response.error(error);
    }
  });
}
function runQueue(queue,done,options){
  function performQuery(object,callback){
    var query = object.query;
    if(object.skip) query.skip(object.skip);
    var optionObject = {
      success:function(result){
        callback(object,result);
      },
      error:function(error){
        callback(object,null,error);
      }
    };
    if(object.count) query.count(optionObject);
    else query.find(optionObject);
  }
  var limit = 1000;
  if(options && options.limit) limit = parseInt(options.limit);
  var recurring = 1;
  if(options && options.recurring) recurring = options.recurring;
  var k = 0;
  var doneCounter = 0;
  var calledDone= false;
  if(queue.length === 0) return done(false,null);
  var returnObj = {};
  function checkDone(){
    if(calledDone) return;
    if(doneCounter == queue.length){
      done(returnObj,null);
      calledDone = true;
    }
    else next();
  }
  function next(){
    if(k>=queue.length){
      return;
    }
    performQuery(queue[k],function(object,result,error){
      if(error && !calledDone){
        done(null,error);
        calledDone = true;
      }
      else{
      	var length = result.length;
      	if(options.changesSince){
	        if(result && length > 0){
	          for(var i = 0 ; i < result.length ; i++){
	            var obj = result[i];
	            scrapeChanges(obj,options.changesSince);
	          }
	        }
    	}
    	if(length == limit){
    		object.skip += limit;
  			queue.push(object);
    	}
        if(returnObj[object.title]) returnObj[object.title] = returnObj[object.title].concat(result);
        else returnObj[object.title] = result;
        doneCounter++;
        checkDone();
      }
      
    });
    k++;
  }
  for(var i = 0 ; i < recurring ; i++){
    next();
  }
}
