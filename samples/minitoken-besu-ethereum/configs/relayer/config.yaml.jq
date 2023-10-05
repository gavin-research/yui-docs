{
  "global": {
    "timeout": "10s",
    "light-cache-size": 20
  },
  "chains": [
    {
      "chain": {
        "@type": "/relayer.chains.ethereum.config.ChainConfig",
        "chain_id": "ibc0",
        "eth_chain_id": 2018,
        "rpc_addr": "http://localhost:8645",
        "hdw_mnemonic": "math razor capable expose worth grape metal sunset metal sudden usage scheme",
        "hdw_path": "m/44'/60'/0'/0/0",
        "ibc_address": "0x702E40245797c5a2108A566b3CE2Bf14Bc6aF841"
      },
      "prover": {
        "@type": "/relayer.provers.mock.config.ProverConfig"
      }
    },
    {
      "chain": {
        "@type": "/relayer.chains.ethereum.config.ChainConfig",
        "chain_id": "ibc1",
        "eth_chain_id": 2019,
        "rpc_addr": "http://localhost:8646",
        "hdw_mnemonic": "math razor capable expose worth grape metal sunset metal sudden usage scheme",
        "hdw_path": "m/44'/60'/0'/0/0",
        "ibc_address": "0x702E40245797c5a2108A566b3CE2Bf14Bc6aF841"
      },
      "prover": {
        "@type": "/relayer.provers.mock.config.ProverConfig"
      }
    }
  ],
  "paths": {
    "ibc01": {
      "src": {
        "chain-id": "ibc0",
        "client-id": "mock-client-0",
        "connection-id": "connection-0",
        "channel-id": "channel-0",
        "port-id": "transfer",
        "order": "unordered",
        "version": "transfer-1"
      },
      "dst": {
        "chain-id": "ibc1",
        "client-id": "mock-client-0",
        "connection-id": "connection-0",
        "channel-id": "channel-0",
        "port-id": "transfer",
        "order": "unordered",
        "version": "transfer-1"
      },
      "strategy": {
        "type": "naive"
      }
    }
  }
}
