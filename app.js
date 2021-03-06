// load .env file if it exists
var connect = require('connect');
var request = require('request');
var citeproc = require('./src/citeproc');
var doi = require('./src/doi');

function init() {
	console.log("creating server...");

	var server = connect();
	server.use(connect.query());
	server.use(connect.logger());
	server.use(connect.static('./public'));
	server.use(connect.json());

	server.use('/styles', listHandler(citeproc.getStyles()));
	server.use('/locales', listHandler(citeproc.getLocales()));
	server.use('/format', method("GET", formatHandler));
	server.use('/format', method("POST", formatPostHandler));

	server.listen();
}

function listHandler(array) {
	return function(req, res) {
		var json = JSON.stringify(array);
		sendResponse(res, 200, json, {
			"Content-Type" : "application/json"
		});
	};
}

function method(method, handler) {
	return function(req, res, next) {
		if (method == req.method)
			handler(req, res, next);
		else
			next();
	};
}

function formatPostHandler(req, res) {
	citeproc.format(
			req.body,
			req.query.style,
			req.query.lang,
			function(text) {
				sendResponse(res, 200, text);
			}, function(msg) {
				sendResponse(res, 400, msg);
			}
	);
}

function formatHandler(req, res) {
	var query = req.query;
	var doi = query.doi;
	if (doi == undefined)
		sendResponse(res, 400, "doi param required");
	else {
		require("./src/doi").resolve(
				doi,
				function(data) {
					try {
						req.body = JSON.parse(data);
						formatPostHandler(req, res);
					} catch (err) {
						sendResponse(res, 500, "error while formatting: "
								+ err.message);
					}
				},
				function(code, msg) {
					sendResponse(res, code, msg);
				},
				"application/vnd.citationstyles.csl+json");
	}
}

function sendResponse(res, code, body, options) {
	if (options == null)
		options = {};
	if (options["Content-Type"] == undefined)
		options["Content-Type"] = "text/plain";
	res.writeHead(code, options);
	res.write(body);
	res.end();
}

init();
