.PHONY: build
build:
	cd wasm-gen-svc-acc/gen-svc-acc/ && make build && cd - && rm -f wasm-gen-svc-acc.zip && zip -r wasm-gen-svc-acc.zip wasm-gen-svc-acc
	cd wasm-java-helm-chart/add-custom-files-dirs/ && make build && cd - && rm -f wasm-java-helm-chart.zip && zip -r wasm-java-helm-chart.zip wasm-java-helm-chart
