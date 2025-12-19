structure SSV = struct
    datatype send_seqvar = SSV of {
        una : int,
        nxt : int,
        wnd : int,
        up  : int,
        wl1 : int,
        wl2 : int,
        mss : int,
        iss : int
    }

    fun update_una f (SSV {una, nxt, wnd, up, wl1, wl2, mss, iss}) =
        SSV {una = f una, nxt = nxt , wnd = wnd, up = up, wl1 = wl1, wl2 = wl2, mss = mss, iss = iss}

    fun update_nxt f (SSV {una, nxt, wnd, up, wl1, wl2, mss, iss}) =
        SSV {una = una, nxt = f nxt , wnd = wnd, up = up, wl1 = wl1, wl2 = wl2, mss = mss, iss = iss}

    fun update_wnd f (SSV {una, nxt, wnd, up, wl1, wl2, mss, iss}) =
        SSV {una = una, nxt = nxt , wnd = f wnd, up = up, wl1 = wl1, wl2 = wl2, mss = mss, iss = iss}
        
    fun update_up f (SSV {una, nxt, wnd, up, wl1, wl2, mss, iss}) =
        SSV {una = una, nxt = nxt , wnd = wnd, up = f up, wl1 = wl1, wl2 = wl2, mss = mss, iss = iss}
        
    fun update_wl1 f (SSV {una, nxt, wnd, up, wl1, wl2, mss, iss}) =
        SSV {una = una, nxt = nxt , wnd = wnd, up = up, wl1 = f wl1, wl2 = wl2, mss = mss, iss = iss}
        
    fun update_wl2 f (SSV {una, nxt, wnd, up, wl1, wl2, mss, iss}) =
        SSV {una = una, nxt = nxt , wnd = wnd, up = up, wl1 = wl1, wl2 = f wl2, mss = mss, iss = iss}
        
    fun update_mss f (SSV {una, nxt, wnd, up, wl1, wl2, mss, iss}) =
        SSV {una = una, nxt = nxt , wnd = wnd, up = up, wl1 = wl1, wl2 = wl2, mss = f mss, iss = iss}
        
    fun update_iss f (SSV {una, nxt, wnd, up, wl1, wl2, mss, iss}) =
        SSV {una = una, nxt = nxt , wnd = wnd, up = up, wl1 = wl1, wl2 = wl2, mss = mss, iss = f iss}

end 