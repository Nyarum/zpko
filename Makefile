
install:
	git clone git@github.com:Nyarum/zig-lmdb.git libs/zig-lmdb

run:
	zig build -Doptimize=Debug
	lldb zig-out/bin/zpko