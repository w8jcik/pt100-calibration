default:
	make server

server:
	PORT=4444 coffee push.coffee

client-once:
	coffee -c public/client.coffee

client:
	coffee -cw public/client.coffee
