var http = require('http');
var uuid = require('node-uuid');
var moment = require('moment');
var express = require('express');
var app = express();

var images = [];
var pageOutput = '';

var LRS_HOST = 'lrs.com';
var LRS_PATH = '/tc/endpoint/';
var LRS_PORT = '80';
var LRS_USER = '3JWa9VEQpXsIxMbdoSJK345c';
var LRS_PASSWORD = 'q5bawNVN2xv99sABC123';

function putStatementToLrs(url, statement, callback)
{
	console.log(url);
	console.log(JSON.stringify(statement));
	statements = [];
	statements.push(statement);
	
	  var options = {
		host: LRS_HOST,
	    path: LRS_PATH+url,
		port: LRS_PORT,
		method: "POST",
	    headers: {'Authorization':'Basic ' + new Buffer(LRS_USER + ':' + LRS_PASSWORD).toString('base64') , 'X-Experience-API-Version':'1.0.0', 'Content-Type': 'application/json', 'accept': "application/json"}
	  };
	lrsCallback = function(response) {
	    var str = '';
	    response.on('data', function (chunk) {
	      str += chunk;
	    });
	    response.on('error', function(e) {
	      console.log('problem with request: ' + e.message);
	    });
	    response.on('end', function (err) {
	      console.log('error:'+err);
	      console.log('statusCode : ' + response.statusCode);
	      try{
			console.log(str);
			callback(str);
	      }catch(err){
	        console.log("error : " + err);
	      }
	    });
	  };
	  var req = http.request(options, lrsCallback);
		req.write(JSON.stringify(statement));
	  req.end();
	
}

function getStatementsFromLrs(url, callback)
{
  console.log(url);
  var options = {
		host: LRS_HOST,
	    path: LRS_PATH+url,
		port: LRS_PORT,
	    headers: {'Authorization':'Basic ' + new Buffer(LRS_USER + ':' + LRS_PASSWORD).toString('base64') , 'X-Experience-API-Version':'1.0.0', 'Content-Type': 'application/json', 'accept': "application/json"}
  };
  var statementResponseFromLRS;

  lrsCallback = function(response) {
    var str = '';
    response.on('data', function (chunk) {
      str += chunk;
    });
    response.on('error', function(e) {
      console.log('problem with request: ' + e.message);
    });
    response.on('end', function (err) {
      try{
		callback(str);
      }catch(err){
        console.log("error : " + err);
      }
    });
  };
  var req = http.request(options, lrsCallback);
  req.end();
}


app.get('/', function(req, res){
	getStatementsFromLrs('statements?verb=http%3A%2F%2Ftincanapi.com%2Fverbs%2Fphotographed&limit=12&attachments=true', function(data){
		var border = data.split('\n')[1];
		var dataArray = data.split(border);
		var statementJson = dataArray[1].split('\n')[4]; //the actual json
		statements = JSON.parse(statementJson).statements
		var body = '<meta name = "viewport" content = "width=device-width">';

		//store attachments in dict for later retrieval
		var attachments = {};
		for(var i=2;i<dataArray.length;i++){
			attachments[dataArray[i].split('\n')[2].replace('X-Experience-API-Hash:','').replace('\r','')] = dataArray[i].split('\n')[5].replace('\r','')
		}

		for (var i = 0; i < statements.length; i++){
			if(statements[i].attachments){
					body += '<div style="border:1px black solid; width:300px;text-align:center;padding:10px;">';
					body += '<p style="font : 18pt arial,geneva,sans-serif;"><strong><a href="/user?email=' + statements[i]['actor'].mbox.replace('mailto:','') + '">' + statements[i]['actor'].name + '</a></strong></p>';
					 body += '<img src="'+ attachments[statements[i].attachments[0].sha2] +'"/>';
					 body += '<p style="font : 14pt arial,geneva,sans-serif;"><strong>' + statements[i]['object'].definition.name['en-US'] + '</strong></p>';
					body += '<br><i>' + moment(statements[i].timestamp).format("dddd, MMMM Do YYYY, h:mm:ss a") + '</i>';
					body += '<br>';
					 if(statements[i]['object'].definition.extensions && statements[i]['object'].definition.extensions['http://registry.tincanapi.com/extensions/coordinates']){
					 	body += '<br>Longitude: ' + statements[i]['object'].definition.extensions['http://registry.tincanapi.com/extensions/coordinates'].currentLong;
					 	body += '<br>Latitude: ' + statements[i]['object'].definition.extensions['http://registry.tincanapi.com/extensions/coordinates'].currentLat;
					 }
					body += '<br>';
					body += '</div>';
			}
		};
	
	  res.setHeader('Content-Type', 'text/html');
	  res.setHeader('Content-Length', body.length);
	  res.end(body);
		
	});

});

app.get('/user', function(req, res){
	// this is ugly, but it works for now.
	getStatementsFromLrs('statements?agent=%7B%22objectType%22%3A%22Agent%22%2C%22mbox%22%3A%22mailto%3A' + req.query.email.replace('@','%40') + '%22%7D&verb=http%3A%2F%2Ftincanapi.com%2Fverbs%2Fphotographed&limit=25&related_activities=false&related_agents=false&attachments=true', function(data){
		var border = data.split('\n')[1];
		var dataArray = data.split(border);
		var statementJson = dataArray[1].split('\n')[4]; //the actual json

		statements = JSON.parse(statementJson).statements
		var body = '<meta name = "viewport" content = "width=device-width">';

		//store attachments in dict for later retrieval
		var attachments = {};
		for(var i=2;i<dataArray.length;i++){
			attachments[dataArray[i].split('\n')[2].replace('X-Experience-API-Hash:','').replace('\r','')] = dataArray[i].split('\n')[5].replace('\r','')
		}

		for (var i = 0; i < statements.length; i++){
			if(statements[i].attachments){
					body += '<div style="border:1px black solid; width:300px;text-align:center;padding:10px;">';
					body += '<p style="font : 18pt arial,geneva,sans-serif;"><strong>' + statements[i]['actor'].name + '</strong></p>';
					body += '<img src="'+ attachments[statements[i].attachments[0].sha2] +'"/>'; 
					body += '<p style="font : 14pt arial,geneva,sans-serif;"><strong>' + statements[i]['object'].definition.name['en-US'] + '</strong></p>';
					body += '<br><i>' + moment(statements[i].timestamp).format("dddd, MMMM Do YYYY, h:mm:ss a") + '</i>';
					body += '<br>';
					 if(statements[i]['object'].definition.extensions && statements[i]['object'].definition.extensions['http://registry.tincanapi.com/extensions/coordinates']){
					 	body += '<br>Longitude: ' + statements[i]['object'].definition.extensions['http://registry.tincanapi.com/extensions/coordinates'].currentLong;
					 	body += '<br>Latitude: ' + statements[i]['object'].definition.extensions['http://registry.tincanapi.com/extensions/coordinates'].currentLat;
					 }
					body += '<br>';
					body += '</div>';
			}
		};
	
	  res.setHeader('Content-Type', 'text/html');
	  res.setHeader('Content-Length', body.length);
	  res.end(body);
		
	});
});

app.get('/photo', function(req, res){
	getStatementsFromLrs('statements?statementId='+req.query.id+'&attachments=true', function(data){
		var border = data.split('\n')[1];;
		var dataArray = data.split(border);
		var statementJson = dataArray[1].split('\n')[4]; //the actual json
		var attachment = dataArray[2].substr(0,dataArray[2].length-(border.length+2)); //remove the last border plus the extra 2 --

		var experience = {};
		experience.statementJson = statementJson;
		experience.imageData = 'data:'+attachment.split('data:')[1];
		var statementObj = JSON.parse(statementJson);
		var body = '<img src="'+ experience.imageData +'"/>';
		body += '<br>Posted Timestamp: ' + moment(statementObj.timestamp).format("dddd, MMMM Do YYYY, h:mm:ss a");
		body += '<br>Activity Id: ' + statementObj['object'].id;
		body += '<br>Activity Name: ' + statementObj['object'].definition.name['en-US'];
		if(statementObj['object'].definition.extensions && statementObj['object'].definition.extensions['http://registry.tincanapi.com/extensions/coordinates']){
			body += '<br>Longitude: ' + statementObj['object'].definition.extensions['http://registry.tincanapi.com/extensions/coordinates'].currentLong;
			body += '<br>Latitude: ' + statementObj['object'].definition.extensions['http://registry.tincanapi.com/extensions/coordinates'].currentLat;
		}
		//body += '<br>' + experience.statementJson;
		res.setHeader('Content-Type', 'text/html');
		  res.setHeader('Content-Length', body.length);
		  res.end(body);
		
	});
});

app.get('/comment', function(req, res){
	var actor = req.query.actor;
	var statementRef = req.query.statementId;
	var commentText = req.query.commentText;
	var statementId = uuid.v4();
	var statement = {};
	statement.id = statementId;
	statement.actor = JSON.parse(actor);
	statement.verb = {"id":"http://registry.tincanapi.com/verbs/commented", "display":{"en-US":"commented on"}};
	statement.context = {};
	statement.context.statement = {
	        "objectType":"StatementRef",
	        "id": statementRef
	    };
	statement.object = {
	        "objectType":"StatementRef",
	        "id": statementRef
	    };
    statement.result = { 
            "response" : commentText
        }

	putStatementToLrs('statements', statement, function(data){
		console.log(data);
	});
	
});

var port = process.env.PORT || 5000;
app.listen(port);
console.log('Listening on port '+port);

