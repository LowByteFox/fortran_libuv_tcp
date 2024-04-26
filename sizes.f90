module uv_sizes
    use iso_c_binding
    integer(c_long), parameter :: UV_EOF = -4095
    integer(c_size_t), parameter :: sockaddr_in_size = 16
    integer(c_size_t), parameter :: uv_tcp_size = 256
    integer(c_size_t), parameter :: uv_write_size = 192
end module uv_sizes
