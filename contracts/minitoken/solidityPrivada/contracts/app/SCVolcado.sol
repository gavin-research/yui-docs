// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@hyperledger-labs/yui-ibc-solidity/contracts/core/OwnableIBCHandler.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "../lib/PacketMssg.sol";
//noivern
contract SCVolcado is IIBCModule {
    IBCHandler ibcHandler;

    using BytesLib for *;

    address private owner;

    address receiverVolcado;
    string sourcePort;
    string sourceChannel;
    uint64 timeoutHeight;

   //mapping the issuers validos en el modelo, address -> nombre de la entidad issuer
    mapping(address => string) private valid_issuers; 

    //mapping codigo del certificado - holder
    mapping(string => address) private holders; 
    //mapping codigo - superhash
    mapping (bytes => string) public certificate;
 

    constructor(IBCHandler ibcHandler_) public {
        owner = msg.sender;

        ibcHandler = ibcHandler_;

        //alice es holder de cert1 Cheddar
        holders["f377e3d8d733de42ec0069766cc8f10b1c5b0b9da03298eea13b196aca6b99e4"]=
        0xcBED645B1C1a6254f1149Df51d3591c6B3803007;
        
        //alice es holder de cert2 Glasha
        holders["e8a52816736f79e9fd4edd70047c59b1f2d514bb375eaa675feac1dd25a6033d"]=
        0xcBED645B1C1a6254f1149Df51d3591c6B3803007;


    //////////////////////////////////////////////////////////////////////////////////////////////

        //clave 1.1 - certificado Cheddar
        certificate["0xf73910ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd497930e"] =
            "f377e3d8d733de42ec0069766cc8f10b1c5b0b9da03298eea13b196aca6b99e4";

        //clave 1.2 - certificado Glasha
        certificate["0x66de0b546355b8dc6b244662365b8f75b20bddb2341fbd313a8492556d78c11e"] = 
         "e8a52816736f79e9fd4edd70047c59b1f2d514bb375eaa675feac1dd25a6033d";

    }

    event AddIssuer(address issuerAddy, string issuerName);
    event AddCertificate(string certificate, address indexed holder);
    event Mint(address indexed to, string message);

    event Gavincall(address indexed to, bytes message);

    event Transfer(address indexed from, address indexed to, string message);

    event SendTransfer(
        address indexed from,
        address indexed to,
        string sourcePort,
        string sourceChannel,
        uint64 timeoutHeight,
        string message
    );

    event Error(string error);

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

// Primero se han de establecer los parametros de la comunicacion.
// _receiverVolcado es la direccion del contrato en la otra cadena que recibe los datos.
// _sourcePort, _sourceChannel y _timeoutHeight son los datos de creacion del canal de comunicacion.
////
    function setCommParams(address _receiverVolcado, 
                        string memory _sourcePort, 
                        string memory _sourceChannel,
                        uint64 _timeoutHeight) external{
        receiverVolcado = _receiverVolcado;
        sourcePort = _sourcePort;
        sourceChannel = _sourceChannel;
        timeoutHeight = _timeoutHeight;

    }


    function addIssuer(
        address issuerAddy,
        string memory issuerName
    ) external{
        valid_issuers[issuerAddy] = issuerName;
        emit AddIssuer(issuerAddy, issuerName);
        
        string memory codeI0xI_IssuerName = string(abi.encode('I0xI', issuerName));
        sendTransfer(codeI0xI_IssuerName, issuerAddy, sourcePort, sourceChannel, timeoutHeight);
    }


// Se anade el hash salteado del cert, con su codigo correspondiente y a que usuario pertenece. Se envia
// el codigo y el hash salteado del certificado a la otra cadena mediante sendtransfer.
////
    function addCertificate(
        string memory _certificate,
        bytes memory _code,
        address _holder
        ) external{
            certificate[_code] = _certificate;
            holders[_certificate] = _holder;
            emit AddCertificate(_certificate, _holder);
            //msg.sender el BAF del issuer 
            string memory mensaje = string(abi.encode(_certificate, _code, msg.sender));
            
            sendTransfer(mensaje, _holder, sourcePort, sourceChannel, timeoutHeight);
            
    }

//
    function sendTransfer(
        string memory message,
        address receiver,
        string storage sourcePort,
        string storage sourceChannel,
        uint64 timeoutHeight
    ) internal {
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


    //recepcion de paquete

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
        
        bool respuesta = true;

        return(_newAcknowledgement(respuesta));
            //_newAcknowledgement(_gavincall(data.receiver.toAddress(0), data.message));
    }


    function onAcknowledgementPacket(
        Packet.Data calldata packet,
        bytes calldata acknowledgement,
        address relayer
    ) external virtual override onlyIBC {
        if (!_isSuccessAcknowledgement(acknowledgement)) {
           emit Error("ACK perdido");
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

}
