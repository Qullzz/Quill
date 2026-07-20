-- // TYPES // --

-- ## BASE ## --

export type BaseDisconnect = () -> ()
export type BaseOnceCallback<T = any> = ( value: T, prevValue: T, replicate: BaseReplicate? ) -> ()
export type BaseConnectCallback<T = any> = ( value: T, prevValue: T, disconnect: BaseDisconnect, replicate: BaseReplicate? ) -> ()
export type BaseReplicate = boolean

export type Base<T = any, V = any> = {
    Clone: ( self: T, value: V? ) -> T,
    Once: ( self: T, callback: BaseOnceCallback<V> ) -> BaseDisconnect,
    Connect: ( self: T, callback: BaseConnectCallback<V> ) -> BaseDisconnect,
    TypeEqual: ( self: T, component: T ) -> boolean,
    Size: ( self: T, buff: buffer? ) -> ComponentSize,
    Serialize: ( self: T, replication: BaseReplicate? ) -> buffer,
    Deserialize: ( self: T, buff: buffer, replication: BaseReplicate? ) -> V,
    SafeWrite: ( self: T, value: V ) -> (),
    SafeGet: ( self: T ) -> V,
    
    __eq: ( self: T, component: T ) -> boolean,
    __index: Base<T, V>?
}

-- ## COMPONENT ## --

export type ComponentAutoReplicate = BaseReplicate
export type ComponentAuthority = "server" | "client"
export type ComponentConvert<T = any> = ( value: any ) -> T?
export type ComponentSize = number

export type Component<T = any, B = any> = typeof(setmetatable({} :: {
    autoReplicate: ComponentAutoReplicate,
    authority: ComponentAuthority,
    value: T,
    
    convert: ComponentConvert<T>?,
    
    _callbacks: {
        {
            callback: BaseOnceCallback<T> | BaseConnectCallback<T>,
            disconnect: BaseDisconnect,
            once: boolean
        }
    }
}, {} :: Base<Component<T, B>, T>)) & B

-- ## PROPERTIES ## --

export type Properties<T = {}> = {
    mock: boolean,
    reset: boolean,
    environment: string?,
    
    templates: {
        previousTemplates: { PlayerData },
        
        currentTemplate: PlayerData<T>
    }
}

-- ## PLAYER ## --

export type PlayerDataID = number
export type PlayerDataKey = string
export type PlayerDataValue = Component<any, Base<Component<any, any>, any>>

export type PlayerData<T = { [PlayerDataKey]: PlayerDataValue }> = T
export type PlayersData<T = { [PlayerDataKey]: PlayerDataValue }> = { [Player]: PlayerData<T> }

-- // MAIN // --

return nil
