# MIN OS — 최상위 Makefile (개발 진입점)
#   make deps        호스트 의존성 설치 (sudo)
#   make shell       MIN 컴포넌트 호스트 빌드 (build/)
#   make test        단위 테스트 + 헤드리스 셸 통합 테스트
#   make image       부팅 ISO 빌드 (sudo). SUITE=debian-trixie(기본)|ubuntu-noble
#   make run         QEMU GUI 실행 / make run-serial 시리얼 콘솔
#   make test-image  QEMU 자동 부팅·종료·재부팅 테스트 (sudo)
#   make image-arm64 / run-arm64 / test-image-arm64   ARM64 디스크 번들 (Android/Termux 용)
#   make bundle-android   out/minos-arm64/ 를 tar.zst 로 묶음
SHELL := /bin/bash
BUILD ?= build
SUITE ?= debian-trixie
ARCH  ?= amd64
ISO   ?= out/minos-dev-$(SUITE)-$(ARCH).iso
JOBS  ?= $(shell nproc)

ARM64_BUNDLE ?= out/minos-arm64

.PHONY: all deps shell test test-unit test-shell image run run-serial test-image clean distclean \
        image-arm64 run-arm64 run-arm64-vnc test-image-arm64 bundle-android

all: shell

deps:
	sudo scripts/install-deps.sh

shell:
	cmake -S . -B $(BUILD) -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
	cmake --build $(BUILD) -j $(JOBS)

test: test-unit test-shell

test-unit: shell
	cd $(BUILD) && ctest --output-on-failure

test-shell: shell
	tests/shell/run.sh $(BUILD)

image:
	sudo image/build.sh --suite $(SUITE) --arch $(ARCH) --output $(ISO)

run:
	image/qemu/run.sh $(ISO)

run-serial:
	image/qemu/run.sh --serial $(ISO)

test-image:
	sudo python3 -I tests/image/boot_test.py $(ISO)

image-arm64:
	sudo image/build.sh --suite $(SUITE) --arch arm64 --format disk --profile mobile --output $(ARM64_BUNDLE)

run-arm64:
	image/qemu/run.sh $(ARM64_BUNDLE)

run-arm64-vnc:
	image/qemu/run.sh --vnc 0 $(ARM64_BUNDLE)

test-image-arm64:
	sudo python3 -I tests/image/boot_test.py $(ARM64_BUNDLE) --out out/boot-test-arm64 --timeout 1800

bundle-android:
	tar -C out --zstd -cvf out/minos-android-arm64.tar.zst $(notdir $(ARM64_BUNDLE))
	@ls -la out/minos-android-arm64.tar.zst

clean:
	rm -rf $(BUILD)

distclean: clean
	sudo rm -rf image/work out
