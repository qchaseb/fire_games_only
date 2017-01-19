var SMTPServer = require('smtp-server').SMTPServer;
var options;
var server = new SMTPServer({
    onConnect: function(session, callback){
    	console.log("x")
        if(session.remoteAddress === '127.0.0.1'){
            return callback(new Error('No connections from localhost allowed'));
        }
        return callback(); // Accept the connection
    },
    onClose: function(){
    	console.log("a connection closed")
    },
    onData: function() {
    	console.log("data")
    }

});

server.on('error',function(err) {
	console.log(err)
})

server.listen(8080,function(){
	console.log("listening on port 8080!")
})


