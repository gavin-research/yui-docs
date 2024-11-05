// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@hyperledger-labs/yui-ibc-solidity/contracts/core/OwnableIBCHandler.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "../lib/PacketMssg.sol";
//noivern
contract SCData is IIBCModule {
    IBCHandler ibcHandler;

    using BytesLib for *;

    address private owner;
    uint256 noivern = 0;

    //mapping que asocia cada codigo a su hash salteado y cifrado
    mapping (bytes => string) public certificate;

    //mapping verificador - ultima hash salteada cifrada recibida para la verificacion
    mapping(address => string) private _mensajin;

    constructor(IBCHandler ibcHandler_) public {
        owner = msg.sender;

        ibcHandler = ibcHandler_;

// datos para facilitar pruebas
        //codigo-certificado Cheddar
        certificate["0xf73910ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd497930e"] = 
        "f377e3d8d733de42ec0069766cc8f10b1c5b0b9da03298eea13b196aca6b99e4";

        //codigo-certificado Glasha
        certificate["0x66de0b546355b8dc6b244662365b8f75b20bddb2341fbd313a8492556d78c11e"] = 
        "e8a52816736f79e9fd4edd70047c59b1f2d514bb375eaa675feac1dd25a6033d";


    }

    event Noivern(uint256 noivern);

    event Mint(address indexed to, string message);

    event Gavincall(address indexed to, bytes message);

    event Burn(address indexed from, string message);

    event Transfer(address indexed from, address indexed to, string message);

    event SendTransfer(
        address indexed from,
        address indexed to,
        string sourcePort,
        string sourceChannel,
        uint64 timeoutHeight,
        string message
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "MiniMessage: caller is not the owner");
        _;
    }

    modifier onlyIBC() {
        require(
            msg.sender == address(ibcHandler),
            "MiniMessage: caller is not the ibcHandler"
        );
        _;
    }


    //La funcion aparece 2 veces (sendTransfer y sendTransfer2), 
    //una interna y otra externa, copiada para facilitar la visualizacion ahora mismo.

    //Lo suyo seria que la blockchain A que siempre va a enviar tenga la funcion externa y
    //la blockchain B que recibe datos, la interna. 
    //Esto es porque la A envia y es invocada desde fuera la funcion por un user 
    //o contrato, y en B es un "ejecutable" que se activan el momento en el que B recibe
    //un codigo valido asociado a un valor, que seria el solicitado desde A
    
    //sendTransfer contiene:
    // el mensaje: un string desde la version anterior
    // una address, del receptor. Aqui la address es la del verificador que solicita el dato. 
    // el resto de parametros refieren al canal del relayer empleado para enviar la informacion
    function sendTransfer(
        string memory message,
        address receiver,
        string calldata sourcePort,
        string calldata sourceChannel,
        uint64 timeoutHeight
    ) external {
        _sendPacket(
            MiniMessagePacketData.Data({
                message: message, 
                sender: abi.encodePacked(msg.sender),
                receiver: abi.encodePacked(receiver)
            }),
            sourcePort,
            sourceChannel,
            timeoutHeight
        );
        emit SendTransfer(
            msg.sender,
            receiver,
            sourcePort,
            sourceChannel,
            timeoutHeight,
            message
        );
    }

    function sendTransfer2(
        string memory message,
        address receiver,
        string memory sourcePort,
        string memory sourceChannel,
        uint64 timeoutHeight 
    ) internal {
        _sendPacket(
            MiniMessagePacketData.Data({
                message: message, 
                sender: abi.encodePacked(receiver),
                receiver: abi.encodePacked(receiver)
            }),
            sourcePort,
            sourceChannel,
            timeoutHeight
        );
        emit SendTransfer(
            msg.sender,
            receiver,
            sourcePort,
            sourceChannel,
            timeoutHeight,
            message
        );
    }


    function getCertificate(bytes calldata _codigo) public returns(string memory){
        noivern = noivern+1;
        emit Noivern(noivern);
        return certificate[_codigo];
    }

    function getNoivern() public  returns(uint256){
        emit Noivern(noivern);
        return noivern;
    }

    
    //unused functions on this project burn, mint
    function mint(address account, string memory message) external onlyOwner {
        require(_mint(account, message));
    }

    function burn(string memory message) external {
        require(_burn(msg.sender, message), "MiniMessage: failed to burn");
    }

    function transfer(address to, string memory message) external {
        bool res;
        string memory mssg;
        (res, mssg) = _transfer(msg.sender, to, message);
        require(res, mssg);
    }

    function balanceOf(address account) public view returns (string memory) {
        return _mensajin[account];
    }

    function _mint(address account, string memory message) internal returns (bool) {
        _mensajin[account] = message; //cacnea
        emit Mint(account, message);
        return true;
    }

//funcion que se llama desde SCStorage mediante call() para almacenar nuevos datos recibidos desde
//las blockchains privadas 
//Para diferenciar en SCAccess el origen del dato y como tratarlo, se codifica
//la informacion emitida aqui, originaria de SCStorage (y por lo tanto de SCVolcado en las
//blockchains privadas) con el prefijo "P0x".
    function receivenewcert(string memory _cert, bytes memory _code, address hold) external returns(bool){
        certificate[_code] = _cert;
        string memory codestr = string(abi.encodePacked("P", _code));
        sendTransfer2(codestr, hold, "transfer", "channel-0", 0);

        return true;
    }

    function receivenewissuer(address _issuer, string memory _issuerName) external returns(bool){
        sendTransfer2(_issuerName, _issuer, "transfer", "channel-0", 0);

        return true;
    }

//funcion de envio de la informacion automaticamente de vuelta a la cadena de acceso
    function _gavincall(bytes memory _mssg) internal returns (string memory) {
       (address account, bytes memory message_s) = abi.decode(_mssg, (address, bytes));
        string memory data_s = string(message_s);

        _mensajin[account] = "sendtransfer completed";
            
        sendTransfer2(certificate[message_s], account, "transfer", "channel-0", 0);
      
        emit Burn(account, "hola");
        
        emit Gavincall(account, message_s);
        
        return "ok"; 
    
    }

    function _burn(address account, string memory message) internal returns (bool) {        
        emit Burn(account, message);
        return true;
    }

    function _transfer( 
        address from,
        address to,
        string memory message
    ) internal returns (bool, string memory) {
        if (keccak256(abi.encodePacked(_mensajin[from] )) != keccak256(abi.encodePacked(message))) {
            return (false, "MiniMessage: Ese mensajin no esta");
        }
        _mensajin[from] = "";
        _mensajin[to] = message;
        emit Transfer(from, to, message);
        return (true, "");
    }

    //funcion para la recepcion de datos. 
    function onRecvPacket(Packet.Data calldata packet, address relayer)
        external
        virtual
        override
        onlyIBC
        returns (bytes memory acknowledgement)
    {
        MiniMessagePacketData.Data memory data = MiniMessagePacketData.decode(
            packet.data
        );
        bytes memory message_s = abi.encode(data.receiver.toAddress(0), data.message); //aqui mandaria mensajillo en vez de data.message 
        
        //en el momento en el que la Blockchain 2 recibe un string, se invoca a gavincall,
        //funcion que simplifica el proceso de volver a invocar
        //la funcion de envio a la cadena solicitante de manera automatica
        //en caso de que haya recibido un codigo correcto
        string memory respuesta = _gavincall(message_s);
        
        bool buleano = false;

        if(keccak256(abi.encodePacked((respuesta))) == keccak256(abi.encodePacked(("ok")))){
            buleano = true;
        }else{
            buleano = true;
        }
        return(_newAcknowledgement(buleano));
    }

    function onAcknowledgementPacket(
        Packet.Data calldata packet,
        bytes calldata acknowledgement,
        address relayer
    ) external virtual override onlyIBC {
        if (!_isSuccessAcknowledgement(acknowledgement)) {
            _refundTokens(MiniMessagePacketData.decode(packet.data));
        }
    }

    function onChanOpenInit(
        Channel.Order,
        string[] calldata connectionHops,
        string calldata portId,
        string calldata channelId,
        ChannelCounterparty.Data calldata counterparty,
        string calldata version
    ) external virtual override {}

    function onChanOpenTry(
        Channel.Order,
        string[] calldata connectionHops,
        string calldata portId,
        string calldata channelId,
        ChannelCounterparty.Data calldata counterparty,
        string calldata version,
        string calldata counterpartyVersion
    ) external virtual override {}

    function onChanOpenAck(
        string calldata portId,
        string calldata channelId,
        string calldata counterpartyVersion
    ) external virtual override {}

    function onChanOpenConfirm(
        string calldata portId,
        string calldata channelId
    ) external virtual override {}

    function onChanCloseConfirm(
        string calldata portId,
        string calldata channelId
    ) external virtual override {}

    function onChanCloseInit(
        string calldata portId,
        string calldata channelId
    ) external virtual override {}

    // Internal Functions //

    //Envia un paquete de datos (creado con la libreria PacketMssg)
    //por el canal especificado hasta la Blockchain B.
    //El enpaquetado se hace en bytes, la libreria ya la modificamos en el 
    //"paso anterior" de int a string para que cuente los saltos a dar para 
    //desenpaquetar correctamente. Es Packetmssg.sol, en ../lib
    function _sendPacket(
        MiniMessagePacketData.Data memory data, 
        string memory sourcePort,
        string memory sourceChannel,
        uint64 timeoutHeight
    ) internal virtual {
        (Channel.Data memory channel, bool found) = ibcHandler.getChannel(
            sourcePort,
            sourceChannel
        );
        require(found, "MiniMessage: channel not found");
        ibcHandler.sendPacket(
            Packet.Data({
                sequence: ibcHandler.getNextSequenceSend(
                    sourcePort,
                    sourceChannel
                ),
                source_port: sourcePort,
                source_channel: sourceChannel,
                destination_port: channel.counterparty.port_id,
                destination_channel: channel.counterparty.channel_id,
                data: MiniMessagePacketData.encode(data),
                timeout_height: Height.Data({
                    revision_number: 0,
                    revision_height: timeoutHeight
                }),
                timeout_timestamp: 0
            })
        );
    }

    function _newAcknowledgement(bool success)
        internal
        pure
        virtual
        returns (bytes memory)
    {
        bytes memory acknowledgement = new bytes(1);
        if (success) {
            acknowledgement[0] = 0x01;
        } else {
            acknowledgement[0] = 0x00;
        }
        return acknowledgement;
    }

    function _isSuccessAcknowledgement(bytes memory acknowledgement)
        internal
        pure
        virtual
        returns (bool)
    {
        require(acknowledgement.length == 1);
        return acknowledgement[0] == 0x01;
    }

//no aplica
    function _refundTokens(MiniMessagePacketData.Data memory data)
        internal
        virtual
    {
        require(_mint(data.sender.toAddress(0), data.message));
    }
}

