structure Eth :> ETH = struct
  fun send {ownMac, dstMac, ethType, ethPayload} = 
    let val ethHeader = (EthCodec.Header { 
            ethType = ethType,
            srcMac = ownMac,
            dstMac = dstMac
        })
    in
      EthCodec.encode ethHeader ethPayload
      |> toByteList 
      |> Netif.send
    end
end 