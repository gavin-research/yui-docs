// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@hyperledger-labs/yui-ibc-solidity/contracts/core/OwnableIBCHandler.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "../lib/PacketMssg.sol";
//noivern
contract MiniDelegateB1 is IIBCModule {
    IBCHandler ibcHandler;

    using BytesLib for *;

    address private owner;

    mapping (string => mapping(address => bool)) public access;
        
    mapping(address => string) private _mensajin;

    constructor(IBCHandler ibcHandler_) public {
        owner = msg.sender;

        ibcHandler = ibcHandler_;

        //para pruebas ahora, predeterminado el usuario puede acceder al registro 0x0541...712
        access["0x05416460deb76d57af601be17e777b93592d8d4d4a4096c57876a91c84f4a712"]
            [0xcBED645B1C1a6254f1149Df51d3591c6B3803007] = true;

        access["0x123456789012344567890bae4567e2cd135786421469cbe1acbedfff21462efa"]
            [0xcBED645B1C1a6254f1149Df51d3591c6B3803007] = false;
        access["0x123456789012344567890bae4567e2cd135786421469cbe1acbedfff21462efa"]
            [0x00731540cd6060991D6B9C57CE295998d9bC2faB] = true; 

    }

    event Mint(address indexed to, string message);

    event Cacneacall(address indexed to, bytes message);

    event Transfer(address indexed from, address indexed to, string message);

    event GrantAccess(address indexed entity, string certificate);


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


    function grantAccess (
        address entity,
        string memory certificate
    ) external {
        // TODO CACNEA FALTA COMPROBAR QUE EL MSG SENDER REALMENTE POSEE ESE CERTIFICADO
        access[certificate]
            [entity] = true;
        emit GrantAccess(
            entity,
            certificate);
    }



    function sendTransfer(
        string memory message,
        address receiver,
        string calldata sourcePort,
        string calldata sourceChannel,
        uint64 timeoutHeight
    ) external {

        if(access[message][msg.sender] == true){
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

        }else{
            _mensajin[msg.sender] = "NO ACCESS TO CERTIFICATION";
        }
    }


    function mint(address account, string memory message) external onlyOwner {
        require(_mint(account, message));
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


    //funcion que recibe un string, y en caso de que sea el esperado, ejecuta la funcion de envio
    //con el valor asociado
    function _cacneacall(bytes memory _mssg) internal returns (bool) {
        (address account, bytes memory message_s) = abi.decode(_mssg, (address, bytes));
        string memory data_s = string(message_s);
       
        if(keccak256(abi.encodePacked(data_s)) != keccak256(abi.encodePacked("FAILED"))){
           _mensajin[account] = data_s;

        }else{
           _mensajin[account] = "Permission = False";
        }

        emit Cacneacall(account, message_s);
        
        return true; //este return esta para comprobaciones, podria devolver un true y ya o nada
    }


    function _transfer( //cacnea
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

    /// Module callbacks ///

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
        //(address sendercontrato, string memory mensajillo) = abi.decode(data.message, (address, string));
        bytes memory message_s = abi.encode(data.receiver.toAddress(0), data.message); //aqui mandaria mensajillo en vez de data.message 
        
        //en el momento en el que la Blockchain 2 recibe un string, se invoca a cacneacall,
        //funcion provisional que simplifica el proceso de volver a invocar
        //la funcion de envio en caso de que haya recibido un codigo correcto
        //aqui hard-coded como "cacnea"

        bool respuesta = _cacneacall(message_s);

        return(_newAcknowledgement(respuesta));
            //_newAcknowledgement(_cacneacall(data.receiver.toAddress(0), data.message));
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

    //No tienes que preocuparte por canales ni puertos, usamos los 
    //de serie de YUI original, son muchas librerias y mejor no tocarlo
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


        //Nota Fun Fact:
        //Cacnea es un Pokemon que evoluciona a Cacturne. Empece a usarlo como mi "to do" en
        //el TFG para no confundirlo con la palabra todo (all) en espanol.
        //Evoluciono a meme interno y ahora ya lo meto en todas partes.

        //Aqui seria mas fitting poner un Pokemon que evoluciona por intercambio
        //por eso de que pasa de una blockchain a otra, como Haunter a Gengar,
        //pero es lo que hay. Cacnea.