-- // TYPES // --

-- ## BASE ## --

export type QuillBaseDisconnect = () -> ()
export type QuillBaseOnceCallback<T = any> = ( old_value: T, value: T ) -> ()
export type QuillBaseConnectCallback<T = any> = ( disconnect: QuillBaseDisconnect, old_value: T, value: T ) -> ()

export type QuillBase<T = any, M = any> = {
    New: ( auto_replicate: QuillAutoReplicate, authority: QuillAuthority, meta_data: M, value: T ) -> Quill<T, M> & (( value: T? ) -> T),
    TypeEqual: ( quill1: Quill<T, M>, quill2: Quill<T, M> ) -> boolean,
    Once: ( self: Quill<T, M>, callback: QuillBaseOnceCallback<T> ) -> QuillBaseDisconnect,
    Connect: ( self: Quill<T, M>, callback: QuillBaseConnectCallback<T> ) -> QuillBaseDisconnect,
    
    __eq: ( quill1: Quill<T, M>, quill2: Quill<T, M> ) -> boolean,
    __call: ( self: Quill<T, M>, value: T? ) -> T,
    __index: QuillBase<T, M>?
}

-- ## QUILL ## --

export type QuillAutoReplicate = boolean
export type QuillAuthority = "server" | "client"

export type Quill<T = any, M = any> = typeof(setmetatable({} :: {
    auto_replicate: QuillAutoReplicate,
    authority: QuillAuthority,
    meta_data: M,
    value: T,
    
    _callbacks: {
        {
            callback: QuillBaseOnceCallback<T> | QuillBaseConnectCallback<T>,
            disconnect: QuillBaseDisconnect,
            once: boolean
        }
    }
}, {} :: QuillBase<T, M>)) & QuillBase<T, M>

-- // MAIN // --

return nil