structure RSV = struct 
    datatype receive_seqvar = RSV of {
        nxt : int,
        wnd : int,
        up  : int,
        irs : int
    }

    fun update_nxt f (RSV {nxt, wnd, up, irs}) = 
        RSV {nxt = f nxt, wnd = wnd, up = up, irs = irs}

    fun update_wnd f (RSV {nxt, wnd, up, irs}) = 
        RSV {nxt = nxt, wnd = f wnd, up = up, irs = irs}

    fun update_up f (RSV {nxt, wnd, up, irs}) = 
        RSV {nxt = nxt, wnd = wnd, up = f up, irs = irs}

    fun update_irs f (RSV {nxt, wnd, up, irs}) = 
        RSV {nxt = nxt, wnd = wnd, up = up, irs = f irs}

end