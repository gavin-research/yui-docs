DOCKER_COMPOSE ?= docker compose
TRUFFLE ?= npx truffle
TEST_OPTS ?= --compile-none --migrate-none

# setup
.PHONY: setup setupPr setup2 down
setup: build network sleep migrate 
setupPr: buildPr sleep migratePr
setup2: build2 sleep migrate2 
relayer01: handshake relayer-start
#new!!
#-anadir scstorage a ibc1 y handler mockclient...
relayerPr1: handshakePr relayer-startPr 


down: relayer-stop network-down

# build
.PHONY: build build-contract build-relayer 
build: build-contract build-relayer build-container
build2: build-contract2 
buildPr: build-contractPr build-relayer

build-contract:
	@make -C ../../contracts/minitoken/solidity build

build-contract2:
	@make -C ../../contracts/minitoken/solidityB2 build2

build-contractPr:
	@make -C ../../contracts/minitoken/solidityPrivada buildPr

build-relayer:
	@make -C relayer build

build-container:
	@make -C chains build

# network
.PHONY: network network-down
network:
	@make -C chains network

network-down:
	@make -C chains network-down

# contract migration
.PHONY: migrate
migrate:
	npm run migrate:ibc0
migrate2:
	npm run migrate:ibc1
migratePr:
	npm run migrate:ibc2

# relayer
.PHONY: handshake handshakePr relayer-start relayer-startPr relayer-stop
handshake:
	./scripts/init-rly

handshakePr:
	./scripts/init-rlyPr

relayer-start:
	./scripts/relayer-start

relayer-startPr:
	./scripts/relayer-startPr

relayer-stop:
	./scripts/relayer-stop

# textlint
.PHONY: lint
lint:
	npm run lint

.PHONY: e2e
# Network must be up and running, reayer must be up after handshake
# Note: The reason why besu_test and geth_test are specified in network during test is
# to prevent redeployment of contract.
e2e:
	${TRUFFLE} exec test/0-init.js --network=ibc0 \
	&& sleep 3 \
	&& ${TRUFFLE} test test/0-init.test.js --network=ibc0 ${TEST_OPTS} \
	&& ${TRUFFLE} exec test/1-send.js --network=ibc0 \
	&& sleep 3 \
	&& ${TRUFFLE} test test/1-send.test.js --network=ibc0 ${TEST_OPTS} \
	&& sleep 3 \
	&& ${TRUFFLE} test test/2-ibc1.test.js --network=ibc1 ${TEST_OPTS} \
	&& ${TRUFFLE} test test/3-ibc0.test.js --network=ibc0 ${TEST_OPTS}

.PHONY: sleep
sleep:
	sleep 5
