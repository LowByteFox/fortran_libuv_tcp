module uv
    use iso_c_binding
    implicit none

    type, bind(C) :: uv_buf
        type(c_ptr) :: base
        integer(c_size_t) :: len
    end type

    interface
        function uv_default_loop() bind(C)
            use iso_c_binding
            type(c_ptr) :: uv_default_loop
        end function uv_default_loop

        function uv_tcp_init(loop, tcp) bind(C)
            use iso_c_binding
            type(c_ptr), value :: loop, tcp
            integer(c_int) :: uv_tcp_init
        end function uv_tcp_init

        function uv_ip4_addr(ip, port, addr) bind(C)
            use iso_c_binding
            character(c_char) :: ip(*)
            integer(c_int), value :: port
            type(c_ptr), value :: addr
            integer(c_int) :: uv_ip4_addr
        end function uv_ip4_addr

        function uv_tcp_bind(server, addr, flags) bind(C)
            use iso_c_binding
            type(c_ptr), value :: server, addr
            integer(c_long), value :: flags
            integer(c_int) :: uv_tcp_bind
        end function uv_tcp_bind

        function uv_listen(stream, backlog, cb) bind(C)
            use iso_c_binding
            type(c_ptr), value :: stream
            integer(c_int), value :: backlog
            type(c_funptr), value :: cb
            integer(c_int) :: uv_listen
        end function uv_listen

        function uv_run(loop, mode) bind(C)
            use iso_c_binding
            type(c_ptr), value :: loop
            integer(c_int), value :: mode
            integer(c_int) :: uv_run
        end function uv_run

        function uv_accept(client, stream) bind(C)
            use iso_c_binding
            type(c_ptr), value :: client, stream
            integer(c_int) :: uv_accept
        end function uv_accept

        subroutine uv_close(client, cb) bind(C)
            use iso_c_binding
            type(c_ptr), value :: client
            type(c_funptr), value :: cb
        end subroutine uv_close

        function uv_read_start(client, acb, rcb) bind(C)
            use iso_c_binding
            type(c_ptr), value :: client
            type(c_funptr), value :: acb, rcb
            integer(c_int) :: uv_read_start
        end function uv_read_start

        function uv_write(req, handle, bufs, nbuf, cb) bind(C)
            use iso_c_binding
            type(c_ptr), value :: req, handle, bufs
            integer(c_int), value :: nbuf
            type(c_funptr), value :: cb
            integer(c_int) :: uv_write
        end function uv_write

        function c_malloc(sz) bind(C, name="malloc")
            use iso_c_binding
            integer(c_size_t), value :: sz
            type(c_ptr) :: c_malloc
        end function c_malloc

        subroutine c_free(ptr) bind(C, name="free")
            use iso_c_binding
            type(c_ptr), value :: ptr
        end subroutine c_free
    end interface
end module uv

module x
    use iso_c_binding
    use uv
    use uv_sizes
    implicit none

    type(c_ptr) :: loop
contains
    subroutine on_connection(server, stat) bind(C)
        use iso_c_binding
        implicit none

        type(c_ptr), value :: server
        integer(c_int), value :: stat

        type(c_ptr) :: client
        integer(c_int) :: res

        client = c_malloc(uv_tcp_size)

        res = uv_tcp_init(loop, client)

        res = uv_accept(server, client)

        if (res .eq. 0) then
            res = uv_read_start(client, c_funloc(alloc_buffer), c_funloc(on_read))
        else
            call uv_close(client, c_null_ptr)
        end if

    end subroutine on_connection

    subroutine alloc_buffer(handle, suggest, buf) bind(C)
        type(c_ptr), value :: handle
        type(uv_buf) :: buf
        integer(c_long), value :: suggest

        buf%base = c_malloc(suggest)
        buf%len = suggest
    end subroutine alloc_buffer

    subroutine after_write(handle, stat) bind(C)
        type(c_ptr), value :: handle
        integer(c_int), value :: stat

        call c_free(handle)
    end subroutine after_write

    subroutine on_read(handle, nread, buf) bind(C)
        type(c_ptr), value :: handle
        integer(c_long), value :: nread
        type(uv_buf) :: buf

        type(c_ptr) :: req
        type(uv_buf), target :: buf2
        integer(c_int) :: res

        if (nread .lt. 0) then
            if (.not. nread .eq. UV_EOF) then
                print *, "oops"
                call uv_close(handle, c_null_ptr)
            end if 
        else if (nread .gt. 0) then
            req = c_malloc(uv_write_size)
            buf2%base = buf%base
            buf2%len = nread

            res = uv_write(req, handle, c_loc(buf2), 1, c_funloc(after_write))
        end if

        if (c_associated(buf%base)) then
            call c_free(buf%base)
        end if
    end subroutine on_read
end module x

program echo_server
    use iso_c_binding
    use x
    use uv
    use uv_sizes
    implicit none

    type(c_ptr) :: server
    type(c_ptr) :: addr_in
    integer(c_int) :: res
    integer(c_long) :: flags = 0
    
    loop = uv_default_loop()
    server = c_malloc(uv_tcp_size)
    addr_in = c_malloc(sockaddr_in_size)

    res = uv_tcp_init(loop, server)
    res = uv_ip4_addr("0.0.0.0" // c_null_char, 7000, addr_in)

    res = uv_tcp_bind(server, addr_in, flags)

    res = uv_listen(server, 128, c_funloc(on_connection))
    res = uv_run(loop, 0)

    call c_free(server)
end program echo_server
