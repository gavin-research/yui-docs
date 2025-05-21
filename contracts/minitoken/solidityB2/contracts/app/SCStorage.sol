// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

import "@hyperledger-labs/yui-ibc-solidity/contracts/core/OwnableIBCHandler.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "../lib/PacketMssg.sol";
//noivern

interface ISCData {
        function receivenewissuer(address _issuer, string calldata _issuerName) external returns (bool);

        function receivenewcert(string memory _cert, string memory _code, address hold) external returns(bool);
}
contract SCStorage is IIBCModule {
    IBCHandler ibcHandler;

    using BytesLib for *;

    address private owner;

    //mapping codigo del certificado - holder
    mapping(string => address) private holders; 
    //mapping codigo - superhash
    mapping (string => string) public certificate;
    //lista de issuers admitidos
    mapping(address => string) public listValidIssuers;

    string public lastIssuerTest;


    // direccion de scdata para call()
    address scdataaddr;
    ISCData scdata;
 

    constructor(IBCHandler ibcHandler_) public {
        owner = msg.sender;

        ibcHandler = ibcHandler_;
        scdataaddr = 0xff77D90D6aA12db33d3Ba50A34fB25401f6e4c4F; //SCDATA ADDRESS
        scdata = ISCData(scdataaddr);


    }

    

    event StoreCertificate(string certificate, string code);
    event Mint(address indexed to, string message);

    event Gavincall(address indexed to, bytes message);
    event CalledData(string cert, string code, address holder);

    event Transfer(address indexed from, address indexed to, string message);

    event Response(bool success, bytes data);

    event SendTransfer(
        address indexed from,
        address indexed to,
        string sourcePort,
        string sourceChannel,
        uint64 timeoutHeight,
        string message
    );

    event Error(string error);

    event LastIssuerTest(string lastIssuerTest);

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


function getlastIssuerTest() public view returns(string memory){
    return lastIssuerTest;
}


function getIssuer(address _add) public view returns(string memory){
    return listValidIssuers[_add];
}

// Se anade el hash salteado del cert, con su codigo correspondiente y a que usuario pertenece. Se envia
// el codigo y el hash salteado del certificado a la otra cadena mediante sendtransfer.
////
    function storeCertificate(
        string memory _certificate,
        string memory _code,
        address _holder) internal{
            certificate[_code] = _certificate;
            holders[_certificate] = _holder;
            emit StoreCertificate(_certificate, _code);

            bool success = scdata.receivenewcert(_certificate, _code, _holder);

             emit CalledData(_certificate,_code,_holder);
    }

    function storeIssuer(
        address issuer,
        string memory issuerName
    ) internal {
        //NOIVERn
        listValidIssuers[issuer]=issuerName;

        bool success = scdata.receivenewissuer(issuer, issuerName);
        //(bool success, bytes memory data) = scdataaddr.call{gas: 1000000}
        //(abi.encodeWithSignature("receivenewissuer(address, string)", issuer, issuerName));

    }

    function getCertificate(string calldata _codigo) public view returns(string memory){
        return certificate[_codigo];
    }


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


    //funcion de recepcion del paquete de datos, desempaqueta la informacion

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
        bytes memory message_s = abi.encode(data.receiver.toAddress(0), data.message); 
        
        lastIssuerTest = data.message;
        
        bytes memory strBytes = bytes(data.message);

        if ((strBytes[0] == 'I')&&(strBytes[1] == '0')&&
        (strBytes[2] == 'x')&&(strBytes[3] == 'I')){
            //si es un issuer...
            
            storeIssuer(data.receiver.toAddress(0), data.message);


        }else{
            //si es un certificado...
            //Separar los dos strings, para almacenar el certificado y el codigo llamando a storeCertificate()
            (string memory certificado, string memory code, address issuer) = abi.decode(bytes(data.message), (string, string, address));
        
            //comprobar que isssuer  esta registrado. si no lo esta no ejecuta el storecertificate y el certificado no se envia a scdata
            if (bytes(listValidIssuers[issuer]).length != 0){
                //Almacena el certificado y el codigo y el holder
                storeCertificate(certificado, code, data.receiver.toAddress(0));
            }

        }

        
        bool respuesta = true;

        return(_newAcknowledgement(respuesta));
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


