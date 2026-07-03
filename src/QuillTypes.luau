-- // TYPES // --

-- ## BASE ## --

export type QuillBaseDisconnect = () -> ()
export type QuillBaseCallback<T = any> = ( disconnect: QuillBaseDisconnect, old_value: T, value: T ) -> ()
export type QuillBaseValue<T = any> = QuillBaseCallback<T> | T

export type QuillBase<T = any, M = any> = {
    New: ( auto_replicate: QuillAutoReplicate, authority: QuillAuthority, meta_data: M, value: T ) -> Quill<T, M> & (( value: QuillBaseValue<T>? ) -> ()),
    TypeEqual: ( quill1: Quill<T, M>, quill2: Quill<T, M> ) -> boolean,
    
    __eq: ( quill1: Quill<T, M>, quill2: Quill<T, M> ) -> boolean,
    __call: ( self: Quill<T, M>, value: QuillBaseValue<T>? ) -> T,
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
    
    _callbacks: { QuillBaseCallback<T> }
}, {} :: QuillBase<T, M>)) & QuillBase<T, M>

-- // MAIN // --

return nil