// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@hyperledger-labs/yui-ibc-solidity/contracts/core/OwnableIBCHandler.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "../lib/PacketMssg.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SCAccess is IIBCModule {
    IBCHandler ibcHandler;

    using BytesLib for *;

    address private owner;

    enum Acceso{
        no_registro, // por defecto
        acceso_total, //acceso mediante caso 1, usuario-tercero
        acceso_parcial, //acceso mediante caso 2, usuario-tercero info parcial
        acceso_usuario_y_terceros_total, //acceso mediante caso 3, usuario permite: issuer-tercero
        acceso_denegado //acceso otorgado previamente PERO ELIMINADO posteriormente
    }

    Acceso constant defaultaccess = Acceso.no_registro;

    address[][] public entidades1cert;
    address[][][] public entidades;

    //mapping codigo del certificado - holder
    mapping(string => address) private holders; 

    //mapping espejo del anterior para el getAccessList
    mapping(address => string[]) public holdersEspejo;
    //mapping codigo - verifier - permisos de acceso
    mapping (string => mapping(address => Acceso)) public access;
    //mapping provisional verifier - ultima hash cifrada y salteada recibida 
    mapping(address => string) private _mensajin;
    //mapping usuario - nonce para firmas
    mapping(address => uint256) private nonce_sign; 

//mappings necesarios para manejo sobre los tipos de acceso para cada verificador y certificado
    //mapping direccion - tipo de acceso
    mapping(address => mapping(address => Acceso)) public accesslist;
    //mapping holder - certificados de ese holder - tipos de acceso - verifiers para cada tipo de accceso
    mapping(address => mapping(string => mapping(Acceso => address[]))) public accesslista;
    //mapping holder - entidades-certificado-tipo de acceso
    mapping(address => address[][][]) public userEntidades;

//estructura de firma empleada para validar al usuario
    struct FirmaValidacion {
        bytes32 _hashCodeCert;
        bytes32 _r;
        bytes32 _s;
        uint8 _v;
    }

//parametros para las conexiones del relayer
    struct RelayerParams {
        string  sourcePort;
        string  sourceChannel;
        uint64 timeoutHeight;
    }

    constructor(IBCHandler ibcHandler_) public {
        owner = msg.sender;

        ibcHandler = ibcHandler_;
        // se anaden parametros para facilitar los tests y pruebas
        //alice es holder de cert1 Cheddar
        holders["0xf73910ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd497930e"]=
        0xcBED645B1C1a6254f1149Df51d3591c6B3803007;
        
        //alice es holder de cert2 Glasha
        holders["0x66de0b546355b8dc6b244662365b8f75b20bddb2341fbd313a8492556d78c11e"]=
        0xcBED645B1C1a6254f1149Df51d3591c6B3803007;

        //bob es holder de cert3 Moon
        holders["0x116ba6d1a2621ebd1f086f00ddfe556ca5dd7c140c01fa0c56c0361448a50fcb"]=
        0x00731540cd6060991D6B9C57CE295998d9bC2faB;



        //espejo del anterior con lista de certificados que posee
        holdersEspejo[0xcBED645B1C1a6254f1149Df51d3591c6B3803007]=
        ["0xf73910ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd497930e",
        "0x66de0b546355b8dc6b244662365b8f75b20bddb2341fbd313a8492556d78c11e"];

        holdersEspejo[0x00731540cd6060991D6B9C57CE295998d9bC2faB]=
        ["0x116ba6d1a2621ebd1f086f00ddfe556ca5dd7c140c01fa0c56c0361448a50fcb"];
 


    //////////////////////////////////////////////////////////////////////////////////////////////

        //alice puede acceder al certificado Cheddar con esta clave, la clave 1.1
        access["0xf73910ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd497930e"]
            [0xcBED645B1C1a6254f1149Df51d3591c6B3803007] =  Acceso.acceso_total;

        //alice puede acceder al certificado Glasha con esta clave, la clave 1.2
        access["0x66de0b546355b8dc6b244662365b8f75b20bddb2341fbd313a8492556d78c11e"]
            [0xcBED645B1C1a6254f1149Df51d3591c6B3803007] = Acceso.acceso_total;

        //bob no puede acceder a nada de alice hasta que alice no le de acceso
        ////

        //bob puede acceder al certificado Moon con esta clave, la clave 2.1
        access["0x116ba6d1a2621ebd1f086f00ddfe556ca5dd7c140c01fa0c56c0361448a50fcb"]
            [0x00731540cd6060991D6B9C57CE295998d9bC2faB] =  Acceso.acceso_total;

        //holder, certificado, nvl acceso, verifiers
        //alice
        accesslista[0xcBED645B1C1a6254f1149Df51d3591c6B3803007]
            ["0xf73910ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd497930e"]
            [Acceso.acceso_total] = 
            [0xcBED645B1C1a6254f1149Df51d3591c6B3803007, 0xa89F47C6b463f74d87572b058427dA0A13ec5425];
        accesslista[0xcBED645B1C1a6254f1149Df51d3591c6B3803007]
            ["0xf73910ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd497930e"]
            [Acceso.acceso_parcial] =
            [0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5, 0x478D97356251BF1F1e744587E67207dAb100CaDb];
        accesslista[0xcBED645B1C1a6254f1149Df51d3591c6B3803007]
            ["0x66de0b546355b8dc6b244662365b8f75b20bddb2341fbd313a8492556d78c11e"]
            [Acceso.acceso_total] = 
            [0xcBED645B1C1a6254f1149Df51d3591c6B3803007, 0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97];

        //bob
        accesslista[0x00731540cd6060991D6B9C57CE295998d9bC2faB]
            ["0x116ba6d1a2621ebd1f086f00ddfe556ca5dd7c140c01fa0c56c0361448a50fcb"]
            [Acceso.acceso_total] = 
            [0x00731540cd6060991D6B9C57CE295998d9bC2faB, 0x333343333CE9647Bdf1e7877bf73ce8b0Bad5F97];
        
    }



    event Mint(address indexed to, string message);

    event Gavincall(address indexed to, bytes message);

    event Transfer(address indexed from, address indexed to, string message);

    event ModifyAccess(address indexed entity, string certificate, Acceso access);

    event NonceSign(uint256 nonce);

    event EventoCacnea(bytes32 firmaHashCode, bytes32 abiFirmaHashCode, bytes noncebytes,uint256 nonce);

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


    function getNonce(address user) public view returns (uint256){
        return nonce_sign[user];
    }

    //Crea una lista de verificadores con diferentes tipos de acceso sobre los certificados
    //poseidos por holder.
    function getAccessList(address holder) public{
        string[] storage certificates = holdersEspejo[holder];
        
        delete entidades;
        delete entidades1cert;

        Acceso[4] memory tipo_de_acceso = [Acceso.acceso_total, Acceso.acceso_parcial, 
                Acceso.acceso_usuario_y_terceros_total, Acceso.acceso_denegado];

        for(uint256 i = 0; i < certificates.length; i++){
            for(uint j = 0; j < 4; j++){
                Acceso acceso = tipo_de_acceso[j];
                address[] memory entidad = accesslista[holder][certificates[i]][acceso];
                entidades1cert.push(entidad);
            }
            entidades.push(entidades1cert);
            delete entidades1cert;
        }
        userEntidades[holder] = entidades;
        
    }

//Devuelve las entidades a las que el holder ha dado permiso de acceso y a que certificados.
    function getEntidades(address holder, FirmaValidacion calldata firma) public view returns (address[][][] memory) {
        address signer = _getSigner(firma);
        require(firma._hashCodeCert == keccak256(abi.encodePacked(Strings.toString(nonce_sign[signer]))), "Invalid signer");
        require(holder == signer, "Invalid signer. Msg signer is not the user requested.");

        
        return userEntidades[holder];
    }

//Permite al usuario, tras verificarse con su firma, modificar el tipo de acceso accessvalue que ha dado a
// un verificador entity sobre un certificado certificate
     function modifyAccess(
        address entity,
        string memory certificate,
        FirmaValidacion calldata firma,
        Acceso accessvalue
    ) external {
        address signer = _getSigner(firma);
        require(firma._hashCodeCert == keccak256(abi.encodePacked(Strings.toString(nonce_sign[signer]))), "Invalid signer");
        require(holders[certificate] == signer, "Invalid signer 2");

        nonce_sign[signer] = nonce_sign[signer] + 1;
        //se anade al mapping access la nueva informacion
        access[certificate][entity] = accessvalue;

        //se borra el tipo de acceso previo en el array antes de guardar el nuevo
        Acceso[4] memory tipo_de_acceso = [Acceso.acceso_total, Acceso.acceso_parcial, 
                Acceso.acceso_usuario_y_terceros_total, Acceso.acceso_denegado];
        for(uint j = 0; j < 4; j++){
                Acceso acceso = tipo_de_acceso[j];
                address[] storage entidad = accesslista[signer][certificate][acceso];
                
                for(uint i=0; i < entidad.length; i++){
                    if(entidad[i] == entity){
                        for (uint k = i; k < entidad.length - 1; k++) {
                            entidad[k] = entidad[k + 1];
                        }
                        entidad.pop();
                    } 
                }
            }
        //ya borrado el valor anterior, se anade al mapping accesslista la nueva informacion   
        accesslista[signer][certificate][accessvalue].push(entity);

        emit ModifyAccess(
            entity,
            certificate,
            accessvalue);
    }

//funcion para verificar la firma del usuario
     function _getSigner(FirmaValidacion memory firma) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, firma._hashCodeCert));
        address signer = ecrecover(prefixedHashMessage, firma._v, firma._r, firma._s);
        
        return signer;
    }

//funcion para enviar un dato message a la otra cadena mediante el relayer
    function sendTransfer(
        string memory message,
        address receiver,
        RelayerParams calldata param,
        FirmaValidacion calldata firma
    ) external {
        address signer = _getSigner(firma);
        require(firma._hashCodeCert == keccak256(abi.encodePacked(Strings.toString(nonce_sign[signer]))), "Invalid signer");
        
        nonce_sign[signer] = nonce_sign[signer] + 1;

        if((access[message][signer] == Acceso.acceso_total) || 
            (access[message][signer] == Acceso.acceso_parcial) || 
            (access[message][signer] == Acceso.acceso_usuario_y_terceros_total) ||
            (holders[message] == signer)){
            _sendPacket(
                MiniMessagePacketData.Data({
                    message: message, 
                    sender: abi.encodePacked(signer),
                    receiver: abi.encodePacked(receiver)
                }),
                param.sourcePort,
                param.sourceChannel,
                param.timeoutHeight
            );
            emit SendTransfer(
                signer,
                receiver,
                param.sourcePort,
                param.sourceChannel,
                param.timeoutHeight,
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
    function _gavincall(bytes memory _mssg) internal returns (bool) {
        // entei, que pasa si recibe de scstorage-scdata (address account, bytes memory )
        (address account, bytes memory message_s) = abi.decode(_mssg, (address, bytes));
        string memory data_s = string(message_s);
        
        //la funcion detecta si el origen del dato es de un usuario o de SCVolcado (y por lo tanto, un
        //dato nuevo). Si el dato hexadecimal comienza por P, es un dato de SCVolcado, y 
        //por lo tanto, se anade a la lista de codigos registrados.
        //En caso contrario, es un dato solicitado por un usuario recibido de SCData, y se envia
        //al verificador
        bytes memory strBytes = bytes(data_s);
        if (strBytes[0] == 'P') {
            bytes memory result = new bytes(strBytes.length - 1);
            for (uint i = 1; i < strBytes.length; i++) {
                result[i - 1] = strBytes[i];
            }
            string memory newdata = string(result); //el code del certificado

            //se guarda el code del certificado en holders y holdersEspejo
            holders[newdata] = account;
            holdersEspejo[account].push(newdata);
            //se anade al holder del certificado con acceso total sobre el mismo
            access[newdata][account] = Acceso.acceso_total;
            accesslista[account][newdata][Acceso.acceso_total].push(account);
           

        }else{      
       
        if(keccak256(abi.encodePacked(data_s)) != keccak256(abi.encodePacked("FAILED"))){
           _mensajin[account] = data_s;

        }else{
           _mensajin[account] = "Permission = False";
        }
        
        }
        emit Gavincall(account, message_s);
        return true; //este return esta para comprobaciones, podria devolver un true y ya o nada
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
        
        //en el momento en el que la Blockchain 2 recibe un string, se invoca a gavincall,
        //funcion provisional que simplifica el proceso de volver a invocar
        //la funcion de envio en caso de que haya recibido un codigo correcto
        //aqui hard-coded como "cacnea"

        bool respuesta = _gavincall(message_s);

        return(_newAcknowledgement(respuesta));
            //_newAcknowledgement(_gavincall(data.receiver.toAddress(0), data.message));
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