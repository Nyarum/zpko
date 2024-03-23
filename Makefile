
install:
	git clone git@github.com:Nyarum/zig-lmdb.git libs/zig-lmdb

run:
	zig build
	./zig-out/bin/zpko