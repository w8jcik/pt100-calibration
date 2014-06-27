default:
	make calibrate

memory:
	coffee -cw memory.coffee

io:
	coffee -cw io.coffee

cpu:
	coffee -cw cpu.coffee

calibrate:
	coffee -cw calibrate.coffee

distributed:
	coffee -cw distributed.coffee
