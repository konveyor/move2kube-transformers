.PHONY: build
build:
	tinygo build -o maintiny.wasm -target=wasi main.go
	wasm2wat maintiny.wasm > maintiny.wat
