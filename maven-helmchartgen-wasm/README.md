# How to build this WASM Transformer

1. Ensure you have the [TinyGo](https://tinygo.org/) compiler installed. Move2Kube WASM modules currently do not support WASI modules built by the Go compiler.
2. Run the following command:
```
$ tinygo build -o helmchartgen.wasm -target=wasi transformer.go
```