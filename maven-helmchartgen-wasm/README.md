# How to build this WASM Transformer

1. Ensure you have the [TinyGo](https://tinygo.org/) compiler installed. The official Golang compiler doesn't fully support WASM exports yet https://github.com/golang/go/issues/65199
2. Run the following command:
```
$ tinygo build -o helmchartgen.wasm -target=wasi transformer.go
```